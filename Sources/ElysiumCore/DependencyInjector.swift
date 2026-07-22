import Foundation

public enum SystemDependency: String, CaseIterable, Codable {
    case vcrun2022 = "Visual C++ 2015-2022 Redistributable"
    case d3dcompiler47 = "Direct3D Shader Compiler (d3dcompiler_47.dll)"
    case xact = "Microsoft XACT Audio Engine"
    case physx = "NVIDIA PhysX System Software"
    case dotnet48 = "Microsoft .NET Framework 4.8"
}

public final class DependencyInjector {
    public static let shared = DependencyInjector()
    
    private init() {}
    
    public func resolveDependencies(for graphicsAPI: String, bottlePath: URL) throws -> [SystemDependency] {
        var needed: [SystemDependency] = [.vcrun2022, .d3dcompiler47]
        
        if graphicsAPI.contains("DirectX 9") || graphicsAPI.contains("D3D9") {
            needed.append(.xact)
        }
        
        let fileManager = FileManager.default
        let sys32 = bottlePath.appendingPathComponent("drive_c/windows/system32", isDirectory: true)
        try? fileManager.createDirectory(at: sys32, withIntermediateDirectories: true)
        
        // Inject required override flags in bottle registry
        let userReg = bottlePath.appendingPathComponent("user.reg")
        var regContent = (try? String(contentsOf: userReg)) ?? ""
        
        if !regContent.contains("[Software\\\\Wine\\\\DllOverrides]") {
            regContent += "\n[Software\\\\Wine\\\\DllOverrides]\n"
        }
        
        for dep in needed {
            switch dep {
            case .d3dcompiler47:
                regContent += "\"d3dcompiler_47\"=\"native,builtin\"\n"
            case .xact:
                regContent += "\"xaudio2_7\"=\"native,builtin\"\n"
            default:
                break
            }
        }
        
        try regContent.write(to: userReg, atomically: true, encoding: .utf8)
        return needed
    }
}
