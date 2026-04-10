import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blink/core/app_constants.dart';
import 'package:blink/core/providers.dart';
import 'package:blink/services/timer_service.dart';
import 'package:blink/ui/mobile/mobile_pairing_screen.dart';
import 'package:blink/ui/pomodoro_screen.dart';
import 'package:blink/ui/stats_screen.dart';
import 'package:blink/ui/settings_screen.dart';

class MobileHomeScreen extends ConsumerStatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  ConsumerState<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends ConsumerState<MobileHomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    _MobileTimerTab(),
    PomodoroScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Timer',
          ),
          NavigationDestination(
            icon: Icon(Icons.av_timer_outlined),
            selectedIcon: Icon(Icons.av_timer),
            label: 'Pomodoro',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _MobileTimerTab extends ConsumerWidget {
  const _MobileTimerTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final appStatus = ref.watch(appStatusProvider);
    final timerAsync = ref.watch(timerStatusProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.remove_red_eye, size: 28, color: Colors.blue),
                const SizedBox(width: 10),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Pairing button
                IconButton(
                  icon: const Icon(Icons.devices),
                  tooltip: 'Pair with Desktop',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MobilePairingScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const Spacer(),

            // Large circular timer
            timerAsync.when(
              data: (status) => _MobileTimerCircle(status: status),
              loading: () => const _MobileTimerCircle(status: null),
              error: (e, st) => const Text('Timer error'),
            ),
            const SizedBox(height: 16),

            // Status label
            timerAsync.when(
              data: (status) => Text(
                status.stateLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: status.state == TimerState.onBreak
                      ? Colors.green
                      : status.state == TimerState.preBreak
                          ? Colors.orange
                          : Colors.grey[600],
                ),
              ),
              loading: () => Text(
                'Starting...',
                style: TextStyle(color: Colors.grey[600]),
              ),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const Spacer(),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: 'pause',
                  onPressed: () {
                    ref.read(appStatusProvider.notifier).toggle();
                  },
                  child: Icon(
                    appStatus == AppStatus.running
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                ),
                const SizedBox(width: 24),
                timerAsync.when(
                  data: (status) {
                    if (status.state == TimerState.onBreak) {
                      return FloatingActionButton.extended(
                        heroTag: 'skip',
                        onPressed: () =>
                            ref.read(timerServiceProvider).skipBreak(),
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Skip'),
                      );
                    }
                    return FloatingActionButton.extended(
                      heroTag: 'break',
                      onPressed: () =>
                          ref.read(timerServiceProvider).startBreakNow(),
                      icon: const Icon(Icons.free_breakfast),
                      label: const Text('Break Now'),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick toggles
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Breaks'),
                      dense: true,
                      value: settings.breaksEnabled,
                      onChanged: (v) {
                        ref.read(settingsProvider.notifier).update(
                          (s) => s.copyWith(breaksEnabled: v),
                        );
                        if (v) {
                          ref.read(timerServiceProvider).startWorkSession();
                        } else {
                          ref.read(timerServiceProvider).pause();
                        }
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Blink Reminders'),
                      dense: true,
                      value: settings.blinkRemindersEnabled,
                      onChanged: (v) {
                        ref.read(settingsProvider.notifier).update(
                          (s) => s.copyWith(blinkRemindersEnabled: v),
                        );
                        ref.read(reminderServiceProvider).updateBlinkEnabled(v);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileTimerCircle extends StatelessWidget {
  final TimerStatus? status;

  const _MobileTimerCircle({required this.status});

  @override
  Widget build(BuildContext context) {
    final progress = status?.progress ?? 0.0;
    final timeText = status?.remainingFormatted ?? '--:--';
    final isBreak = status?.state == TimerState.onBreak;
    final color = isBreak ? Colors.green : Colors.blue;

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.grey.shade200,
              color: color,
            ),
          ),
          Text(
            timeText,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w200,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
