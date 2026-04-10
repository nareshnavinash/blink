import 'dart:async';
import 'package:local_notifier/local_notifier.dart';

enum ReminderType { blink, posture }

class ReminderEvent {
  final ReminderType type;
  final DateTime timestamp;

  const ReminderEvent({required this.type, required this.timestamp});
}

class ReminderService {
  Timer? _blinkTimer;
  Timer? _postureTimer;

  int _blinkIntervalMinutes = 10;
  int _postureIntervalMinutes = 30;
  bool _blinkEnabled = true;
  bool _postureEnabled = true;

  final StreamController<ReminderEvent> _eventController =
      StreamController<ReminderEvent>.broadcast();

  Stream<ReminderEvent> get events => _eventController.stream;

  void configure({
    required int blinkIntervalMinutes,
    required int postureIntervalMinutes,
    required bool blinkEnabled,
    required bool postureEnabled,
  }) {
    _blinkIntervalMinutes = blinkIntervalMinutes;
    _postureIntervalMinutes = postureIntervalMinutes;
    _blinkEnabled = blinkEnabled;
    _postureEnabled = postureEnabled;
  }

  void start() {
    stop();
    if (_blinkEnabled) {
      _startBlinkReminder();
    }
    if (_postureEnabled) {
      _startPostureReminder();
    }
  }

  void stop() {
    _blinkTimer?.cancel();
    _blinkTimer = null;
    _postureTimer?.cancel();
    _postureTimer = null;
  }

  void updateBlinkEnabled(bool enabled) {
    _blinkEnabled = enabled;
    _blinkTimer?.cancel();
    if (enabled) {
      _startBlinkReminder();
    }
  }

  void updatePostureEnabled(bool enabled) {
    _postureEnabled = enabled;
    _postureTimer?.cancel();
    if (enabled) {
      _startPostureReminder();
    }
  }

  void _startBlinkReminder() {
    _blinkTimer = Timer.periodic(
      Duration(minutes: _blinkIntervalMinutes),
      (_) => _fireReminder(ReminderType.blink),
    );
  }

  void _startPostureReminder() {
    _postureTimer = Timer.periodic(
      Duration(minutes: _postureIntervalMinutes),
      (_) => _fireReminder(ReminderType.posture),
    );
  }

  void _fireReminder(ReminderType type) {
    _eventController.add(ReminderEvent(
      type: type,
      timestamp: DateTime.now(),
    ));
    _showNotification(type);
  }

  void _showNotification(ReminderType type) {
    final notification = LocalNotification(
      title: type == ReminderType.blink ? 'Blink' : 'Posture Check',
      body: type == ReminderType.blink
          ? 'Remember to blink. Your eyes will thank you.'
          : 'Sit up straight. Roll your shoulders back.',
    );
    notification.show();
  }

  void dispose() {
    stop();
    _eventController.close();
  }
}
