import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:blink/core/providers.dart';
import 'package:blink/services/notification_service.dart';
import 'package:blink/services/storage_service.dart';
import 'package:blink/services/timer_service.dart';
import 'package:blink/services/reminder_service.dart';
import 'package:blink/services/tray_service.dart';
import 'package:blink/ui/home_screen.dart';
import 'package:blink/ui/break_screen.dart';

late final TrayService trayService;
late final TimerService timerService;
late final NotificationService notificationService;
late final ReminderService reminderService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Initialize storage
  final storageService = StorageService();
  await storageService.init();
  final settings = storageService.loadSettings();

  // Initialize window
  const windowOptions = WindowOptions(
    size: Size(480, 640),
    minimumSize: Size(400, 500),
    center: true,
    title: 'Blink',
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    if (settings.startMinimized) {
      await windowManager.hide();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  });

  await windowManager.setPreventClose(true);

  // Initialize notifications
  notificationService = NotificationService();
  await notificationService.init();

  // Initialize timer service
  timerService = TimerService();
  timerService.configure(
    workMinutes: settings.workMinutes,
    breakSeconds: settings.breakSeconds,
    longBreakMinutes: settings.longBreakMinutes,
    longBreakInterval: settings.longBreakInterval,
  );

  // Wire timer callbacks to notifications
  timerService.onPreBreakStart = () {
    final status = timerService.currentStatus;
    notificationService.showPreBreakNotification(
      secondsUntilBreak: status.remainingSeconds,
      breakType: status.nextBreakType,
      canPostpone: status.canPostpone,
      postponesRemaining: status.postponesRemaining,
    );
  };

  timerService.onBreakStart = (breakType) {
    notificationService.showBreakStartNotification(breakType: breakType);
  };

  timerService.onBreakEnd = () {
    notificationService.showBreakEndNotification();
  };

  // Initialize reminder service
  reminderService = ReminderService();
  reminderService.configure(
    blinkIntervalMinutes: 10,
    postureIntervalMinutes: 30,
    blinkEnabled: settings.blinkRemindersEnabled,
    postureEnabled: settings.postureRemindersEnabled,
  );

  // Initialize system tray
  trayService = TrayService();
  await trayService.init();
  trayService.listenToTimer(timerService);

  // Start the first work session and reminders
  if (settings.breaksEnabled) {
    timerService.startWorkSession();
  }
  reminderService.start();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        timerServiceProvider.overrideWithValue(timerService),
        reminderServiceProvider.overrideWithValue(reminderService),
      ],
      child: const BlinkApp(),
    ),
  );
}

class BlinkApp extends ConsumerStatefulWidget {
  const BlinkApp({super.key});

  @override
  ConsumerState<BlinkApp> createState() => _BlinkAppState();
}

class _BlinkAppState extends ConsumerState<BlinkApp> with WindowListener {
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _isBreakScreenShowing = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    trayService.setOnPauseToggle((isPaused) {
      ref.read(appStatusProvider.notifier).set(
          isPaused ? AppStatus.paused : AppStatus.running);
    });

    trayService.setOnStartBreakNow(() {
      ref.read(timerServiceProvider).startBreakNow();
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    await windowManager.hide();
  }

  void _handleTimerStatus(TimerStatus status) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    if (status.state == TimerState.onBreak && !_isBreakScreenShowing) {
      _isBreakScreenShowing = true;
      // Show window if hidden during break
      windowManager.show();
      windowManager.focus();
      navigator.push(
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (context, animation, secondaryAnimation) =>
              const BreakScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else if (status.state != TimerState.onBreak && _isBreakScreenShowing) {
      _isBreakScreenShowing = false;
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to timer status for break screen navigation
    ref.listen<AsyncValue<TimerStatus>>(timerStatusProvider, (prev, next) {
      next.whenData(_handleTimerStatus);
    });

    return MaterialApp(
      title: 'Blink',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
