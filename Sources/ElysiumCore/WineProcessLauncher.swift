import Foundation
import os

public enum WineBinarySource: String, Codable {
    case elysiumWine = "Elysium Vanguard Built-In Wine 11.13 (WoW64 Native)"
    case wineStable = "Wine Stable 11.0"
    case wineGE = "Wine-GE (GloriousEggroll)"
    case crossoverWine = "CrossOver Wine (CodeWeavers)"
    case gamePortingToolkit = "Apple Game Porting Toolkit"
}

public struct WineInstallation: Codable {
    public let source: WineBinarySource
    public let version: String
    public let installPath: URL
    public let wineBinaryPath: URL
    public let wineserverPath: URL
}

public final class WineProcessLauncher {
    public static let shared = WineProcessLauncher()
    
    private let fileManager = FileManager.default
    private let logger = ElysiumLogger.shared
    
    private init() {}
    
    /// Searches for installed Wine binaries on the system.
    public func discoverWineInstallations() -> [WineInstallation] {
        logger.log(.info, subsystem: "WineLauncher", message: "Searching for system Wine installations...")
        var installs: [WineInstallation] = []
        
        let customWine11Binary = URL(fileURLWithPath: "/Users/jordelmirsdevhome/Wine/wine-11.13-install/bin/wine")
        let elysiumWineAppBinary = WineDownloader.shared.elysiumWineDir.appendingPathComponent("Wine Staging.app/Contents/Resources/wine/bin/wine")
        let elysiumWineBinary = WineDownloader.shared.elysiumWineDir.appendingPathComponent("bin/wine")
        
        let searchPaths: [(URL, WineBinarySource, String)] = [
            (elysiumWineAppBinary, .elysiumWine, "11.13-Staging"),
            (customWine11Binary, .elysiumWine, "11.13-WoW64-Builtin"),
            (elysiumWineBinary, .elysiumWine, "11.x"),
            (URL(fileURLWithPath: "/Applications/Wine Stable.app/Contents/Resources/wine/bin/wine"), .wineStable, "11.0"),
            (URL(fileURLWithPath: "/usr/local/opt/game-porting-toolkit/bin/wine64"), .gamePortingToolkit, "2.0"),
            (URL(fileURLWithPath: "/opt/homebrew/opt/game-porting-toolkit/bin/wine64"), .gamePortingToolkit, "2.0"),
            (URL(fileURLWithPath: "/usr/local/bin/wine64"), .wineGE, "9.x"),
            (URL(fileURLWithPath: "/opt/homebrew/bin/wine64"), .wineGE, "9.x"),
            (URL(fileURLWithPath: "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine64"), .crossoverWine, "24.x"),
        ]
        
        for (binaryPath, source, version) in searchPaths {
            if fileManager.fileExists(atPath: binaryPath.path) {
                let binDir = binaryPath.deletingLastPathComponent()
                let wineserver = binDir.appendingPathComponent("wineserver")
                
                let inst = WineInstallation(
                    source: source,
                    version: version,
                    installPath: binDir.deletingLastPathComponent(),
                    wineBinaryPath: binaryPath,
                    wineserverPath: wineserver
                )
                installs.append(inst)
                logger.log(.info, subsystem: "WineLauncher", message: "Discovered Wine runtime: \(source.rawValue) at \(binaryPath.path)")
            }
        }
        
        if installs.isEmpty {
            logger.log(.warning, subsystem: "WineLauncher", message: "No Wine installation discovered on host system.")
        }
        
        return installs
    }
    
    /// Selects the best available Wine installation ranked by priority.
    public func selectBestWine() -> WineInstallation? {
        let installs = discoverWineInstallations()
        let profile = HardwareProbe.shared.detectProfile()
        
        let priorityOrder: [WineBinarySource] = [.elysiumWine, .wineStable, .gamePortingToolkit, .crossoverWine, .wineGE]
        
        for preferred in priorityOrder {
            if let found = installs.first(where: { $0.source == preferred }) {
                logger.log(.info, subsystem: "WineLauncher", message: "Selected optimal Wine runtime for \(profile.cpuArch.rawValue): \(found.source.rawValue)")
                return found
            }
        }
        
        let fallback = installs.first
        if let fallback = fallback {
            logger.log(.info, subsystem: "WineLauncher", message: "Using fallback Wine runtime: \(fallback.source.rawValue)")
        }
        return fallback
    }
    
    /// Launches a Windows executable through Wine with full Elysium environment injection.
    public func launchGame(
        entry: InstalledGameEntry,
        bottleConfig: BottleConfiguration,
        wine: WineInstallation
    ) throws -> Process {
        logger.log(.info, subsystem: "WineLauncher", message: "Initiating launch for game '\(entry.gameName)'", details: [
            "exe": entry.mainExecutablePath,
            "wine": wine.source.rawValue,
            "pipeline": bottleConfig.targetPipeline.rawValue
        ])
        
        let exeURL = URL(fileURLWithPath: entry.mainExecutablePath)
        let exeDir = exeURL.deletingLastPathComponent()
        
        let process = Process()
        process.executableURL = wine.wineBinaryPath
        
        // Use PerformanceOptimizer turbo profile
        let profile = PerformanceOptimizer.shared.getProfile(for: entry.gameName, exeName: exeURL.lastPathComponent)
        var env = PerformanceOptimizer.shared.buildOptimizedEnvironment(profile: profile)
        
        // Bottle prefix
        let prefixURL = bottleConfig.bottlePath.appendingPathComponent("\(entry.gameName.replacingOccurrences(of: " ", with: "_"))_Prefix")
        env["WINEPREFIX"] = prefixURL.path
        
        for (k, v) in bottleConfig.environmentVariables { env[k] = v }
        
        if let patch = GamePatchRegistry.shared.findPatch(for: exeURL.lastPathComponent) {
            for (k, v) in patch.envOverrides { env[k] = v }
            logger.log(.info, subsystem: "WineLauncher", message: "Applied game patch overrides: \(patch.notes)")
        }
        
        process.executableURL = wine.wineBinaryPath
        process.arguments = [exeURL.lastPathComponent] + profile.gameArguments
        process.currentDirectoryURL = exeDir
        process.environment = env
        
        do {
            try process.run()
            logger.log(.info, subsystem: "WineLauncher", message: "Process launched successfully (PID: \(process.processIdentifier))")
            return process
        } catch {
            logger.log(.error, subsystem: "WineLauncher", message: "Failed to launch process: \(error.localizedDescription)", details: [
                "error": String(describing: error)
            ])
            throw error
        }
    }
}
