import Foundation

public struct InstalledGameEntry: Codable, Identifiable, Equatable {
    public var id: UUID
    public var gameName: String
    public var gameFolderPath: String
    public var mainExecutablePath: String
    public var detectedGraphicsAPI: String
    public var is64Bit: Bool
    public var engineType: GameEngineType
    public var bottleID: UUID?
    public var coverArtPath: String?
    public var totalLaunchCount: Int
    public var totalPlayTimeSeconds: Double
    public var addedDate: Date
    public var lastPlayedDate: Date?
    
    public init(
        gameName: String,
        gameFolderPath: String,
        mainExecutablePath: String,
        detectedGraphicsAPI: String,
        is64Bit: Bool,
        engineType: GameEngineType,
        bottleID: UUID? = nil,
        coverArtPath: String? = nil
    ) {
        self.id = UUID()
        self.gameName = gameName
        self.gameFolderPath = gameFolderPath
        self.mainExecutablePath = mainExecutablePath
        self.detectedGraphicsAPI = detectedGraphicsAPI
        self.is64Bit = is64Bit
        self.engineType = engineType
        self.bottleID = bottleID
        self.coverArtPath = coverArtPath
        self.totalLaunchCount = 0
        self.totalPlayTimeSeconds = 0
        self.addedDate = Date()
        self.lastPlayedDate = nil
    }
}

public final class GameLibraryStore {
    public static let shared = GameLibraryStore()
    
    private let fileManager = FileManager.default
    private let storePath: URL
    
    public private(set) var games: [InstalledGameEntry] = []
    
    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dataDir = appSupport.appendingPathComponent("ElysiumVanguard/Data", isDirectory: true)
        try? fileManager.createDirectory(at: dataDir, withIntermediateDirectories: true)
        self.storePath = dataDir.appendingPathComponent("game_library.json")
        loadFromDisk()
    }
    
    public func addGame(from folderURL: URL) throws -> InstalledGameEntry {
        guard let exeMeta = ExeScanner.shared.scanGameFolder(at: folderURL) else {
            throw LibraryError.noExecutableFound(folder: folderURL.path)
        }
        
        var isDir: ObjCBool = false
        let isFile = fileManager.fileExists(atPath: folderURL.path, isDirectory: &isDir) && !isDir.boolValue
        let rootFolderURL = isFile ? folderURL.deletingLastPathComponent() : folderURL
        
        var rawGameName = rootFolderURL.lastPathComponent
        let genericFolderNames = ["binaries", "bin", "win64", "win32", "x64", "x86", "release", "build"]
        if genericFolderNames.contains(rawGameName.lowercased()) {
            let parentName = rootFolderURL.deletingLastPathComponent().lastPathComponent
            if !parentName.isEmpty && parentName != "/" {
                rawGameName = parentName
            }
        }
        
        let gameName = rawGameName
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
        
        // Create micro-bottle
        let bottle = try BottleManager.shared.createMicroBottle(for: gameName, exeMetadata: exeMeta)
        
        // Inject dependencies
        _ = try DependencyInjector.shared.resolveDependencies(
            for: exeMeta.detectedGraphicsAPI,
            bottlePath: bottle.bottlePath
        )
        
        // Apply game-specific patches if available
        if let patch = GamePatchRegistry.shared.findPatch(for: exeMeta.fileName) {
            var updatedEnv = bottle.environmentVariables
            for (k, v) in patch.envOverrides { updatedEnv[k] = v }
        }
        
        // Prepare shader cache
        _ = ShaderCacheManager.shared.prepareShaderCache(for: gameName)
        
        // Detect game engine for tuning profile
        let engineProfile = GameEngineProfileDetector.shared.detectEngine(
            in: rootFolderURL,
            mainExeName: exeMeta.fileName
        )
        
        let entry = InstalledGameEntry(
            gameName: gameName,
            gameFolderPath: folderURL.path,
            mainExecutablePath: exeMeta.url.path,
            detectedGraphicsAPI: exeMeta.detectedGraphicsAPI,
            is64Bit: exeMeta.is64Bit,
            engineType: engineProfile.engineType,
            bottleID: bottle.bottleID
        )
        
        // Remove previous entry for same executable if present
        games.removeAll { $0.mainExecutablePath == entry.mainExecutablePath }
        games.append(entry)
        try saveToDisk()
        return entry
    }
    
    public func removeGame(id: UUID) throws {
        games.removeAll { $0.id == id }
        try saveToDisk()
    }
    
    public func recordSession(gameID: UUID, playTimeSeconds: Double) throws {
        guard let idx = games.firstIndex(where: { $0.id == gameID }) else { return }
        games[idx].totalLaunchCount += 1
        games[idx].totalPlayTimeSeconds += playTimeSeconds
        games[idx].lastPlayedDate = Date()
        try saveToDisk()
    }
    
    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: storePath) else { return }
        games = (try? JSONDecoder().decode([InstalledGameEntry].self, from: data)) ?? []
    }
    
    private func saveToDisk() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(games)
        try data.write(to: storePath, options: .atomic)
    }
    
    public enum LibraryError: Error, LocalizedError {
        case noExecutableFound(folder: String)
        
        public var errorDescription: String? {
            switch self {
            case .noExecutableFound(let folder):
                return "No valid Windows executable (.exe) found in: \(folder)"
            }
        }
    }
}
