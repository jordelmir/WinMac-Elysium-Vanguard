import SwiftUI
import AppKit
import ElysiumCore
import ElysiumUI

class AppDelegate: NSObject, NSApplicationDelegate {
    override init() {
        super.init()
        Self.setDockIcon()
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        Self.setDockIcon()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        Self.setDockIcon()
        
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.center()
        }
    }
    
    private static func setDockIcon() {
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = image
        } else if let logoURL = Bundle.main.url(forResource: "elysium_logo", withExtension: "jpg"),
                  let logoImage = NSImage(contentsOf: logoURL) {
            NSApp.applicationIconImage = logoImage
        } else {
            let resPath = Bundle.main.bundlePath + "/Contents/Resources/AppIcon.icns"
            if let image = NSImage(contentsOfFile: resPath) {
                NSApp.applicationIconImage = image
            }
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
