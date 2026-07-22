import Foundation
import Metal

public enum CPUArchitecture: String, Codable {
    case appleSilicon = "Apple Silicon (ARM64)"
    case intelx86 = "Intel Core / Xeon (x86_64)"
}

public enum TranslationPipeline: String, Codable {
    case d3dMetalGPTK = "D3DMetal (Apple Game Porting Toolkit 2.x)"
    case dxvkMoltenVK = "DXVK 2.4 + VKD3D-Proton + MoltenVK (Native x86 Pipeline)"
}

public struct SystemHardwareProfile: Codable {
    public let cpuArch: CPUArchitecture
    public let gpuName: String
    public let isMetal3Supported: Bool
    public let recommendedPipeline: TranslationPipeline
}

public final class HardwareProbe {
    public static let shared = HardwareProbe()
    
    private init() {}
    
    public func detectProfile() -> SystemHardwareProfile {
        #if arch(arm64)
        let cpuArch = CPUArchitecture.appleSilicon
        #else
        let cpuArch = CPUArchitecture.intelx86
        #endif
        
        let gpuDevice = MTLCreateSystemDefaultDevice()
        let gpuName = gpuDevice?.name ?? "Generic GPU"
        
        let isMetal3Supported: Bool
        if #available(macOS 13.0, *) {
            isMetal3Supported = gpuDevice?.supportsFamily(.metal3) ?? false
        } else {
            isMetal3Supported = false
        }
        
        let pipeline: TranslationPipeline
        switch cpuArch {
        case .appleSilicon:
            pipeline = .d3dMetalGPTK
        case .intelx86:
            // Intel Mac strategy: DXVK + MoltenVK native x86 without Rosetta translation layer
            pipeline = .dxvkMoltenVK
        }
        
        return SystemHardwareProfile(
            cpuArch: cpuArch,
            gpuName: gpuName,
            isMetal3Supported: isMetal3Supported,
            recommendedPipeline: pipeline
        )
    }
}
