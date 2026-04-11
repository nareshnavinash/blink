import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let overlayRegistrar = flutterViewController.registrar(forPlugin: "OverlayWindowManager")
    OverlayWindowManager.shared.register(with: overlayRegistrar)

    super.awakeFromNib()
  }
}
