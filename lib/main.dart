import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:chirp/core/providers.dart';
import 'package:chirp/services/notification_service.dart';
import 'package:chirp/services/mobile_notification_service.dart';
import 'package:chirp/services/storage_service.dart';
import 'package:chirp/services/timer_service.dart';
import 'package:chirp/services/reminder_service.dart';
import 'package:chirp/services/idle_service.dart';
import 'package:chirp/services/schedule_service.dart';
import 'package:chirp/services/smart_pause_service.dart';
import 'package:chirp/services/stats_service.dart';
import 'package:chirp/services/pairing_service.dart';
import 'package:chirp/services/sync_service.dart';
import 'package:chirp/services/team_service.dart';
import 'package:chirp/services/pomodoro_service.dart';
import 'package:chirp/services/tray_service.dart';
import 'package:chirp/services/overlay_service.dart';
import 'package:chirp/ui/break_screen.dart';
import 'package:chirp/ui/home_screen.dart';
import 'package:chirp/ui/settings_screen.dart';
import 'package:chirp/ui/stats_screen.dart';
import 'package:chirp/ui/mobile/mobile_home_screen.dart';
import 'package:chirp/ui/theme/app_theme.dart';

late final TimerService timerService;
late final ReminderService reminderService;
late final StatsService statsService;
late final SyncService syncService;
late final TeamService teamService;
late final SmartPauseService smartPauseService;
late final IdleService idleService;
late final ScheduleService scheduleService;
late final PomodoroService pomodoroService;

// Desktop-only globals
TrayService? trayService;
NotificationService? desktopNotificationService;
OverlayService? overlayService;

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
      title: 'Chirp',
      skipTaskbar: true,
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

    if (Platform.isMacOS) {
      overlayService = OverlayService();
    }

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

  // Initialize pomodoro service
  pomodoroService = PomodoroService();
  pomodoroService.configure();

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
    trayService!.listenToPomodoro(pomodoroService);
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
        pomodoroServiceProvider.overrideWithValue(pomodoroService),
        if (pairingService != null)
          pairingServiceProvider.overrideWithValue(pairingService!),
      ],
      child: const ChirpApp(),
    ),
  );
}

class ChirpApp extends ConsumerStatefulWidget {
  const ChirpApp({super.key});

  @override
  ConsumerState<ChirpApp> createState() => _ChirpAppState();
}

class _ChirpAppState extends ConsumerState<ChirpApp> with WindowListener {
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
      trayService?.setOnSkipBreak(() {
        ref.read(timerServiceProvider).skipBreak();
      });
      trayService?.setOnPostpone((minutes) {
        ref.read(timerServiceProvider).postpone(minutes);
      });
      trayService?.setOnOpenApp(() async {
        await windowManager.show();
        await windowManager.focus();
      });
      trayService?.setOnOpenSettings(() async {
        await windowManager.show();
        await windowManager.focus();
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      });
      trayService?.setOnOpenStats(() async {
        await windowManager.show();
        await windowManager.focus();
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const StatsScreen()),
        );
      });
      trayService?.setOnPomodoroStart(() {
        ref.read(pomodoroServiceProvider).startWork();
      });
      trayService?.setOnPomodoroTogglePause(() {
        final pomo = ref.read(pomodoroServiceProvider);
        final status = pomo.currentStatus;
        if (status.state == PomodoroState.paused) {
          pomo.resume();
        } else {
          pomo.pause();
        }
      });
      trayService?.setOnPomodoroSkipBreak(() {
        ref.read(pomodoroServiceProvider).skipBreak();
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

      if (Platform.isMacOS && overlayService != null) {
        // macOS: push break screen first (while window is still hidden),
        // then show the fullscreen overlay — prevents HomeScreen from
        // flashing behind the semi-transparent break overlay.
        navigator.push(
          PageRouteBuilder(
            opaque: true,
            pageBuilder: (context, animation, secondaryAnimation) =>
                const BreakScreen(),
            // No transition on macOS — the window goes from hidden to
            // visible via showBreakOverlay(), so a fade is redundant.
            // Duration.zero also ensures opaque:true takes effect
            // immediately, preventing the HomeScreen from painting
            // during a transition period.
            transitionDuration: Duration.zero,
          ),
        );
        overlayService!.showBreakOverlay();
      } else {
        // Windows/Linux: show in normal window
        windowManager.show();
        windowManager.focus();
        navigator.push(
          PageRouteBuilder(
            opaque: true,
            pageBuilder: (context, animation, secondaryAnimation) =>
                const BreakScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween(begin: 0.95, end: 1.0).animate(curved),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } else if (status.state != TimerState.onBreak && _isBreakScreenShowing) {
      _isBreakScreenShowing = false;
      navigator.pop();

      if (Platform.isMacOS && overlayService != null) {
        overlayService!.hideBreakOverlay();
      } else if (_isDesktop) {
        windowManager.hide();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<TimerStatus>>(timerStatusProvider, (prev, next) {
      next.whenData(_handleTimerStatus);
    });

    return MaterialApp(
      title: 'Chirp',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: _isMobile ? const MobileHomeScreen() : const HomeScreen(),
    );
  }
}
