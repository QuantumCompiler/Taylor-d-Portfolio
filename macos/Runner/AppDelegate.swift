import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    if let window = NSApplication.shared.windows.first {
      let initialSize = NSSize(width: 1000, height: 700)
      window.setFrame(NSRect(origin: window.frame.origin, size: initialSize), display: true)
      window.minSize = NSSize(width: 900, height: 600)
    }
    super.applicationDidFinishLaunching(notification)
  }
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}
