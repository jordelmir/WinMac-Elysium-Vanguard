import Foundation
import os

public enum LogLevel: String, Codable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
}

public struct DiagnosticEvent: Codable {
    public let timestamp: Date
    public let level: LogLevel
    public let subsystem: String
    public let message: String
    public let details: [String: String]?
}

public final class ElysiumLogger {
    public static let shared = ElysiumLogger()
    
    private let fileManager = FileManager.default
    private let logDirectory: URL
    public let logFileURL: URL
    public let telemetryFileURL: URL
    private let osLogger = Logger(subsystem: "com.elysium.vanguard", category: "Diagnostics")
    
    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.logDirectory = appSupport.appendingPathComponent("ElysiumVanguard/Logs", isDirectory: true)
        try? fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        self.logFileURL = logDirectory.appendingPathComponent("elysium_diagnostics.log")
        self.telemetryFileURL = logDirectory.appendingPathComponent("telemetry.json")
    }
    
    public func log(_ level: LogLevel, subsystem: String, message: String, details: [String: String]? = nil) {
        let event = DiagnosticEvent(
            timestamp: Date(),
            level: level,
            subsystem: subsystem,
            message: message,
            details: details
        )
        
        switch level {
        case .debug: osLogger.debug("[\(subsystem)] \(message)")
        case .info: osLogger.info("[\(subsystem)] \(message)")
        case .warning: osLogger.warning("[\(subsystem)] \(message)")
        case .error: osLogger.error("[\(subsystem)] \(message)")
        }
        
        let dateFormatter = ISO8601DateFormatter()
        var logLine = "[\(dateFormatter.string(from: event.timestamp))] [\(level.rawValue)] [\(subsystem)] \(message)"
        if let details = details, !details.isEmpty {
            logLine += " | Details: \(details)"
        }
        logLine += "\n"
        
        if let data = logLine.data(using: .utf8) {
            if fileManager.fileExists(atPath: logFileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    try? fileHandle.close()
                }
            } else {
                try? data.write(to: logFileURL, options: .atomic)
            }
        }
        
        appendTelemetry(event)
    }
    
    private func appendTelemetry(_ event: DiagnosticEvent) {
        var events: [DiagnosticEvent] = []
        if let data = try? Data(contentsOf: telemetryFileURL),
           let existing = try? JSONDecoder().decode([DiagnosticEvent].self, from: data) {
            events = existing
        }
        events.append(event)
        if events.count > 500 {
            events = Array(events.suffix(500))
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(events) {
            try? data.write(to: telemetryFileURL, options: .atomic)
        }
    }
    
    public func readLogFile() -> String {
        return (try? String(contentsOf: logFileURL, encoding: .utf8)) ?? "No log file found."
    }
    
    public func readTelemetryEvents() -> [DiagnosticEvent] {
        guard let data = try? Data(contentsOf: telemetryFileURL),
              let events = try? JSONDecoder().decode([DiagnosticEvent].self, from: data) else {
            return []
        }
        return events
    }
}
