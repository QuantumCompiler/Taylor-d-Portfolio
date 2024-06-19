import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let initialSize = CGSize(width: 970, height: 620)
    self.setContentSize(initialSize)
    self.contentViewController = flutterViewController
    self.setFrame(self.frameRect(forContentRect: NSRect(origin: CGPoint.zero, size: initialSize)), display: true)
    self.minSize = NSSize(width: 970, height: 600)
    self.center()
    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
  }
}
