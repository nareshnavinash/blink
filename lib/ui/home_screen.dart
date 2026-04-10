import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blink/core/app_constants.dart';
import 'package:blink/core/providers.dart';
import 'package:blink/services/timer_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final appStatus = ref.watch(appStatusProvider);
    final timerAsync = ref.watch(timerStatusProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.remove_red_eye, size: 32, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _StatusChip(appStatus: appStatus),
              ],
            ),
            const SizedBox(height: 32),

            // Timer card
            _TimerCard(
              timerAsync: timerAsync,
              appStatus: appStatus,
              settings: settings,
              ref: ref,
            ),
            const SizedBox(height: 24),

            // Break info
            timerAsync.when(
              data: (status) => _BreakInfoRow(status: status),
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Quick settings
            Text(
              'Quick Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              title: 'Break Reminders',
              subtitle:
                  'Every ${settings.workMinutes} min, ${settings.breakSeconds}s break',
              value: settings.breaksEnabled,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).update(
                  (s) => s.copyWith(breaksEnabled: value),
                );
                if (value) {
                  ref.read(timerServiceProvider).startWorkSession();
                } else {
                  ref.read(timerServiceProvider).pause();
                }
              },
            ),
            _SettingsTile(
              title: 'Blink Reminders',
              subtitle: 'Gentle reminder to blink',
              value: settings.blinkRemindersEnabled,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).update(
                  (s) => s.copyWith(blinkRemindersEnabled: value),
                );
              },
            ),
            _SettingsTile(
              title: 'Posture Reminders',
              subtitle: 'Check your posture periodically',
              value: settings.postureRemindersEnabled,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).update(
                  (s) => s.copyWith(postureRemindersEnabled: value),
                );
              },
            ),
          ],
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
              ? Colors.green.shade100
              : Colors.orange.shade100,
    );
  }
}

class _TimerCard extends StatelessWidget {
  final AsyncValue<TimerStatus> timerAsync;
  final AppStatus appStatus;
  final dynamic settings;
  final WidgetRef ref;

  const _TimerCard({
    required this.timerAsync,
    required this.appStatus,
    required this.settings,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            timerAsync.when(
              data: (status) => _TimerDisplay(status: status),
              loading: () => _TimerDisplayPlaceholder(
                workMinutes: settings.workMinutes,
              ),
              error: (e, st) => const Text('Timer error'),
            ),
            const SizedBox(height: 16),

            // Progress bar
            timerAsync.when(
              data: (status) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: status.progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  color: status.state == TimerState.onBreak
                      ? Colors.green
                      : Colors.blue,
                ),
              ),
              loading: () => const LinearProgressIndicator(value: 0),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () {
                    ref.read(appStatusProvider.notifier).toggle();
                  },
                  icon: Icon(
                    appStatus == AppStatus.running
                        ? Icons.pause
                        : Icons.play_arrow,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  final TimerStatus status;

  const _TimerDisplay({required this.status});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          status.stateLabel,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: status.state == TimerState.onBreak
                ? Colors.green[700]
                : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          status.remainingFormatted,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w300,
            fontFeatures: [const FontFeature.tabularFigures()],
            color: status.state == TimerState.onBreak
                ? Colors.green[700]
                : null,
          ),
        ),
      ],
    );
  }
}

class _TimerDisplayPlaceholder extends StatelessWidget {
  final int workMinutes;

  const _TimerDisplayPlaceholder({required this.workMinutes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next break in',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${workMinutes.toString().padLeft(2, '0')}:00',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w300,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _BreakInfoRow extends StatelessWidget {
  final TimerStatus status;

  const _BreakInfoRow({required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.info_outline,
          size: 16,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 8),
        Text(
          'Break ${status.breaksTakenInCycle + 1} of cycle  |  '
          'Next: ${status.nextBreakType == BreakType.long ? 'Long break' : 'Short break'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}
