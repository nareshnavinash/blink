import 'package:local_notifier/local_notifier.dart';
import 'package:blink/services/timer_service.dart';

class NotificationService {
  Future<void> init() async {
    await localNotifier.setup(appName: 'Blink');
  }

  void showPreBreakNotification({
    required int secondsUntilBreak,
    required BreakType breakType,
    required bool canPostpone,
    required int postponesRemaining,
  }) {
    final type = breakType == BreakType.long ? 'Long break' : 'Break';
    final body = canPostpone
        ? '$type starting in $secondsUntilBreak seconds. $postponesRemaining postpones remaining.'
        : '$type starting in $secondsUntilBreak seconds. No postpones remaining.';

    final notification = LocalNotification(
      title: 'Time for a break',
      body: body,
    );

    if (canPostpone) {
      notification.actions = [
        LocalNotificationAction(text: '+1 min'),
        LocalNotificationAction(text: '+5 min'),
      ];
    }

    notification.show();
  }

  void showBreakStartNotification({required BreakType breakType}) {
    final message = breakType == BreakType.long
        ? 'Time for a longer break. Stand up and stretch!'
        : 'Look at something 20 feet away for 20 seconds.';

    final notification = LocalNotification(
      title: breakType == BreakType.long ? 'Long Break' : 'Eye Break',
      body: message,
    );
    notification.show();
  }

  void showBreakEndNotification() {
    final notification = LocalNotification(
      title: 'Break complete',
      body: 'Welcome back! Work session started.',
    );
    notification.show();
  }
}
