import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chirp/core/providers.dart';
import 'package:chirp/services/timer_service.dart';
import 'package:chirp/ui/theme/app_theme_extension.dart';
import 'package:chirp/ui/widgets/break_keyboard_shortcuts.dart';
import 'package:chirp/ui/widgets/breathing_progress_ring.dart';

class BreakScreen extends ConsumerWidget {
  const BreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerAsync = ref.watch(timerStatusProvider);
    final colors = ChirpColors.of(context);

    // On macOS, use semi-transparent dark overlay for fullscreen mode
    // On other desktop platforms, keep the gradient in the normal window
    final background = Platform.isMacOS
        ? BoxDecoration(color: Colors.black.withValues(alpha: 0.85))
        : BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.breakGradientStart,
                colors.breakGradientEnd,
              ],
            ),
          );

    return BreakKeyboardShortcuts(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
        decoration: background,
        child: Center(
          child: timerAsync.when(
            data: (status) => _BreakContent(status: status, ref: ref),
            loading: () => const CircularProgressIndicator(color: Colors.white),
            error: (e, st) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.white38, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Break timer encountered an issue.\nIt will resume automatically.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, height: 1.5),
                ),
              ],
            ),
          ),
         ),
        ),
       ),
    );
  }
}

class _BreakContent extends StatelessWidget {
  final TimerStatus status;
  final WidgetRef ref;

  const _BreakContent({required this.status, required this.ref});

  String get _breakMessage {
    if (status.nextBreakType == BreakType.long) {
      return 'Stand up and stretch.\nGrab some water.';
    }
    return 'Look at something 20 feet away\nfor 20 seconds.';
  }

  String get _breakTitle {
    return status.nextBreakType == BreakType.long
        ? 'Long Break'
        : 'Eye Break';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Break type icon
        Icon(
          status.nextBreakType == BreakType.long
              ? Icons.self_improvement
              : Icons.visibility,
          size: 64,
          color: Colors.white70,
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          _breakTitle,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 16),

        // Message
        Text(
          _breakMessage,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white60,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 48),

        // Breathing countdown ring
        BreathingProgressRing(
          progress: status.progress,
          timeText: status.remainingFormatted,
        ),
        const SizedBox(height: 48),

        // Skip button (improved contrast)
        TextButton.icon(
          onPressed: () {
            ref.read(timerServiceProvider).skipBreak();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white60,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          icon: const Icon(Icons.skip_next, size: 18),
          label: const Text('Skip break (Esc)'),
        ),
      ],
    );
  }
}
