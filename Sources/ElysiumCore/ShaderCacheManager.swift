import Foundation

public final class ShaderCacheManager {
    public static let shared = ShaderCacheManager()
    
    private let fileManager = FileManager.default
    private let baseCacheDirectory: URL
    
    private init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.baseCacheDirectory = caches.appendingPathComponent("ElysiumVanguard/ShaderCaches", isDirectory: true)
        try? fileManager.createDirectory(at: baseCacheDirectory, withIntermediateDirectories: true)
    }
    
    public func prepareShaderCache(for gameName: String) -> [String: String] {
        let sanitized = gameName.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "_")
        let gameCacheDir = baseCacheDirectory.appendingPathComponent(sanitized, isDirectory: true)
        
        try? fileManager.createDirectory(at: gameCacheDir, withIntermediateDirectories: true)
        
        return [
            "DXVK_STATE_CACHE": "1",
            "DXVK_STATE_CACHE_PATH": gameCacheDir.path,
            "VKD3D_SHADER_CACHE_DIR": gameCacheDir.path,
            "MTL_SHADER_VALIDATION": "0" // High efficiency shader execution
        ]
    }
}
