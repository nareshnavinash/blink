import 'dart:async';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import 'package:blink/services/timer_service.dart';

class TrayService {
  final SystemTray _systemTray = SystemTray();
  bool _isPaused = false;
  StreamSubscription<TimerStatus>? _timerSubscription;

  bool get isPaused => _isPaused;

  Future<void> init() async {
    await _systemTray.initSystemTray(
      title: 'Blink',
      iconPath: _getTrayIconPath(),
      toolTip: 'Blink - Starting...',
    );

    await _updateMenu();

    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick ||
          eventName == kSystemTrayEventRightClick) {
        _systemTray.popUpContextMenu();
      }
    });
  }

  void listenToTimer(TimerService timerService) {
    _timerSubscription?.cancel();
    _timerSubscription = timerService.statusStream.listen((status) {
      _updateTooltipFromStatus(status);
    });
  }

  String _getTrayIconPath() {
    return 'assets/icons/tray_icon.png';
  }

  void _updateTooltipFromStatus(TimerStatus status) {
    String tooltip;
    switch (status.state) {
      case TimerState.working:
        tooltip = 'Blink - Next break in ${status.remainingFormatted}';
      case TimerState.preBreak:
        tooltip = 'Blink - Break starting in ${status.remainingFormatted}';
      case TimerState.onBreak:
        final type =
            status.nextBreakType == BreakType.long ? 'Long break' : 'Break';
        tooltip = 'Blink - $type ${status.remainingFormatted}';
      case TimerState.paused:
        tooltip = 'Blink - Paused';
      case TimerState.idle:
        tooltip = 'Blink - Idle';
    }
    _systemTray.setToolTip(tooltip);
  }

  Future<void> _updateMenu({String? timerInfo}) async {
    final menu = Menu();
    final items = <MenuItemBase>[
      MenuItemLabel(
        label: timerInfo ?? 'Blink',
        onClicked: (menuItem) async {
          await windowManager.show();
          await windowManager.focus();
        },
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Open Blink',
        onClicked: (menuItem) async {
          await windowManager.show();
          await windowManager.focus();
        },
      ),
      MenuItemLabel(
        label: 'Start Break Now',
        onClicked: (menuItem) {
          _onStartBreakNow?.call();
        },
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: _isPaused ? 'Resume' : 'Pause',
        onClicked: (menuItem) async {
          _isPaused = !_isPaused;
          await _updateMenu();
          _onPauseToggle?.call(_isPaused);
        },
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Quit Blink',
        onClicked: (menuItem) async {
          await _systemTray.destroy();
          await windowManager.destroy();
        },
      ),
    ];
    await menu.buildFrom(items);
    await _systemTray.setContextMenu(menu);
  }

  void Function(bool isPaused)? _onPauseToggle;
  void Function()? _onStartBreakNow;

  void setOnPauseToggle(void Function(bool isPaused) callback) {
    _onPauseToggle = callback;
  }

  void setOnStartBreakNow(void Function() callback) {
    _onStartBreakNow = callback;
  }

  Future<void> destroy() async {
    _timerSubscription?.cancel();
    await _systemTray.destroy();
  }
}
