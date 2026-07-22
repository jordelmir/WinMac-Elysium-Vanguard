import Foundation

public struct GameFixPatch: Codable {
    public let gameTitlePattern: String
    public let envOverrides: [String: String]
    public let dllOverrides: [String: String]
    public let notes: String
}

public final class GamePatchRegistry {
    public static let shared = GamePatchRegistry()
    
    private var patches: [GameFixPatch] = []
    
    private init() {
        registerDefaultPatches()
    }
    
    private func registerDefaultPatches() {
        patches.append(GameFixPatch(
            gameTitlePattern: "cyberpunk",
            envOverrides: [
                "VKD3D_CONFIG": "dxr11,dxr",
                "DXVK_STATE_CACHE": "1",
                "RADV_PERFTEST": "aco"
            ],
            dllOverrides: ["dxgi": "native,builtin"],
            notes: "Enables Ray Tracing and ACO Shader compiler for REDengine 4."
        ))
        
        patches.append(GameFixPatch(
            gameTitlePattern: "gow2",
            envOverrides: [
                "WINEESYNC": "1",
                "WINEMSYNC": "1",
                "DXVK_ASYNC": "1"
            ],
            dllOverrides: ["d3d11": "native,builtin"],
            notes: "Gears of War 2 Nativo / Unreal Engine 3 high frametime stabilization patch."
        ))
    }
    
    public func findPatch(for exeName: String) -> GameFixPatch? {
        let lower = exeName.lowercased()
        return patches.first { lower.contains($0.gameTitlePattern) }
    }
}
