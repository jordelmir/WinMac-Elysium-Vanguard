import Foundation

public struct BottleConfiguration: Codable {
    public let bottleID: UUID
    public let name: String
    public let bottlePath: URL
    public let targetPipeline: TranslationPipeline
    public let environmentVariables: [String: String]
    public let createdDate: Date
    
    public init(
        bottleID: UUID,
        name: String,
        bottlePath: URL,
        targetPipeline: TranslationPipeline,
        environmentVariables: [String: String],
        createdDate: Date
    ) {
        self.bottleID = bottleID
        self.name = name
        self.bottlePath = bottlePath
        self.targetPipeline = targetPipeline
        self.environmentVariables = environmentVariables
        self.createdDate = createdDate
    }
}

public final class BottleManager {
    public static let shared = BottleManager()
    
    private let fileManager = FileManager.default
    private let baseBottlesDirectory: URL
    
    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.baseBottlesDirectory = appSupport.appendingPathComponent("ElysiumVanguard/Bottles", isDirectory: true)
        try? fileManager.createDirectory(at: baseBottlesDirectory, withIntermediateDirectories: true)
    }
    
    public func createMicroBottle(for gameName: String, exeMetadata: ExecutableMetadata) throws -> BottleConfiguration {
        let bottleID = UUID()
        let sanitizedName = gameName.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "_")
        let bottleFolder = baseBottlesDirectory.appendingPathComponent("\(sanitizedName)_\(bottleID.uuidString.prefix(8))", isDirectory: true)
        
        try fileManager.createDirectory(at: bottleFolder, withIntermediateDirectories: true)
        
        let profile = HardwareProbe.shared.detectProfile()
        var env: [String: String] = [
            "WINEPREFIX": bottleFolder.path,
            "WINEDEBUG": "-all",
            "WINEESYNC": "1",
            "WINEMSYNC": "1"
        ]
        
        switch profile.recommendedPipeline {
        case .d3dMetalGPTK:
            env["DXVK_ASYNC"] = "1"
            env["MTL_HUD_ENABLED"] = "1"
            env["D3DMETAL_LOG_LEVEL"] = "1"
        case .dxvkMoltenVK:
            env["DXVK_ASYNC"] = "1"
            env["MVK_CONFIG_LOG_LEVEL"] = "1"
            env["VK_ICD_FILENAMES"] = "/usr/local/share/vulkan/icd.d/MoltenVK_icd.json"
        }
        
        let config = BottleConfiguration(
            bottleID: bottleID,
            name: gameName,
            bottlePath: bottleFolder,
            targetPipeline: profile.recommendedPipeline,
            environmentVariables: env,
            createdDate: Date()
        )
        
        try saveConfiguration(config, inside: bottleFolder)
        return config
    }
    
    private func saveConfiguration(_ config: BottleConfiguration, inside folder: URL) throws {
        let configURL = folder.appendingPathComponent("elysium_config.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(config)
        try data.write(to: configURL)
    }
}
