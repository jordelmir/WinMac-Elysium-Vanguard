import Foundation

public enum GameEngineType: String, Codable {
    case unrealEngine = "Unreal Engine (4/5)"
    case unity = "Unity Engine"
    case redEngine = "REDengine (Cyberpunk/Witcher)"
    case frostbite = "Frostbite Engine"
    case cryEngine = "CryEngine"
    case custom = "Generic / Custom Engine"
}

public struct EngineTuningProfile: Codable {
    public let engineType: GameEngineType
    public let recommendedEnv: [String: String]
    public let supportsMetalFX: Bool
    public let defaultFPSLimit: Int
}

public final class GameEngineProfileDetector {
    public static let shared = GameEngineProfileDetector()
    
    private init() {}
    
    public func detectEngine(in folderURL: URL, mainExeName: String) -> EngineTuningProfile {
        let fileManager = FileManager.default
        let folderPath = folderURL.path.lowercased()
        
        var engine: GameEngineType = .custom
        
        // Detection rules based on file structures
        if fileManager.fileExists(atPath: folderURL.appendingPathComponent("Engine/Binaries").path) ||
           folderPath.contains("unreal") {
            engine = .unrealEngine
        } else if fileManager.fileExists(atPath: folderURL.appendingPathComponent("UnityPlayer.dll").path) ||
                  fileManager.fileExists(atPath: folderURL.appendingPathComponent("MonoBleedingEdge").path) {
            engine = .unity
        } else if mainExeName.lowercased().contains("cyberpunk") || mainExeName.lowercased().contains("witcher") {
            engine = .redEngine
        }
        
        var env: [String: String] = [:]
        
        switch engine {
        case .unrealEngine:
            env["WINEESYNC"] = "1"
            env["WINEMSYNC"] = "1"
            env["DXVK_ASYNC"] = "1"
            env["RADV_PERFTEST"] = "aco"
            return EngineTuningProfile(
                engineType: engine,
                recommendedEnv: env,
                supportsMetalFX: true,
                defaultFPSLimit: 120
            )
        case .unity:
            env["WINEESYNC"] = "1"
            env["DXVK_ASYNC"] = "1"
            return EngineTuningProfile(
                engineType: engine,
                recommendedEnv: env,
                supportsMetalFX: true,
                defaultFPSLimit: 144
            )
        case .redEngine:
            env["WINEMSYNC"] = "1"
            env["DXVK_STATE_CACHE"] = "1"
            env["VKD3D_CONFIG"] = "dxr11,dxr"
            return EngineTuningProfile(
                engineType: engine,
                recommendedEnv: env,
                supportsMetalFX: true,
                defaultFPSLimit: 60
            )
        default:
            env["WINEESYNC"] = "1"
            env["DXVK_ASYNC"] = "1"
            return EngineTuningProfile(
                engineType: engine,
                recommendedEnv: env,
                supportsMetalFX: false,
                defaultFPSLimit: 60
            )
        }
    }
}
