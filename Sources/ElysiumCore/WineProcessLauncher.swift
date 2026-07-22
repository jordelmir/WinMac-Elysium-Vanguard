import Foundation
import os

public enum WineBinarySource: String, Codable {
    case elysiumWine = "Elysium Vanguard Internal Wine"
    case wineStable = "Wine Stable 11.0 (WoW64 Native)"
    case whiskyWine = "WhiskyWine (Proton-based)"
    case wineGE = "Wine-GE (GloriousEggroll)"
    case crossoverWine = "CrossOver Wine (CodeWeavers)"
    case gamePortingToolkit = "Apple Game Porting Toolkit 2.x"
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
        
        let elysiumWineBinary = WineDownloader.shared.elysiumWineDir.appendingPathComponent("bin/wine64")
        
        let searchPaths: [(URL, WineBinarySource, String)] = [
            (URL(fileURLWithPath: "/Applications/Wine Stable.app/Contents/Resources/wine/bin/wine"), .wineStable, "11.0"),
            (elysiumWineBinary, .elysiumWine, "2.0"),
            (URL(fileURLWithPath: "/usr/local/opt/game-porting-toolkit/bin/wine64"), .gamePortingToolkit, "2.0"),
            (URL(fileURLWithPath: "/opt/homebrew/opt/game-porting-toolkit/bin/wine64"), .gamePortingToolkit, "2.0"),
            (URL(fileURLWithPath: "\(NSHomeDirectory())/Library/Application Support/com.isaacmarovitz.Whisky/Libraries/Wine/bin/wine64"), .whiskyWine, "9.x"),
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
        
        let priorityOrder: [WineBinarySource]
        switch profile.cpuArch {
        case .appleSilicon:
            priorityOrder = [.wineStable, .elysiumWine, .gamePortingToolkit, .whiskyWine, .crossoverWine, .wineGE]
        case .intelx86:
            priorityOrder = [.wineStable, .elysiumWine, .crossoverWine, .wineGE, .whiskyWine, .gamePortingToolkit]
        }
        
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
        
        let process = Process()
        process.executableURL = wine.wineBinaryPath
        process.arguments = [entry.mainExecutablePath]
        process.currentDirectoryURL = URL(fileURLWithPath: entry.gameFolderPath)
        
        var env = ProcessInfo.processInfo.environment
        
        for (k, v) in bottleConfig.environmentVariables { env[k] = v }
        
        let engineProfile = GameEngineProfileDetector.shared.detectEngine(
            in: URL(fileURLWithPath: entry.gameFolderPath),
            mainExeName: entry.mainExecutablePath
        )
        for (k, v) in engineProfile.recommendedEnv { env[k] = v }
        
        let shaderEnv = ShaderCacheManager.shared.prepareShaderCache(for: entry.gameName)
        for (k, v) in shaderEnv { env[k] = v }
        
        if let patch = GamePatchRegistry.shared.findPatch(for: URL(fileURLWithPath: entry.mainExecutablePath).lastPathComponent) {
            for (k, v) in patch.envOverrides { env[k] = v }
            logger.log(.info, subsystem: "WineLauncher", message: "Applied game patch overrides: \(patch.notes)")
        }
        
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
