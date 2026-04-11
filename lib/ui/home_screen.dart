import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chirp/core/app_constants.dart';
import 'package:chirp/core/providers.dart';
import 'package:chirp/services/timer_service.dart';
import 'package:chirp/ui/settings_screen.dart';
import 'package:chirp/ui/pomodoro_screen.dart';
import 'package:chirp/ui/stats_screen.dart';
import 'package:chirp/ui/team_screen.dart';
import 'package:chirp/ui/theme/app_theme_extension.dart';
import 'package:chirp/ui/widgets/circular_timer.dart';
import 'package:chirp/ui/widgets/keyboard_shortcuts.dart';
import 'package:chirp/ui/widgets/quick_settings_row.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Color _progressColor(BuildContext context, TimerStatus status) {
    final colors = ChirpColors.of(context);
    switch (status.state) {
      case TimerState.onBreak:
        return colors.success;
      case TimerState.preBreak:
        return colors.warning;
      default:
        return colors.brand;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStatus = ref.watch(appStatusProvider);
    final timerAsync = ref.watch(timerStatusProvider);

    return KeyboardShortcutWrapper(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
          children: [
            // Header
            Row(
              children: [
                Image.asset(
                  Theme.of(context).brightness == Brightness.dark
                      ? 'assets/branding/chirp_splash_240_dark.png'
                      : 'assets/branding/chirp_splash_240.png',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _StatusChip(appStatus: appStatus),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.timer),
                  tooltip: 'Pomodoro',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PomodoroScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.bar_chart),
                  tooltip: 'Stats',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StatsScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.people),
                  tooltip: 'Team',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TeamScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Settings',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Circular timer (centered focal point)
            timerAsync.when(
              data: (status) => CircularTimer(
                progress: status.progress,
                timeText: status.remainingFormatted,
                label: status.stateLabel,
                progressColor: _progressColor(context, status),
              ),
              loading: () => const CircularTimer(
                progress: 0,
                timeText: '--:--',
                label: 'Starting...',
              ),
              error: (e, st) => Column(
                children: [
                  Icon(Icons.error_outline, color: ChirpColors.of(context).warning, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Timer is restarting...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ChirpColors.of(context).textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.read(timerServiceProvider).startWorkSession(),
                    child: const Text('Restart now'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons (centered)
            _ActionButtons(timerAsync: timerAsync, appStatus: appStatus, ref: ref),
            const SizedBox(height: 12),

            // Snooze bar (animated in/out during preBreak)
            timerAsync.when(
              data: (status) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: status.state == TimerState.preBreak
                    ? _SnoozeBar(key: const ValueKey('snooze'), status: status, ref: ref)
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),

            // Break info
            timerAsync.when(
              data: (status) => _BreakInfoRow(status: status),
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),

            const Spacer(),

            // Keyboard shortcut hints
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Space to ${appStatus == AppStatus.running ? "pause" : "resume"} · B for break · S to skip',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ChirpColors.of(context).textTertiary,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Compact quick settings chips
            const QuickSettingsRow(),
          ],
         ),
        ),
       ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AppStatus appStatus;

  const _StatusChip({required this.appStatus});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        appStatus == AppStatus.running ? 'Active' : 'Paused',
      ),
      backgroundColor:
          appStatus == AppStatus.running
              ? ChirpColors.of(context).successLight
              : ChirpColors.of(context).warningLight,
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final AsyncValue<TimerStatus> timerAsync;
  final AppStatus appStatus;
  final WidgetRef ref;

  const _ActionButtons({
    required this.timerAsync,
    required this.appStatus,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: () {
            ref.read(appStatusProvider.notifier).toggle();
          },
          icon: Icon(
            appStatus == AppStatus.running ? Icons.pause : Icons.play_arrow,
          ),
          label: Text(
            appStatus == AppStatus.running ? 'Pause' : 'Resume',
          ),
        ),
        const SizedBox(width: 12),
        timerAsync.when(
          data: (status) {
            if (status.state == TimerState.onBreak) {
              return OutlinedButton.icon(
                onPressed: () {
                  ref.read(timerServiceProvider).skipBreak();
                },
                icon: const Icon(Icons.skip_next),
                label: const Text('Skip Break'),
              );
            }
            if (status.state == TimerState.preBreak) {
              return OutlinedButton.icon(
                onPressed: () {
                  ref.read(timerServiceProvider).startBreakNow();
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Now'),
              );
            }
            return OutlinedButton.icon(
              onPressed: () {
                ref.read(timerServiceProvider).startBreakNow();
              },
              icon: const Icon(Icons.free_breakfast),
              label: const Text('Start Break Now'),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, st) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SnoozeBar extends StatelessWidget {
  final TimerStatus status;
  final WidgetRef ref;

  const _SnoozeBar({super.key, required this.status, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        color: ChirpColors.of(context).warningLight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.snooze, size: 18, color: ChirpColors.of(context).warningDark),
                  const SizedBox(width: 8),
                  Text(
                    status.canPostpone
                        ? 'Postpone? (${status.postponesRemaining} left today)'
                        : 'No postpones remaining',
                    style: TextStyle(
                      color: ChirpColors.of(context).warningDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (status.canPostpone) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SnoozeButton(
                      label: '+1 min',
                      onPressed: () =>
                          ref.read(timerServiceProvider).postpone(1),
                    ),
                    const SizedBox(width: 8),
                    _SnoozeButton(
                      label: '+5 min',
                      onPressed: () =>
                          ref.read(timerServiceProvider).postpone(5),
                    ),
                    const SizedBox(width: 8),
                    _SnoozeButton(
                      label: '+15 min',
                      onPressed: () =>
                          ref.read(timerServiceProvider).postpone(15),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SnoozeButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SnoozeButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: ChirpColors.of(context).warningDark,
        side: BorderSide(color: ChirpColors.of(context).warningMedium),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
      ),
      child: Text(label),
    );
  }
}

class _BreakInfoRow extends StatelessWidget {
  final TimerStatus status;

  const _BreakInfoRow({required this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 16, color: ChirpColors.of(context).textTertiary),
          const SizedBox(width: 8),
          Text(
            'Break ${status.breaksTakenInCycle + 1} of cycle  |  '
            'Next: ${status.nextBreakType == BreakType.long ? 'Long break' : 'Short break'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ChirpColors.of(context).textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
