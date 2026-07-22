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
        print("  │  Run: 'elysium-cli setup-wine' to auto-download Wine runtime.")
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
    
    print("  Commands: status | setup-wine | scan <folder> | launch <game-name> | gui")
}

func setupWine() {
    printBanner()
    print("  🚀 Initiating automated 1-click Wine Runtime Download & Installation...")
    let semaphore = DispatchSemaphore(value: 0)
    
    WineDownloader.shared.downloadAndInstallWine { progress, status in
        print("  [Progress: \(Int(progress * 100))%] \(status)")
    } completion: { result in
        switch result {
        case .success(let binaryPath):
            print("  ✅ Wine Runtime installed successfully!")
            print("     Binary: \(binaryPath.path)")
        case .failure(let error):
            print("  ❌ Download/Extraction failed: \(error.localizedDescription)")
        }
        semaphore.signal()
    }
    
    semaphore.wait()
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
    
    let engine = GameEngineProfileDetector.shared.detectEngine(in: url, mainExeName: exe.fileName)
    print("  🏗  Engine Detected : \(engine.engineType.rawValue)")
    print("     MetalFX Support : \(engine.supportsMetalFX ? "YES" : "NO")")
    print("     FPS Limit       : \(engine.defaultFPSLimit)\n")
    
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
        print("  👉 Run: 'elysium-cli setup-wine' to download the Wine runtime automatically.")
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

func printAIGuide() {
    printBanner()
    print("""
    🤖 ══════════════════════════════════════════════════════════════════ 🤖
       AI AGENT OPERATIONAL DIRECTIVE & SYSTEM INTERFACE GUIDELINES
    🤖 ══════════════════════════════════════════════════════════════════ 🤖
    
    1. CLI COMMAND INTERFACE:
       - elysium-cli status            : Inspect hardware, Wine installations & library
       - elysium-cli scan <folder>     : Auto-detect executable & add game to library
       - elysium-cli launch <game>     : Launch game with optimal Wine profile
       - elysium-cli diagnose          : Read active processes, logs & memory pressure
       - elysium-cli gow2              : Instant launch Gears of War 2 optimized profile
       - elysium-cli ai-guide          : Print this AI Operational Specification
    
    2. PERFORMANCE TUNING RECEPTACLE (UE3 / 32-bit Games):
       - Memory Crash Fix: Set WINE_LARGE_ADDRESS_AWARE=0 (prevents 32-bit overflow)
       - Multi-thread Sync: Set WINEESYNC=1 and WINEMSYNC=1
       - Renderer Overrides: WINEDLLOVERRIDES="d3d9=builtin;d3d11=builtin;dxgi=builtin;dbghelp=n"
       - Resolution & Display: Pass -windowed -ResX=1280 -ResY=720 -NOSPLASH
    
    3. LOG FILES & TELEMETRY:
       - Game Logs: ~/Library/Application Support/ElysiumVanguard/Logs/
       - Bottles  : ~/Library/Application Support/ElysiumVanguard/Bottles/
       - Built-In Wine: /Users/jordelmirsdevhome/Wine/wine-11.13-install/bin/wine
    """)
}

func printDiagnose() {
    printBanner()
    print("  🩺 RUNTIME DIAGNOSTICS & SYSTEM PERFORMANCE TELEMETRY\n")
    
    let hw = HardwareProbe.shared.detectProfile()
    print("  ► GPU: \(hw.gpuName) | Metal 3: \(hw.isMetal3Supported ? "YES ✅" : "NO")")
    print("  ► CPU Cores: \(ProcessInfo.processInfo.activeProcessorCount) cores")
    print("  ► Physical Memory: \(ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024)) GB\n")
    
    print("  ► Checking Active Wine Processes...")
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/ps")
    task.arguments = ["aux"]
    let pipe = Pipe()
    task.standardOutput = pipe
    try? task.run()
    task.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let psOutput = String(data: data, encoding: .utf8) {
        let lines = psOutput.components(separatedBy: "\n").filter { $0.contains("wine") && !$0.contains("grep") }
        if lines.isEmpty {
            print("     (No active Wine processes running)")
        } else {
            for line in lines.prefix(5) {
                print("     [PROC] \(line.prefix(120))")
            }
        }
    }
    
    print("\n  ► Checking System Log Directory...")
    let logDir = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support/ElysiumVanguard/Logs")
    if let files = try? FileManager.default.contentsOfDirectory(atPath: logDir.path) {
        for f in files {
            print("     [LOG] \(f)")
        }
    } else {
        print("     (No logs found in \(logDir.path))")
    }
}

func launchGOW2Direct() {
    printBanner()
    print("  🎮 Launching Gears of War 2 via Optimized Wine 11.13 Profile...")
    let scriptPath = "/Users/jordelmirsdevhome/Downloads/Juegos/Win Mac Elysium Vanguard /Scripts/launch_gow2_wine11.sh"
    guard FileManager.default.fileExists(atPath: scriptPath) else {
        print("  ❌ Launcher script not found at: \(scriptPath)")
        return
    }
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = [scriptPath]
    try? process.run()
    print("  ✅ Process spawned successfully (PID: \(process.processIdentifier))")
}

func startAIServer() {
    printBanner()
    print("  🤖 Starting AI Terminal Server on http://localhost:19847")
    print("  ─────────────────────────────────────────────────────────")
    print("  Endpoints:")
    print("    GET  /health           — Server health check")
    print("    GET  /status           — Hardware, Wine, game library (JSON)")
    print("    GET  /diagnose         — CPU, RAM, memory pressure, Wine procs")
    print("    GET  /logs             — Last 50 diagnostic log lines")
    print("    GET  /guide            — AI operational specification")
    print("    POST /command          — Execute shell: {\"command\": \"...\"}")
    print("    POST /launch           — Launch game: {\"game\": \"gow2\"}")
    print("  ─────────────────────────────────────────────────────────")
    print("  Press Ctrl+C to stop\n")
    
    AITerminalServer.shared.start()
    
    // Keep the process alive
    dispatchMain()
}

func printPerformanceSnapshot() {
    printBanner()
    print("  📊 REAL-TIME PERFORMANCE SNAPSHOT\n")
    
    let snapshot = AIPerformanceMonitor.shared.captureSnapshot()
    
    print("  ┌─ SYSTEM ─────────────────────────────────────────────────┐")
    print("  │  Timestamp     : \(snapshot.timestamp)")
    print("  │  CPU Cores     : \(snapshot.cpuCores)")
    print("  │  RAM           : \(snapshot.ramTotalGB) GB")
    print("  │  Load Average  : \(snapshot.loadAverage)")
    print("  │  Memory Status : \(snapshot.memoryPressure)")
    print("  │  GPU           : \(snapshot.gpuName)")
    print("  │  Metal 3       : \(snapshot.metal3Supported ? "YES ✅" : "NO")")
    print("  └─────────────────────────────────────────────────────────┘\n")
    
    print("  ┌─ WINE PROCESSES (\(snapshot.activeWineProcessCount) active) ─────────────────┐")
    if snapshot.wineProcesses.isEmpty {
        print("  │  (No active Wine processes)")
    } else {
        for proc in snapshot.wineProcesses.prefix(8) {
            print("  │  PID \(proc.pid) | CPU: \(proc.cpuPercent)% | MEM: \(proc.memPercent)% | \(proc.command.prefix(50))")
        }
    }
    print("  └─────────────────────────────────────────────────────────┘\n")
    
    print("  ┌─ AI RECOMMENDATIONS ─────────────────────────────────────┐")
    for rec in snapshot.recommendations {
        print("  │  💡 \(rec)")
    }
    print("  └─────────────────────────────────────────────────────────┘\n")
}

func runBenchmark() {
    printBanner()
    print("  ⏱  WINE ENGINE BENCHMARK\n")
    let result = AIPerformanceMonitor.shared.measureWineStartupLatency()
    print("  \(result)\n")
}

// ── MAIN DISPATCH ──────────────────────────────────────────────

switch command {
case "status":
    printStatus()
case "setup-wine":
    setupWine()
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
case "gow2":
    launchGOW2Direct()
case "diagnose":
    printDiagnose()
case "perf":
    printPerformanceSnapshot()
case "benchmark":
    runBenchmark()
case "serve":
    startAIServer()
case "ai-guide", "help":
    printAIGuide()
case "gui":
    printBanner()
    print("  Launching GUI...")
default:
    print("  Unknown command: \(command)")
    print("  Commands: status | scan | launch | gow2 | diagnose | perf | benchmark | serve | ai-guide | setup-wine | gui")
}

