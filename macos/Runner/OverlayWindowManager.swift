import Cocoa
import FlutterMacOS

class OverlayWindowManager: NSObject {
    static let shared = OverlayWindowManager()
    private var overlayWindows: [NSWindow] = []
    private var savedMainWindowLevel: NSWindow.Level = .normal
    private var savedMainWindowCollectionBehavior: NSWindow.CollectionBehavior = []

    func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.chirp/overlay",
            binaryMessenger: registrar.messenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "showOverlays":
                self?.showOverlays(result: result)
            case "hideOverlays":
                self?.hideOverlays(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func showOverlays(result: FlutterResult) {
        hideOverlaysInternal()

        let screens = NSScreen.screens
        guard let primaryScreen = screens.first else {
            result(nil)
            return
        }

        // Elevate the main Flutter window above fullscreen apps
        if let mainWindow = NSApp.windows.first(where: { $0 is MainFlutterWindow }) {
            savedMainWindowLevel = mainWindow.level
            savedMainWindowCollectionBehavior = mainWindow.collectionBehavior
            mainWindow.level = .screenSaver
            mainWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        }

        // Create dark overlay on each non-primary screen
        for screen in screens {
            if screen == primaryScreen { continue }

            let overlay = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )
            overlay.level = .screenSaver
            overlay.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            overlay.backgroundColor = NSColor.black.withAlphaComponent(0.85)
            overlay.isOpaque = false
            overlay.hasShadow = false
            overlay.ignoresMouseEvents = true
            overlay.orderFrontRegardless()

            overlayWindows.append(overlay)
        }

        result(nil)
    }

    private func hideOverlays(result: FlutterResult) {
        hideOverlaysInternal()

        // Restore the main Flutter window to normal level
        if let mainWindow = NSApp.windows.first(where: { $0 is MainFlutterWindow }) {
            mainWindow.level = savedMainWindowLevel
            mainWindow.collectionBehavior = savedMainWindowCollectionBehavior
        }

        result(nil)
    }

    private func hideOverlaysInternal() {
        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
    }
}
