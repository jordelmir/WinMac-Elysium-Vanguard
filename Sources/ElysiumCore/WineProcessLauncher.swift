import Foundation
import os

public enum WineBinarySource: String, Codable {
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
    
    private let logger = Logger(subsystem: "com.elysium.vanguard", category: "WineProcess")
    private let fileManager = FileManager.default
    
    private init() {}
    
    /// Searches for installed Wine binaries on the system.
    public func discoverWineInstallations() -> [WineInstallation] {
        var installs: [WineInstallation] = []
        
        let searchPaths: [(URL, WineBinarySource, String)] = [
            // GPTK (Apple Game Porting Toolkit)
            (URL(fileURLWithPath: "/usr/local/opt/game-porting-toolkit/bin/wine64"), .gamePortingToolkit, "2.0"),
            (URL(fileURLWithPath: "/opt/homebrew/opt/game-porting-toolkit/bin/wine64"), .gamePortingToolkit, "2.0"),
            // WhiskyWine
            (URL(fileURLWithPath: "\(NSHomeDirectory())/Library/Application Support/com.isaacmarovitz.Whisky/Libraries/Wine/bin/wine64"), .whiskyWine, "9.x"),
            // Wine-GE / Proton-GE custom
            (URL(fileURLWithPath: "/usr/local/bin/wine64"), .wineGE, "9.x"),
            (URL(fileURLWithPath: "/opt/homebrew/bin/wine64"), .wineGE, "9.x"),
            // CrossOver
            (URL(fileURLWithPath: "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine64"), .crossoverWine, "24.x"),
        ]
        
        for (binaryPath, source, version) in searchPaths {
            if fileManager.fileExists(atPath: binaryPath.path) {
                let binDir = binaryPath.deletingLastPathComponent()
                let wineserver = binDir.appendingPathComponent("wineserver")
                
                installs.append(WineInstallation(
                    source: source,
                    version: version,
                    installPath: binDir.deletingLastPathComponent(),
                    wineBinaryPath: binaryPath,
                    wineserverPath: wineserver
                ))
            }
        }
        
        return installs
    }
    
    /// Selects the best available Wine installation ranked by priority.
    public func selectBestWine() -> WineInstallation? {
        let installs = discoverWineInstallations()
        let profile = HardwareProbe.shared.detectProfile()
        
        // Priority order depends on architecture
        let priorityOrder: [WineBinarySource]
        switch profile.cpuArch {
        case .appleSilicon:
            priorityOrder = [.gamePortingToolkit, .whiskyWine, .crossoverWine, .wineGE]
        case .intelx86:
            priorityOrder = [.crossoverWine, .wineGE, .whiskyWine, .gamePortingToolkit]
        }
        
        for preferred in priorityOrder {
            if let found = installs.first(where: { $0.source == preferred }) {
                return found
            }
        }
        
        return installs.first
    }
    
    /// Launches a Windows executable through Wine with full Elysium environment injection.
    public func launchGame(
        entry: InstalledGameEntry,
        bottleConfig: BottleConfiguration,
        wine: WineInstallation
    ) throws -> Process {
        let process = Process()
        process.executableURL = wine.wineBinaryPath
        process.arguments = [entry.mainExecutablePath]
        process.currentDirectoryURL = URL(fileURLWithPath: entry.gameFolderPath)
        
        // Build merged environment
        var env = ProcessInfo.processInfo.environment
        
        // 1. Bottle base environment
        for (k, v) in bottleConfig.environmentVariables {
            env[k] = v
        }
        
        // 2. Engine tuning overlay
        let engineProfile = GameEngineProfileDetector.shared.detectEngine(
            in: URL(fileURLWithPath: entry.gameFolderPath),
            mainExeName: entry.mainExecutablePath
        )
        for (k, v) in engineProfile.recommendedEnv {
            env[k] = v
        }
        
        // 3. Shader cache paths
        let shaderEnv = ShaderCacheManager.shared.prepareShaderCache(for: entry.gameName)
        for (k, v) in shaderEnv {
            env[k] = v
        }
        
        // 4. Game-specific patch overlay
        if let patch = GamePatchRegistry.shared.findPatch(for: URL(fileURLWithPath: entry.mainExecutablePath).lastPathComponent) {
            for (k, v) in patch.envOverrides {
                env[k] = v
            }
        }
        
        process.environment = env
        
        logger.info("🚀 Launching: \(entry.gameName)")
        logger.info("   EXE: \(entry.mainExecutablePath)")
        logger.info("   Wine: \(wine.source.rawValue) (\(wine.version))")
        logger.info("   Pipeline: \(bottleConfig.targetPipeline.rawValue)")
        
        try process.run()
        return process
    }
}
