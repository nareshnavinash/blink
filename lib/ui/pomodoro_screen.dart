import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blink/core/providers.dart';
import 'package:blink/services/pomodoro_service.dart';

class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomodoroAsync = ref.watch(pomodoroStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro')),
      body: Center(
        child: pomodoroAsync.when(
          data: (status) => _PomodoroContent(status: status, ref: ref),
          loading: () => _PomodoroIdle(ref: ref),
          error: (e, st) => _PomodoroIdle(ref: ref),
        ),
      ),
    );
  }
}

class _PomodoroIdle extends StatelessWidget {
  final WidgetRef ref;

  const _PomodoroIdle({required this.ref});

  @override
  Widget build(BuildContext context) {
    final service = ref.read(pomodoroServiceProvider);
    final status = service.currentStatus;

    if (status.state == PomodoroState.idle) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Ready to focus?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '25 min work / 5 min break / 4 cycles',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => service.startWork(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Pomodoro'),
          ),
        ],
      );
    }

    return _PomodoroContent(status: status, ref: ref);
  }
}

class _PomodoroContent extends StatelessWidget {
  final PomodoroStatus status;
  final WidgetRef ref;

  const _PomodoroContent({required this.status, required this.ref});

  Color get _stateColor {
    switch (status.state) {
      case PomodoroState.work:
        return Colors.red;
      case PomodoroState.shortBreak:
        return Colors.green;
      case PomodoroState.longBreak:
        return Colors.blue;
      case PomodoroState.paused:
        return Colors.orange;
      case PomodoroState.idle:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // State label
        Text(
          status.stateLabel,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: _stateColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 32),

        // Circular timer
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: status.progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: _stateColor,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    status.remainingFormatted,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w200,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Pomodoro dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(status.totalPomodoros, (i) {
            final isComplete = i < status.currentPomodoro - 1 ||
                (i == status.currentPomodoro - 1 &&
                    (status.state == PomodoroState.shortBreak ||
                     status.state == PomodoroState.longBreak));
            final isCurrent = i == status.currentPomodoro - 1 &&
                status.state == PomodoroState.work;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isComplete
                      ? _stateColor
                      : isCurrent
                          ? _stateColor.withValues(alpha: 0.3)
                          : Colors.grey.shade300,
                  border: isCurrent
                      ? Border.all(color: _stateColor, width: 2)
                      : null,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Pomodoro ${status.currentPomodoro} of ${status.totalPomodoros}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (status.state == PomodoroState.paused)
              FilledButton.icon(
                onPressed: () =>
                    ref.read(pomodoroServiceProvider).resume(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Resume'),
              )
            else if (status.state != PomodoroState.idle)
              FilledButton.icon(
                onPressed: () =>
                    ref.read(pomodoroServiceProvider).pause(),
                icon: const Icon(Icons.pause),
                label: const Text('Pause'),
              ),
            const SizedBox(width: 12),
            if (status.state == PomodoroState.shortBreak ||
                status.state == PomodoroState.longBreak)
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(pomodoroServiceProvider).skipBreak(),
                icon: const Icon(Icons.skip_next),
                label: const Text('Skip Break'),
              ),
            if (status.state != PomodoroState.idle) ...[
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () =>
                    ref.read(pomodoroServiceProvider).reset(),
                icon: const Icon(Icons.stop),
                label: const Text('Reset'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),

        // Completed count
        Text(
          '${status.pomodorosCompletedToday} Pomodoros completed today',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
