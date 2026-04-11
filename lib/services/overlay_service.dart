import 'dart:io';
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

class OverlayService {
  static const _channel = MethodChannel('com.chirp/overlay');

  Size? _savedWindowSize;
  Offset? _savedWindowPosition;

  Future<void> showBreakOverlay() async {
    if (!Platform.isMacOS) return;

    // Save current window state
    _savedWindowSize = await windowManager.getSize();
    _savedWindowPosition = await windowManager.getPosition();

    // Get primary display dimensions
    final primaryDisplay = await screenRetriever.getPrimaryDisplay();
    final screenSize = primaryDisplay.size;

    // Show native overlays on secondary screens
    await _channel.invokeMethod('showOverlays');

    // Transform main window to cover primary screen
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.setMinimumSize(const Size(0, 0));
    await windowManager.setHasShadow(false);
    await windowManager.setBackgroundColor(const Color(0x00000000));
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setVisibleOnAllWorkspaces(true,
        visibleOnFullScreen: true);
    await windowManager.setPosition(Offset.zero);
    await windowManager.setSize(Size(
      screenSize.width,
      screenSize.height,
    ));
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> hideBreakOverlay() async {
    if (!Platform.isMacOS) return;

    // Hide native overlays on secondary screens
    await _channel.invokeMethod('hideOverlays');

    // Restore main window
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setVisibleOnAllWorkspaces(false);
    await windowManager.setHasShadow(true);
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);

    if (_savedWindowSize != null) {
      await windowManager.setMinimumSize(const Size(400, 500));
      await windowManager.setSize(_savedWindowSize!);
    }
    if (_savedWindowPosition != null) {
      await windowManager.setPosition(_savedWindowPosition!);
    }

    // Hide window — menu-bar-only app should not stay visible after break
    await windowManager.hide();

    _savedWindowSize = null;
    _savedWindowPosition = null;
  }
}
