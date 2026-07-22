import Foundation

/// AIPerformanceMonitor — Real-time performance telemetry collector
/// Monitors CPU load, memory pressure, active Wine processes, and game responsiveness.
/// AI agents can poll /diagnose on AITerminalServer or call this directly.

public final class AIPerformanceMonitor {
    public static let shared = AIPerformanceMonitor()
    
    private let logger = ElysiumLogger.shared
    
    private init() {}
    
    // MARK: - Snapshot
    
    public struct PerformanceSnapshot: Codable {
        public let timestamp: String
        public let cpuCores: Int
        public let ramTotalGB: UInt64
        public let loadAverage: String
        public let memoryPressure: String
        public let gpuName: String
        public let metal3Supported: Bool
        public let activeWineProcessCount: Int
        public let wineProcesses: [WineProcessInfo]
        public let recommendations: [String]
    }
    
    public struct WineProcessInfo: Codable {
        public let pid: String
        public let cpuPercent: String
        public let memPercent: String
        public let command: String
    }
    
    // MARK: - Capture
    
    /// Take a full performance snapshot of the system
    public func captureSnapshot() -> PerformanceSnapshot {
        let hw = HardwareProbe.shared.detectProfile()
        let formatter = ISO8601DateFormatter()
        
        // Load average
        let loadAvg = runQuick("sysctl -n vm.loadavg").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Memory pressure
        let memPressure = runQuick("memory_pressure 2>/dev/null | grep 'System-wide' | head -1").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Wine processes
        let psOutput = runQuick("ps aux | grep -i wine | grep -v grep")
        var wineProcs: [WineProcessInfo] = []
        let lines = psOutput.components(separatedBy: "\n").filter { !$0.isEmpty }
        for line in lines {
            let cols = line.split(separator: " ", maxSplits: 10, omittingEmptySubsequences: true)
            if cols.count >= 11 {
                wineProcs.append(WineProcessInfo(
                    pid: String(cols[1]),
                    cpuPercent: String(cols[2]),
                    memPercent: String(cols[3]),
                    command: String(cols[10...].joined(separator: " ")).trimmingCharacters(in: .whitespacesAndNewlines)
                ))
            }
        }
        
        // Recommendations
        var recommendations: [String] = []
        
        if wineProcs.isEmpty {
            recommendations.append("No Wine processes running. Use 'elysium-cli gow2' or POST /launch to start a game.")
        }
        
        let highCPU = wineProcs.filter { (Double($0.cpuPercent) ?? 0) > 80 }
        if !highCPU.isEmpty {
            recommendations.append("HIGH CPU: \(highCPU.count) Wine process(es) above 80% CPU. Consider lowering resolution (-ResX=1024 -ResY=768) or enabling WINEESYNC=1.")
        }
        
        let highMem = wineProcs.filter { (Double($0.memPercent) ?? 0) > 5 }
        if !highMem.isEmpty {
            recommendations.append("HIGH MEMORY: Some Wine processes using significant RAM. Ensure WINE_LARGE_ADDRESS_AWARE=0 for 32-bit games.")
        }
        
        if memPressure.lowercased().contains("critical") || memPressure.lowercased().contains("warn") {
            recommendations.append("SYSTEM MEMORY PRESSURE DETECTED. Close unnecessary applications before launching games.")
        }
        
        if recommendations.isEmpty {
            recommendations.append("System looks healthy. Ready for game launch.")
        }
        
        return PerformanceSnapshot(
            timestamp: formatter.string(from: Date()),
            cpuCores: ProcessInfo.processInfo.activeProcessorCount,
            ramTotalGB: ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024),
            loadAverage: loadAvg,
            memoryPressure: memPressure.isEmpty ? "Unable to read (normal on some macOS versions)" : memPressure,
            gpuName: hw.gpuName,
            metal3Supported: hw.isMetal3Supported,
            activeWineProcessCount: wineProcs.count,
            wineProcesses: wineProcs,
            recommendations: recommendations
        )
    }
    
    /// Quick benchmark: measure Wine startup latency
    public func measureWineStartupLatency() -> String {
        let wineBin = "/Users/jordelmirsdevhome/Wine/wine-11.13-install/bin/wine"
        guard FileManager.default.fileExists(atPath: wineBin) else {
            return "Wine binary not found at \(wineBin)"
        }
        
        let start = DispatchTime.now()
        let result = runQuick("\(wineBin) --version 2>&1")
        let end = DispatchTime.now()
        let elapsed = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
        
        return "Wine startup latency: \(String(format: "%.1f", elapsed))ms | Version: \(result.trimmingCharacters(in: .whitespacesAndNewlines))"
    }
    
    // MARK: - Private
    
    private func runQuick(_ cmd: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", cmd]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
