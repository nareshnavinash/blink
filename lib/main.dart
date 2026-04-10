import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:blink/core/providers.dart';
import 'package:blink/services/notification_service.dart';
import 'package:blink/services/mobile_notification_service.dart';
import 'package:blink/services/storage_service.dart';
import 'package:blink/services/timer_service.dart';
import 'package:blink/services/reminder_service.dart';
import 'package:blink/services/idle_service.dart';
import 'package:blink/services/schedule_service.dart';
import 'package:blink/services/smart_pause_service.dart';
import 'package:blink/services/stats_service.dart';
import 'package:blink/services/pairing_service.dart';
import 'package:blink/services/sync_service.dart';
import 'package:blink/services/team_service.dart';
import 'package:blink/services/tray_service.dart';
import 'package:blink/ui/break_screen.dart';
import 'package:blink/ui/home_screen.dart';
import 'package:blink/ui/mobile/mobile_home_screen.dart';

late final TimerService timerService;
late final ReminderService reminderService;
late final StatsService statsService;
late final SyncService syncService;
late final TeamService teamService;
late final SmartPauseService smartPauseService;
late final IdleService idleService;
late final ScheduleService scheduleService;

// Desktop-only globals
TrayService? trayService;
NotificationService? desktopNotificationService;

// Mobile-only globals
MobileNotificationService? mobileNotificationService;
PairingService? pairingService;

bool get _isDesktop => Platform.isMacOS || Platform.isWindows || Platform.isLinux;
bool get _isMobile => Platform.isIOS || Platform.isAndroid;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop window setup
  if (_isDesktop) {
    await windowManager.ensureInitialized();
  }

  // Initialize storage
  final storageService = StorageService();
  await storageService.init();
  final settings = storageService.loadSettings();

  // Initialize stats
  final prefs = await SharedPreferences.getInstance();
  statsService = StatsService();
  await statsService.init(prefs);

  // Initialize sync service
  syncService = SyncService();
  await syncService.init(prefs);

  // Initialize team service
  teamService = TeamService();
  await teamService.init(prefs);

  // Desktop-specific window initialization
  if (_isDesktop) {
    final windowOptions = WindowOptions(
      size: const Size(480, 640),
      minimumSize: const Size(400, 500),
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

    desktopNotificationService = NotificationService();
    await desktopNotificationService!.init();

    // Start pairing server on desktop
    pairingService = PairingService(role: PairingRole.desktop);
    await pairingService!.startServer();
  }

  // Mobile-specific initialization
  if (_isMobile) {
    mobileNotificationService = MobileNotificationService();
    await mobileNotificationService!.init();

    pairingService = PairingService(role: PairingRole.mobile);
  }

  // Initialize timer service (shared)
  timerService = TimerService();
  timerService.configure(
    workMinutes: settings.workMinutes,
    breakSeconds: settings.breakSeconds,
    longBreakMinutes: settings.longBreakMinutes,
    longBreakInterval: settings.longBreakInterval,
  );

  // Wire timer callbacks to platform-appropriate notifications
  timerService.onPreBreakStart = () {
    final status = timerService.currentStatus;
    if (_isDesktop) {
      desktopNotificationService?.showPreBreakNotification(
        secondsUntilBreak: status.remainingSeconds,
        breakType: status.nextBreakType,
        canPostpone: status.canPostpone,
        postponesRemaining: status.postponesRemaining,
      );
    } else {
      mobileNotificationService?.showPreBreakNotification(
        secondsUntilBreak: status.remainingSeconds,
        breakType: status.nextBreakType,
        canPostpone: status.canPostpone,
        postponesRemaining: status.postponesRemaining,
      );
    }
  };

  timerService.onBreakStart = (breakType) {
    if (_isDesktop) {
      desktopNotificationService?.showBreakStartNotification(breakType: breakType);
    } else {
      mobileNotificationService?.showBreakStartNotification(breakType: breakType);
    }
    pairingService?.sendEvent(PairingSyncEvent.breakStart);
  };

  timerService.onBreakEnd = () {
    if (_isDesktop) {
      desktopNotificationService?.showBreakEndNotification();
    } else {
      mobileNotificationService?.showBreakEndNotification();
    }
    statsService.recordBreakTaken();
    pairingService?.sendEvent(PairingSyncEvent.breakEnd);
  };

  // Initialize reminder service (shared)
  reminderService = ReminderService();
  reminderService.configure(
    blinkIntervalMinutes: settings.blinkIntervalMinutes,
    postureIntervalMinutes: settings.postureIntervalMinutes,
    blinkEnabled: settings.blinkRemindersEnabled,
    postureEnabled: settings.postureRemindersEnabled,
  );

  // Desktop-only services
  if (_isDesktop) {
    idleService = IdleService();
    idleService.configure(idleThresholdSeconds: settings.idleThresholdMinutes * 60);
    idleService.onIdleChanged = (isIdle) {
      if (isIdle) {
        timerService.pause();
        reminderService.stop();
      } else {
        timerService.resume();
        reminderService.start();
      }
    };
    await idleService.start();

    scheduleService = ScheduleService();
    scheduleService.onScheduleChanged = (isWithinSchedule) {
      if (isWithinSchedule) {
        timerService.resume();
        reminderService.start();
      } else {
        timerService.pause();
        reminderService.stop();
      }
    };
    scheduleService.start();

    smartPauseService = SmartPauseService();
    smartPauseService.configure(const SmartPauseConfig());
    smartPauseService.onPauseChanged = (shouldPause, reason) {
      if (shouldPause) {
        timerService.pause();
        reminderService.stop();
      } else {
        timerService.resume();
        reminderService.start();
      }
    };
    smartPauseService.start();

    trayService = TrayService();
    await trayService!.init();
    trayService!.listenToTimer(timerService);
  } else {
    // Provide defaults for mobile so providers don't crash
    idleService = IdleService();
    scheduleService = ScheduleService();
    smartPauseService = SmartPauseService();
  }

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
        idleServiceProvider.overrideWithValue(idleService),
        scheduleServiceProvider.overrideWithValue(scheduleService),
        statsServiceProvider.overrideWithValue(statsService),
        smartPauseServiceProvider.overrideWithValue(smartPauseService),
        syncServiceProvider.overrideWithValue(syncService),
        teamServiceProvider.overrideWithValue(teamService),
        if (pairingService != null)
          pairingServiceProvider.overrideWithValue(pairingService!),
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

    if (_isDesktop) {
      windowManager.addListener(this);
      trayService?.setOnPauseToggle((isPaused) {
        ref.read(appStatusProvider.notifier).set(
            isPaused ? AppStatus.paused : AppStatus.running);
      });
      trayService?.setOnStartBreakNow(() {
        ref.read(timerServiceProvider).startBreakNow();
      });
    }
  }

  @override
  void dispose() {
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    await windowManager.hide();
  }

  void _handleTimerStatus(TimerStatus status) {
    if (!_isDesktop) return;

    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    if (status.state == TimerState.onBreak && !_isBreakScreenShowing) {
      _isBreakScreenShowing = true;
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
      home: _isMobile ? const MobileHomeScreen() : const HomeScreen(),
    );
  }
}
