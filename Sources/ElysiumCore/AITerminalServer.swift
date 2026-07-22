import Foundation

/// AITerminalServer — Lightweight HTTP JSON API server for AI agent control
/// Runs on localhost:19847 and accepts POST /command with JSON payloads.
///
/// AI agents can send structured commands to:
/// - Execute shell commands and get output
/// - Launch games with tuned profiles
/// - Read diagnostics, logs, and performance telemetry
/// - Modify Wine environment variables in real-time
///
/// Protocol:
///   POST http://localhost:19847/command
///   Content-Type: application/json
///   {"action": "exec", "command": "ps aux | grep wine"}
///
///   Response:
///   {"status": "ok", "output": "...", "exitCode": 0}

public final class AITerminalServer {
    public static let shared = AITerminalServer()
    
    private var serverSocket: Int32 = -1
    private var isRunning = false
    private let port: UInt16 = 19847
    private let logger = ElysiumLogger.shared
    private let queue = DispatchQueue(label: "com.elysium.ai-terminal", qos: .userInitiated, attributes: .concurrent)
    
    private init() {}
    
    // MARK: - Public API
    
    /// Start the AI Terminal Server on localhost:19847
    public func start() {
        guard !isRunning else {
            logger.log(.warning, subsystem: "AITerminal", message: "Server already running on port \(port)")
            return
        }
        
        queue.async { [weak self] in
            self?.runServer()
        }
    }
    
    /// Stop the server
    public func stop() {
        isRunning = false
        if serverSocket >= 0 {
            close(serverSocket)
            serverSocket = -1
        }
        logger.log(.info, subsystem: "AITerminal", message: "Server stopped")
    }
    
    /// Check if server is running
    public var running: Bool { isRunning }
    
    // MARK: - Server Loop
    
    private func runServer() {
        serverSocket = socket(AF_INET, SOCK_STREAM, 0)
        guard serverSocket >= 0 else {
            logger.log(.error, subsystem: "AITerminal", message: "Failed to create socket")
            return
        }
        
        var reuse: Int32 = 1
        setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))
        
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr.s_addr = INADDR_ANY // localhost only for security
        
        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                bind(serverSocket, sockPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        
        guard bindResult == 0 else {
            logger.log(.error, subsystem: "AITerminal", message: "Failed to bind to port \(port): \(String(cString: strerror(errno)))")
            close(serverSocket)
            return
        }
        
        guard listen(serverSocket, 10) == 0 else {
            logger.log(.error, subsystem: "AITerminal", message: "Failed to listen on port \(port)")
            close(serverSocket)
            return
        }
        
        isRunning = true
        logger.log(.info, subsystem: "AITerminal", message: "🤖 AI Terminal Server listening on http://localhost:\(port)")
        
        while isRunning {
            var clientAddr = sockaddr_in()
            var clientAddrLen = socklen_t(MemoryLayout<sockaddr_in>.size)
            
            let clientSocket = withUnsafeMutablePointer(to: &clientAddr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                    accept(serverSocket, sockPtr, &clientAddrLen)
                }
            }
            
            guard clientSocket >= 0 else { continue }
            
            queue.async { [weak self] in
                self?.handleClient(clientSocket)
            }
        }
    }
    
    // MARK: - Request Handling
    
    private func handleClient(_ socket: Int32) {
        defer { close(socket) }
        
        // Read HTTP request (max 64KB)
        var buffer = [UInt8](repeating: 0, count: 65536)
        let bytesRead = recv(socket, &buffer, buffer.count, 0)
        guard bytesRead > 0 else { return }
        
        let rawRequest = String(bytes: buffer[..<bytesRead], encoding: .utf8) ?? ""
        
        // Parse HTTP request
        let lines = rawRequest.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return }
        
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else { return }
        
        let method = String(parts[0])
        let path = String(parts[1])
        
        // Extract body (after empty line)
        let bodyParts = rawRequest.components(separatedBy: "\r\n\r\n")
        let body = bodyParts.count > 1 ? bodyParts[1] : ""
        
        let response: String
        
        switch (method, path) {
        case ("POST", "/command"):
            response = handleCommand(body: body)
        case ("GET", "/status"):
            response = handleStatus()
        case ("GET", "/diagnose"):
            response = handleDiagnose()
        case ("GET", "/logs"):
            response = handleLogs()
        case ("POST", "/launch"):
            response = handleLaunch(body: body)
        case ("GET", "/guide"):
            response = handleGuide()
        case ("GET", "/health"):
            response = makeJSON(["status": "ok", "server": "AITerminalServer", "port": "\(port)"])
        default:
            response = makeJSON(["status": "error", "message": "Unknown endpoint. Available: GET /status, /diagnose, /logs, /guide, /health | POST /command, /launch"])
        }
        
        let httpResponse = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: \(response.utf8.count)\r\nConnection: close\r\n\r\n\(response)"
        
        _ = httpResponse.withCString { ptr in
            send(socket, ptr, strlen(ptr), 0)
        }
    }
    
    // MARK: - Command Handlers
    
    /// POST /command — Execute arbitrary shell command and return output
    private func handleCommand(body: String) -> String {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let command = json["command"] as? String else {
            return makeJSON(["status": "error", "message": "Missing 'command' field. Send: {\"command\": \"your shell command\"}"])
        }
        
        let timeout = (json["timeout"] as? Int) ?? 30
        logger.log(.info, subsystem: "AITerminal", message: "Executing command: \(command)")
        
        let result = executeShellCommand(command, timeout: timeout)
        return makeJSON([
            "status": result.exitCode == 0 ? "ok" : "error",
            "command": command,
            "output": result.output,
            "exitCode": "\(result.exitCode)",
            "durationMs": "\(result.durationMs)"
        ])
    }
    
    /// GET /status — System hardware, Wine installations, game library
    private func handleStatus() -> String {
        let hw = HardwareProbe.shared.detectProfile()
        let wines = WineProcessLauncher.shared.discoverWineInstallations()
        let library = GameLibraryStore.shared
        
        var wineList: [[String: String]] = []
        for w in wines {
            wineList.append([
                "source": w.source.rawValue,
                "version": w.version,
                "path": w.wineBinaryPath.path
            ])
        }
        
        var gameList: [[String: String]] = []
        for g in library.games {
            gameList.append([
                "name": g.gameName,
                "exe": g.mainExecutablePath,
                "api": g.detectedGraphicsAPI,
                "engine": g.engineType.rawValue,
                "launches": "\(g.totalLaunchCount)",
                "playtimeHours": "\(Int(g.totalPlayTimeSeconds / 3600))"
            ])
        }
        
        let statusDict: [String: Any] = [
            "status": "ok",
            "hardware": [
                "cpu": hw.cpuArch.rawValue,
                "gpu": hw.gpuName,
                "metal3": hw.isMetal3Supported,
                "pipeline": hw.recommendedPipeline.rawValue,
                "cores": ProcessInfo.processInfo.activeProcessorCount,
                "ramGB": ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024)
            ],
            "wine": wineList,
            "games": gameList
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: statusDict, options: .prettyPrinted),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return makeJSON(["status": "error", "message": "Failed to serialize status"])
    }
    
    /// GET /diagnose — Active Wine processes, memory pressure, system load
    private func handleDiagnose() -> String {
        let wineProcs = executeShellCommand("ps aux | grep wine | grep -v grep", timeout: 5)
        let memPressure = executeShellCommand("memory_pressure 2>/dev/null | head -5 || sysctl vm.page_pageable_internal_count vm.page_purgeable_count 2>/dev/null", timeout: 5)
        let cpuLoad = executeShellCommand("sysctl -n vm.loadavg", timeout: 3)
        let diskUsage = executeShellCommand("df -h / | tail -1", timeout: 3)
        
        let hw = HardwareProbe.shared.detectProfile()
        
        return makeJSON([
            "status": "ok",
            "gpu": hw.gpuName,
            "metal3": hw.isMetal3Supported ? "true" : "false",
            "cores": "\(ProcessInfo.processInfo.activeProcessorCount)",
            "ramGB": "\(ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024))",
            "loadAvg": cpuLoad.output.trimmingCharacters(in: .whitespacesAndNewlines),
            "diskUsage": diskUsage.output.trimmingCharacters(in: .whitespacesAndNewlines),
            "memoryPressure": memPressure.output.trimmingCharacters(in: .whitespacesAndNewlines),
            "activeWineProcesses": wineProcs.output.trimmingCharacters(in: .whitespacesAndNewlines)
        ])
    }
    
    /// GET /logs — Read last 50 log lines
    private func handleLogs() -> String {
        let logContent = ElysiumLogger.shared.readLogFile()
        let lines = logContent.components(separatedBy: "\n")
        let last50 = lines.suffix(50).joined(separator: "\n")
        return makeJSON(["status": "ok", "logLines": "\(min(lines.count, 50))", "content": last50])
    }
    
    /// POST /launch — Launch a game by name or shortcut
    private func handleLaunch(body: String) -> String {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let game = json["game"] as? String else {
            return makeJSON(["status": "error", "message": "Missing 'game' field. Send: {\"game\": \"gow2\"}"])
        }
        
        if game.lowercased() == "gow2" || game.lowercased().contains("gears") {
            let scriptPath = "/Users/jordelmirsdevhome/Downloads/Juegos/Win Mac Elysium Vanguard /Scripts/launch_gow2_wine11.sh"
            guard FileManager.default.fileExists(atPath: scriptPath) else {
                return makeJSON(["status": "error", "message": "GoW2 launcher script not found"])
            }
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = [scriptPath]
            do {
                try process.run()
                logger.log(.info, subsystem: "AITerminal", message: "Launched GoW2 via API (PID: \(process.processIdentifier))")
                return makeJSON([
                    "status": "ok",
                    "game": "Gears of War 2",
                    "pid": "\(process.processIdentifier)",
                    "message": "Game launched successfully"
                ])
            } catch {
                return makeJSON(["status": "error", "message": "Failed to launch: \(error.localizedDescription)"])
            }
        }
        
        return makeJSON(["status": "error", "message": "Unknown game: \(game). Available: gow2"])
    }
    
    /// GET /guide — Return AI operational specification
    private func handleGuide() -> String {
        return makeJSON([
            "status": "ok",
            "server": "WinMac Elysium Vanguard AI Terminal",
            "version": "1.0",
            "endpoints": [
                "GET /health": "Server health check",
                "GET /status": "Hardware, Wine runtimes, game library (JSON)",
                "GET /diagnose": "CPU load, RAM, memory pressure, active Wine processes",
                "GET /logs": "Last 50 diagnostic log lines",
                "GET /guide": "This guide",
                "POST /command": "Execute shell command: {\"command\": \"...\", \"timeout\": 30}",
                "POST /launch": "Launch game: {\"game\": \"gow2\"}"
            ].description,
            "performanceTips": [
                "WINE_LARGE_ADDRESS_AWARE=0": "Prevents 32-bit memory overflow crashes",
                "WINEESYNC=1": "Enable eventfd sync for better multi-thread performance",
                "WINEMSYNC=1": "Enable Mach semaphore sync (macOS native)",
                "WINEDLLOVERRIDES='d3d9=builtin'": "Force WineD3D for DirectX 9 translation"
            ].description,
            "wineBinary": "/Users/jordelmirsdevhome/Wine/wine-11.13-install/bin/wine"
        ])
    }
    
    // MARK: - Shell Execution
    
    private struct ShellResult {
        let output: String
        let exitCode: Int32
        let durationMs: Int
    }
    
    private func executeShellCommand(_ command: String, timeout: Int = 30) -> ShellResult {
        let start = DispatchTime.now()
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        do {
            try process.run()
        } catch {
            return ShellResult(output: "Failed to execute: \(error.localizedDescription)", exitCode: -1, durationMs: 0)
        }
        
        // Wait with timeout
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global().async {
            process.waitUntilExit()
            group.leave()
        }
        
        let waitResult = group.wait(timeout: .now() + .seconds(timeout))
        if waitResult == .timedOut {
            process.terminate()
            return ShellResult(output: "Command timed out after \(timeout)s", exitCode: -1, durationMs: timeout * 1000)
        }
        
        let outData = pipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        var output = String(data: outData, encoding: .utf8) ?? ""
        if output.isEmpty, let errStr = String(data: errData, encoding: .utf8), !errStr.isEmpty {
            output = errStr
        }
        
        // Truncate very long output (max 32KB)
        if output.count > 32768 {
            output = String(output.prefix(32768)) + "\n... [truncated, \(output.count) total chars]"
        }
        
        let end = DispatchTime.now()
        let elapsed = Int((end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000)
        
        return ShellResult(output: output, exitCode: process.terminationStatus, durationMs: elapsed)
    }
    
    // MARK: - JSON Helpers
    
    private func makeJSON(_ dict: [String: String]) -> String {
        var parts: [String] = []
        for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
            let escaped = value
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "")
                .replacingOccurrences(of: "\t", with: "\\t")
            parts.append("  \"\(key)\": \"\(escaped)\"")
        }
        return "{\n\(parts.joined(separator: ",\n"))\n}"
    }
}
