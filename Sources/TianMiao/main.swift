import Cocoa
import QuartzCore
import ServiceManagement
import Sparkle
import UserNotifications


final class AppDelegate: NSObject, NSApplicationDelegate {
    private let petController = PetController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        petController.start()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
