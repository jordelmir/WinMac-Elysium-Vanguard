import SwiftUI
import AppKit
import ElysiumCore
import ElysiumUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.center()
        }
    }
}

@main
struct ElysiumVanguardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup("WinMac Elysium Vanguard") {
            GameLibraryView()
                .frame(minWidth: 1000, minHeight: 700)
        }
    }
}
