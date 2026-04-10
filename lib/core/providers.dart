import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blink/features/settings/settings_model.dart';
import 'package:blink/services/reminder_service.dart';
import 'package:blink/services/storage_service.dart';
import 'package:blink/services/timer_service.dart';

// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Timer service provider (singleton)
final timerServiceProvider = Provider<TimerService>((ref) {
  final service = TimerService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Reminder service provider (singleton)
final reminderServiceProvider = Provider<ReminderService>((ref) {
  final service = ReminderService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Timer status stream provider
final timerStatusProvider = StreamProvider<TimerStatus>((ref) {
  final timerService = ref.watch(timerServiceProvider);
  // Emit current status immediately, then stream updates
  return timerService.statusStream;
});

// Settings notifier using modern Riverpod API
class SettingsNotifier extends Notifier<SettingsModel> {
  @override
  SettingsModel build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.loadSettings();
  }

  Future<void> update(SettingsModel Function(SettingsModel) updater) async {
    state = updater(state);
    final storage = ref.read(storageServiceProvider);
    await storage.saveSettings(state);

    // Reconfigure timer when settings change
    final timerService = ref.read(timerServiceProvider);
    timerService.configure(
      workMinutes: state.workMinutes,
      breakSeconds: state.breakSeconds,
      longBreakMinutes: state.longBreakMinutes,
      longBreakInterval: state.longBreakInterval,
    );
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsModel>(SettingsNotifier.new);

// App status — derived from timer state
enum AppStatus { running, paused }

class AppStatusNotifier extends Notifier<AppStatus> {
  @override
  AppStatus build() => AppStatus.running;

  void toggle() {
    final timerService = ref.read(timerServiceProvider);
    final reminderService = ref.read(reminderServiceProvider);
    if (state == AppStatus.running) {
      timerService.pause();
      reminderService.stop();
      state = AppStatus.paused;
    } else {
      timerService.resume();
      reminderService.start();
      state = AppStatus.running;
    }
  }

  void set(AppStatus status) {
    final timerService = ref.read(timerServiceProvider);
    final reminderService = ref.read(reminderServiceProvider);
    if (status == AppStatus.paused) {
      timerService.pause();
      reminderService.stop();
    } else {
      timerService.resume();
      reminderService.start();
    }
    state = status;
  }
}

final appStatusProvider =
    NotifierProvider<AppStatusNotifier, AppStatus>(AppStatusNotifier.new);
