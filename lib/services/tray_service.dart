import 'dart:async';
import 'dart:io' show exit;
import 'dart:ui' show Brightness;
import 'package:flutter/scheduler.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import 'package:chirp/services/timer_service.dart';

class TrayService {
  final SystemTray _systemTray = SystemTray();
  bool _isPaused = false;
  StreamSubscription<TimerStatus>? _timerSubscription;

  bool get isPaused => _isPaused;

  Future<void> init() async {
    await _systemTray.initSystemTray(
      title: '',
      iconPath: _getTrayIconPath(),
      toolTip: 'Chirp - Starting...',
    );

    await _updateMenu();

    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        _toggleMainWindow();
      } else if (eventName == kSystemTrayEventRightClick) {
        _systemTray.popUpContextMenu();
      }
    });

    _listenForAppearanceChanges();
  }

  void listenToTimer(TimerService timerService) {
    _timerSubscription?.cancel();
    _timerSubscription = timerService.statusStream.listen((status) {
      _updateTooltipFromStatus(status);
    });
  }

  Future<void> _toggleMainWindow() async {
    final isVisible = await windowManager.isVisible();
    if (isVisible) {
      await windowManager.hide();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  }

  void _listenForAppearanceChanges() {
    SchedulerBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
      _systemTray.setSystemTrayInfo(iconPath: _getTrayIconPath());
    };
  }

  String _getTrayIconPath() {
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark
        ? 'assets/icons/tray_icon_dark.png'
        : 'assets/icons/tray_icon.png';
  }

  void _updateTooltipFromStatus(TimerStatus status) {
    String tooltip;
    switch (status.state) {
      case TimerState.working:
        tooltip = 'Chirp - Next break in ${status.remainingFormatted}';
      case TimerState.preBreak:
        tooltip = 'Chirp - Break starting in ${status.remainingFormatted}';
      case TimerState.onBreak:
        final type =
            status.nextBreakType == BreakType.long ? 'Long break' : 'Break';
        tooltip = 'Chirp - $type ${status.remainingFormatted}';
      case TimerState.paused:
        tooltip = 'Chirp - Paused';
      case TimerState.idle:
        tooltip = 'Chirp - Idle';
    }
    _systemTray.setToolTip(tooltip);
  }

  Future<void> _updateMenu({String? timerInfo}) async {
    final menu = Menu();
    final items = <MenuItemBase>[
      MenuItemLabel(
        label: timerInfo ?? 'Chirp',
        onClicked: (menuItem) async {
          await windowManager.show();
          await windowManager.focus();
        },
      ),
      MenuSeparator(),
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
        label: 'Quit Chirp',
        onClicked: (menuItem) async {
          await _systemTray.destroy();
          await windowManager.setPreventClose(false);
          await windowManager.destroy();
          exit(0);
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
