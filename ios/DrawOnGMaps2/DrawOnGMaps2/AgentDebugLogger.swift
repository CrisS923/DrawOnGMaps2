import Foundation

#if DEBUG
enum AgentDebugLogger {
    private enum Env {
        static let logPath = "AGENT_DEBUG_LOG_PATH"
        static let endpoint = "AGENT_DEBUG_ENDPOINT"
        static let sessionId = "AGENT_DEBUG_SESSION_ID"
    }

    private static var logPath: String {
        if let configured = ProcessInfo.processInfo.environment[Env.logPath], !configured.isEmpty {
            return configured
        }
        let base = FileManager.default.temporaryDirectory
        return base.appendingPathComponent("agent-debug.log").path
    }

    private static var endpoint: URL? {
        guard
            let raw = ProcessInfo.processInfo.environment[Env.endpoint],
            !raw.isEmpty
        else { return nil }
        return URL(string: raw)
    }

    private static var sessionId: String? {
        guard
            let raw = ProcessInfo.processInfo.environment[Env.sessionId],
            !raw.isEmpty
        else { return nil }
        return raw
    }

    static func log(
        runId: String = "initial",
        hypothesisId: String,
        location: String,
        message: String,
        data: [String: Any] = [:]
    ) {
        var payload: [String: Any] = [
            "runId": runId,
            "hypothesisId": hypothesisId,
            "location": location,
            "message": message,
            "data": data,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        if let sessionId {
            payload["sessionId"] = sessionId
        }
        payload["id"] = "log_\(payload["timestamp"] ?? 0)_\(UUID().uuidString)"

        guard
            JSONSerialization.isValidJSONObject(payload),
            let jsonData = try? JSONSerialization.data(withJSONObject: payload),
            var jsonLine = String(data: jsonData, encoding: .utf8)
        else { return }

        jsonLine.append("\n")
        guard let lineData = jsonLine.data(using: .utf8) else { return }

        NSLog("AGENT_DEBUG %@", jsonLine.trimmingCharacters(in: .newlines))

        let fileURL = URL(fileURLWithPath: logPath)
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: logPath) {
            try? lineData.write(to: fileURL)
        } else if let fileHandle = FileHandle(forWritingAtPath: logPath) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(lineData)
            try? fileHandle.close()
        }

        sendToEndpoint(payload: payload)
    }

    private static func sendToEndpoint(payload: [String: Any]) {
        guard
            let endpoint,
            JSONSerialization.isValidJSONObject(payload),
            let body = try? JSONSerialization.data(withJSONObject: payload)
        else { return }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let sessionId {
            request.setValue(sessionId, forHTTPHeaderField: "X-Debug-Session-Id")
        }
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }
}
#else
enum AgentDebugLogger {
    static func log(
        runId: String = "initial",
        hypothesisId: String,
        location: String,
        message: String,
        data: [String: Any] = [:]
    ) {
        _ = runId
        _ = hypothesisId
        _ = location
        _ = message
        _ = data
    }
}
#endif
