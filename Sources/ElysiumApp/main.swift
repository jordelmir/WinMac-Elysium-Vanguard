import SwiftUI
import ElysiumCore
import ElysiumUI

@main
struct ElysiumVanguardApp: App {
    var body: some Scene {
        WindowGroup("WinMac Elysium Vanguard") {
            GameLibraryView()
                .frame(minWidth: 900, minHeight: 650)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
