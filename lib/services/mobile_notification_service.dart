import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:blink/services/timer_service.dart';

class MobileNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions on iOS
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Request permissions on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap actions
    final payload = response.payload;
    if (payload == 'snooze_1') {
      _onSnooze?.call(1);
    } else if (payload == 'snooze_5') {
      _onSnooze?.call(5);
    }
  }

  void Function(int minutes)? _onSnooze;

  void setOnSnooze(void Function(int minutes) callback) {
    _onSnooze = callback;
  }

  Future<void> showPreBreakNotification({
    required int secondsUntilBreak,
    required BreakType breakType,
    required bool canPostpone,
    required int postponesRemaining,
  }) async {
    final type = breakType == BreakType.long ? 'Long break' : 'Break';
    final body = canPostpone
        ? '$type starting in $secondsUntilBreak seconds. $postponesRemaining postpones remaining.'
        : '$type starting in $secondsUntilBreak seconds.';

    await _show(
      id: 1,
      title: 'Time for a break',
      body: body,
      channel: 'breaks',
      channelName: 'Break Reminders',
    );
  }

  Future<void> showBreakStartNotification({required BreakType breakType}) async {
    final message = breakType == BreakType.long
        ? 'Time for a longer break. Stand up and stretch!'
        : 'Look at something 20 feet away for 20 seconds.';

    await _show(
      id: 2,
      title: breakType == BreakType.long ? 'Long Break' : 'Eye Break',
      body: message,
      channel: 'breaks',
      channelName: 'Break Reminders',
    );
  }

  Future<void> showBreakEndNotification() async {
    await _show(
      id: 3,
      title: 'Break complete',
      body: 'Welcome back! Work session started.',
      channel: 'breaks',
      channelName: 'Break Reminders',
    );
  }

  Future<void> showBlinkReminder() async {
    await _show(
      id: 10,
      title: 'Blink',
      body: 'Remember to blink. Your eyes will thank you.',
      channel: 'reminders',
      channelName: 'Wellness Reminders',
    );
  }

  Future<void> showPostureReminder() async {
    await _show(
      id: 11,
      title: 'Posture Check',
      body: 'Sit up straight. Roll your shoulders back.',
      channel: 'reminders',
      channelName: 'Wellness Reminders',
    );
  }

  Future<void> showSyncNotification({
    required String title,
    required String body,
  }) async {
    await _show(
      id: 20,
      title: title,
      body: body,
      channel: 'sync',
      channelName: 'Desktop Sync',
    );
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channel,
    required String channelName,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channel,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
