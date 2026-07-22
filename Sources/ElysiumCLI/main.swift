import Foundation
import ElysiumCore
import ElysiumUI

let args = CommandLine.arguments
let command = args.count > 1 ? args[1] : "status"

func printBanner() {
    print("""
    
    🌌 ════════════════════════════════════════════════════════════ 🌌
    ⚡        WINMAC ELYSIUM VANGUARD — COMMAND CENTER v1.0        ⚡
    🌌 ════════════════════════════════════════════════════════════ 🌌
    """)
}

func printStatus() {
    printBanner()
    
    // Hardware
    let hw = HardwareProbe.shared.detectProfile()
    print("  ┌─ HARDWARE ──────────────────────────────────────────────┐")
    print("  │  CPU Architecture   : \(hw.cpuArch.rawValue)")
    print("  │  GPU Device         : \(hw.gpuName)")
    print("  │  Metal 3 Support    : \(hw.isMetal3Supported ? "YES ✅" : "NO (Legacy Mode)")")
    print("  │  Target Pipeline    : \(hw.recommendedPipeline.rawValue)")
    print("  └─────────────────────────────────────────────────────────┘\n")
    
    // Wine Runtimes
    let wines = WineProcessLauncher.shared.discoverWineInstallations()
    print("  ┌─ WINE RUNTIMES ─────────────────────────────────────────┐")
    if wines.isEmpty {
        print("  │  ⚠️  No Wine installations detected on this system.")
        print("  │  Install via: brew install --cask game-porting-toolkit")
    } else {
        for (i, w) in wines.enumerated() {
            let marker = (i == 0) ? "★" : "·"
            print("  │  \(marker) \(w.source.rawValue) v\(w.version)")
            print("  │    \(w.wineBinaryPath.path)")
        }
    }
    print("  └─────────────────────────────────────────────────────────┘\n")
    
    // Neon Theme
    let theme = NeonThemeEngine.shared
    print("  ┌─ NEON PALETTE ──────────────────────────────────────────┐")
    print("  │  Primary     \(theme.currentPalette.primaryHex)  │  Secondary   \(theme.currentPalette.secondaryHex)")
    print("  │  Tertiary    \(theme.currentPalette.tertiaryHex)  │  Quaternary  \(theme.currentPalette.quaternaryHex)")
    print("  └─────────────────────────────────────────────────────────┘\n")
    
    // Game Library
    let library = GameLibraryStore.shared
    print("  ┌─ GAME LIBRARY ──────────────────────────────────────────┐")
    if library.games.isEmpty {
        print("  │  (empty) — Use 'elysium-cli scan <folder>' to add games")
    } else {
        for game in library.games {
            let hours = Int(game.totalPlayTimeSeconds / 3600)
            print("  │  🎮 \(game.gameName)")
            print("  │     API: \(game.detectedGraphicsAPI) | Engine: \(game.engineType.rawValue)")
            print("  │     Plays: \(game.totalLaunchCount) | Time: \(hours)h")
        }
    }
    print("  └─────────────────────────────────────────────────────────┘\n")
    
    print("  Commands: status | scan <folder> | launch <game-name> | gui")
}

func scanFolder(_ path: String) {
    printBanner()
    let url = URL(fileURLWithPath: path)
    print("  🔍 Scanning: \(url.path)\n")
    
    guard let exe = ExeScanner.shared.scanGameFolder(at: url) else {
        print("  ❌ No valid Windows executable found in folder.")
        return
    }
    
    print("  ✅ Detected Executable:")
    print("     File        : \(exe.fileName)")
    print("     Path        : \(exe.relativePath)")
    print("     Graphics    : \(exe.detectedGraphicsAPI)")
    print("     Arch        : \(exe.is64Bit ? "64-bit (x64)" : "32-bit (x86)")")
    print("     Score       : \(exe.score)\n")
    
    // Engine detection
    let engine = GameEngineProfileDetector.shared.detectEngine(in: url, mainExeName: exe.fileName)
    print("  🏗  Engine Detected : \(engine.engineType.rawValue)")
    print("     MetalFX Support : \(engine.supportsMetalFX ? "YES" : "NO")")
    print("     FPS Limit       : \(engine.defaultFPSLimit)\n")
    
    // Add to library
    do {
        let entry = try GameLibraryStore.shared.addGame(from: url)
        print("  🍾 Added to library: \(entry.gameName)")
        print("     Bottle ID     : \(entry.bottleID?.uuidString.prefix(8) ?? "none")")
    } catch {
        print("  ❌ Error: \(error.localizedDescription)")
    }
}

func launchGame(_ name: String) {
    printBanner()
    let library = GameLibraryStore.shared
    guard let game = library.games.first(where: { $0.gameName.lowercased().contains(name.lowercased()) }) else {
        print("  ❌ Game '\(name)' not found in library. Use 'scan' first.")
        return
    }
    
    guard let wine = WineProcessLauncher.shared.selectBestWine() else {
        print("  ❌ No Wine installation found.")
        return
    }
    
    let profile = HardwareProbe.shared.detectProfile()
    let config = BottleConfiguration(
        bottleID: game.bottleID ?? UUID(),
        name: game.gameName,
        bottlePath: URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/ElysiumVanguard/Bottles"),
        targetPipeline: profile.recommendedPipeline,
        environmentVariables: [:],
        createdDate: Date()
    )
    
    do {
        print("  🚀 Launching: \(game.gameName)")
        print("     Wine: \(wine.source.rawValue) v\(wine.version)")
        print("     Pipeline: \(profile.recommendedPipeline.rawValue)")
        let process = try WineProcessLauncher.shared.launchGame(entry: game, bottleConfig: config, wine: wine)
        print("  ✅ Process started (PID: \(process.processIdentifier))")
        process.waitUntilExit()
        let exitCode = process.terminationStatus
        print("  🏁 Game exited with code: \(exitCode)")
    } catch {
        print("  ❌ Launch failed: \(error.localizedDescription)")
    }
}

// ── MAIN DISPATCH ──────────────────────────────────────────────

switch command {
case "status":
    printStatus()
case "scan":
    guard args.count > 2 else {
        print("  Usage: elysium-cli scan <path-to-game-folder>")
        exit(1)
    }
    scanFolder(args[2])
case "launch":
    guard args.count > 2 else {
        print("  Usage: elysium-cli launch <game-name>")
        exit(1)
    }
    launchGame(args[2...].joined(separator: " "))
case "gui":
    printBanner()
    print("  Launching GUI... (use 'elysium-app' binary for the full UI experience)")
default:
    print("  Unknown command: \(command)")
    print("  Commands: status | scan <folder> | launch <game-name> | gui")
}
