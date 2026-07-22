import Foundation

public struct ExecutableMetadata: Codable {
    public let url: URL
    public let relativePath: String
    public let fileName: String
    public let detectedGraphicsAPI: String
    public let is64Bit: Bool
    public let score: Int
}

public final class ExeScanner {
    public static let shared = ExeScanner()
    
    private let ignoredNames: Set<String> = [
        "setup.exe", "install.exe", "installer.exe", "unins000.exe", "uninstall.exe",
        "dxsetup.exe", "vc_redist.x64.exe", "vc_redist.x86.exe", "vcredist_x64.exe",
        "vcredist_x86.exe", "crashreporter.exe", "unitycrashhandler64.exe",
        "unitycrashhandler32.exe", "unrealrecoverytool.exe", "epicgamesserver.exe",
        "easynanti_setup.exe", "battleye_setup.exe", "uplay_installer.exe"
    ]
    
    private init() {}
    
    public func scanGameFolder(at folderURL: URL) -> ExecutableMetadata? {
        let fileManager = FileManager.default
        
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: folderURL.path, isDirectory: &isDir), !isDir.boolValue {
            // Direct .exe file selection
            guard folderURL.pathExtension.lowercased() == "exe" else { return nil }
            let (graphicsAPI, is64Bit) = inspectPEHeader(at: folderURL)
            return ExecutableMetadata(
                url: folderURL,
                relativePath: folderURL.lastPathComponent,
                fileName: folderURL.lastPathComponent,
                detectedGraphicsAPI: graphicsAPI,
                is64Bit: is64Bit,
                score: 1000
            )
        }
        
        guard let enumerator = fileManager.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }
        
        var candidates: [ExecutableMetadata] = []
        
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension.lowercased() == "exe" else { continue }
            let fileName = fileURL.lastPathComponent.lowercased()
            
            if ignoredNames.contains(fileName) { continue }
            
            let relativePath = fileURL.path.replacingOccurrences(of: folderURL.path + "/", with: "")
            let (graphicsAPI, is64Bit) = inspectPEHeader(at: fileURL)
            
            // Score calculation
            var score = 100
            let depth = relativePath.components(separatedBy: "/").count - 1
            score -= (depth * 15) // Prefer root or shallow executables
            
            if fileName.contains("game") || fileName.contains("launch") || fileName.contains("win64") {
                score += 30
            }
            if relativePath.contains("Binaries/Win64") || relativePath.contains("bin/x64") {
                score += 40
            }
            
            candidates.append(ExecutableMetadata(
                url: fileURL,
                relativePath: relativePath,
                fileName: fileURL.lastPathComponent,
                detectedGraphicsAPI: graphicsAPI,
                is64Bit: is64Bit,
                score: score
            ))
        }
        
        return candidates.max(by: { $0.score < $1.score })
    }
    
    private func inspectPEHeader(at fileURL: URL) -> (graphicsAPI: String, is64Bit: Bool) {
        guard let handle = try? FileHandle(forReadingFrom: fileURL) else {
            return ("DirectX (Default)", true)
        }
        defer { try? handle.close() }
        
        guard let dosData = try? handle.read(upToCount: 64), dosData.count >= 64 else {
            return ("DirectX (Default)", true)
        }
        
        let dosHeader = dosData.withUnsafeBytes { $0.bindMemory(to: UInt8.self) }
        guard dosHeader[0] == 0x4D && dosHeader[1] == 0x5A else { // 'MZ'
            return ("DirectX (Default)", true)
        }
        
        // e_lfanew offset is at 0x3C
        let e_lfanew = dosData.withUnsafeBytes { $0.load(fromByteOffset: 0x3C, as: UInt32.self) }
        
        try? handle.seek(toOffset: UInt64(e_lfanew))
        guard let peData = try? handle.read(upToCount: 24), peData.count >= 24 else {
            return ("DirectX (Default)", true)
        }
        
        let peHeader = peData.withUnsafeBytes { $0.bindMemory(to: UInt8.self) }
        guard peHeader[0] == 0x50 && peHeader[1] == 0x45 else { // 'PE\0\0'
            return ("DirectX (Default)", true)
        }
        
        let machine = peData.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt16.self) }
        let is64Bit = (machine == 0x8664) // IMAGE_FILE_MACHINE_AMD64
        
        // Quick scan for graphics API strings in PE imports (first 8KB)
        try? handle.seek(toOffset: 0)
        if let sampleData = try? handle.read(upToCount: 8192),
           let sampleString = String(data: sampleData, encoding: .ascii)?.lowercased() {
            if sampleString.contains("d3d12.dll") {
                return ("DirectX 12 (D3D12)", is64Bit)
            } else if sampleString.contains("d3d11.dll") {
                return ("DirectX 11 (D3D11)", is64Bit)
            } else if sampleString.contains("vulkan-1.dll") {
                return ("Vulkan Engine", is64Bit)
            } else if sampleString.contains("d3d9.dll") {
                return ("DirectX 9 (D3D9)", is64Bit)
            }
        }
        
        return ("DirectX 11/12", is64Bit)
    }
}
