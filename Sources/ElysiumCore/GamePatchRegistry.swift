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
        
        // ── GoW2 / UE3 32-bit on Apple Silicon comprehensive fix ──
        patches.append(GameFixPatch(
            gameTitlePattern: "gow2",
            envOverrides: [
                // Thread sync
                "WINEESYNC": "1",
                // 32-bit memory management — prevents virtual.c assertion
                "WINE_LARGE_ADDRESS_AWARE": "0",
                "WINE_HEAP_DELAY_FREE": "0",
                // OpenGL compatibility (GPTK 1.x has no Vulkan)
                "MESA_GL_VERSION_OVERRIDE": "4.6",
                "MESA_GLSL_VERSION_OVERRIDE": "460",
                // Metal GPU stability
                "MVK_CONFIG_RESUME_LOST_DEVICE": "1",
                // Suppress noisy debug output
                "WINEDEBUG": "fixme-all,warn-all"
            ],
            dllOverrides: [
                // Use Wine's built-in D3D9 → OpenGL (wined3d)
                "d3d9": "builtin",
                "d3d11": "builtin",
                "dxgi": "builtin",
                "d3d10core": "builtin",
                // Use game's own DLLs for these
                "dbghelp": "native,builtin",
                "steam_api": "native"
            ],
            notes: "Gears of War 2 (UE3 32-bit): virtual.c fix, texture streaming disabled, memory pressure reduced, OpenGL forced."
        ))
    }
    
    public func findPatch(for exeName: String) -> GameFixPatch? {
        let lower = exeName.lowercased()
        return patches.first { lower.contains($0.gameTitlePattern) }
    }
}
