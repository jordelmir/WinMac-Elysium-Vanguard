import Foundation

public final class WineDownloader {
    public static let shared = WineDownloader()
    
    private let fileManager = FileManager.default
    public let elysiumWineDir: URL
    
    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.elysiumWineDir = appSupport.appendingPathComponent("ElysiumVanguard/Wine", isDirectory: true)
        try? fileManager.createDirectory(at: elysiumWineDir, withIntermediateDirectories: true)
    }
    
    public var isWineInstalled: Bool {
        let binaryPath = elysiumWineDir.appendingPathComponent("bin/wine64")
        return fileManager.fileExists(atPath: binaryPath.path)
    }
    
    public func downloadAndInstallWine(progressHandler: @escaping (Double, String) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        let tarURLString = "https://github.com/Whisky-App/WhiskyWine/releases/download/v2.0.0/WhiskyWine-2.0.0.tar.gz"
        guard let url = URL(string: tarURLString) else { return }
        
        let logger = ElysiumLogger.shared
        logger.log(.info, subsystem: "WineDownloader", message: "Starting automated Wine runtime download from \(tarURLString)")
        
        let destinationTar = elysiumWineDir.appendingPathComponent("wine_runtime.tar.gz")
        
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            guard let self = self else { return }
            
            if let error = error {
                logger.log(.error, subsystem: "WineDownloader", message: "Wine download failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let tempURL = tempURL else { return }
            
            do {
                try? self.fileManager.removeItem(at: destinationTar)
                try self.fileManager.moveItem(at: tempURL, to: destinationTar)
                
                logger.log(.info, subsystem: "WineDownloader", message: "Wine tarball downloaded. Extracting to \(self.elysiumWineDir.path)")
                progressHandler(0.8, "Extracting Wine Runtime...")
                
                // Extract tarball
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
                process.arguments = ["-xzf", destinationTar.path, "-C", self.elysiumWineDir.path]
                try process.run()
                process.waitUntilExit()
                
                let binaryPath = self.elysiumWineDir.appendingPathComponent("bin/wine64")
                if self.fileManager.fileExists(atPath: binaryPath.path) {
                    logger.log(.info, subsystem: "WineDownloader", message: "Wine runtime installed successfully at \(binaryPath.path)")
                    completion(.success(binaryPath))
                } else {
                    let err = NSError(domain: "ElysiumWine", code: 404, userInfo: [NSLocalizedDescriptionKey: "Extraction completed but wine64 binary not found"])
                    completion(.failure(err))
                }
            } catch {
                logger.log(.error, subsystem: "WineDownloader", message: "Extraction error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
