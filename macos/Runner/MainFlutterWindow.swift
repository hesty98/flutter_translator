import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var directoryPickerChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    directoryPickerChannel = FlutterMethodChannel(
      name: "flutter_translator/directory_picker",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    directoryPickerChannel?.setMethodCallHandler { call, result in
      guard call.method == "pickProjectDirectory" else {
        result(FlutterMethodNotImplemented)
        return
      }

      let panel = NSOpenPanel()
      panel.canChooseDirectories = true
      panel.canChooseFiles = false
      panel.allowsMultipleSelection = false
      panel.canCreateDirectories = false
      panel.prompt = "Select"

      let response = panel.runModal()
      guard response == .OK, let url = panel.url else {
        result(nil)
        return
      }

      do {
        let bookmark = try url.bookmarkData(
          options: .withSecurityScope,
          includingResourceValuesForKeys: nil,
          relativeTo: nil
        ).base64EncodedString()

        result([
          "path": url.path,
          "bookmark": bookmark,
        ])
      } catch {
        result(
          FlutterError(
            code: "bookmark_failed",
            message: "Failed to create bookmark for \(url.path)",
            details: "\(error)"
          )
        )
      }
    }

    super.awakeFromNib()
  }
}
