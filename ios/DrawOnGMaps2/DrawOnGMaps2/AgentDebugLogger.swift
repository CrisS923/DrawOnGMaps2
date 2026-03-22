import Foundation

enum AgentDebugLogger {
    private static let logPath = "/Users/cristianniculae/Projects/.cursor/debug-e55e2d.log"
    private static let sessionId = "e55e2d"
    private static let endpoint = URL(string: "http://127.0.0.1:7771/ingest/2d7bc145-02b3-4ed1-9469-a58896aec9b1")

    static func log(
        runId: String = "initial",
        hypothesisId: String,
        location: String,
        message: String,
        data: [String: Any] = [:]
    ) {
        var payload: [String: Any] = [
            "sessionId": sessionId,
            "runId": runId,
            "hypothesisId": hypothesisId,
            "location": location,
            "message": message,
            "data": data,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        payload["id"] = "log_\(payload["timestamp"] ?? 0)_\(UUID().uuidString)"

        guard
            JSONSerialization.isValidJSONObject(payload),
            let jsonData = try? JSONSerialization.data(withJSONObject: payload),
            var jsonLine = String(data: jsonData, encoding: .utf8)
        else { return }

        jsonLine.append("\n")
        guard let lineData = jsonLine.data(using: .utf8) else { return }

        // #region agent log
        NSLog("AGENT_DEBUG %@", jsonLine.trimmingCharacters(in: .newlines))
        // #endregion

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
        request.setValue(sessionId, forHTTPHeaderField: "X-Debug-Session-Id")
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { _, _, _ in
            // #region agent log
            // Intentionally ignore network errors for non-blocking debug instrumentation.
            // #endregion
        }.resume()
    }
}
