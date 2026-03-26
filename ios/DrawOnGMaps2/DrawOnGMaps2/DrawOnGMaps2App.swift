import SwiftUI
import Foundation
import GoogleMaps

private enum ApiKeyProvider {
    /// Compile-time fallback so release builds still have a key even if Info.plist substitution failed.
    /// NOTE: Keep in sync with Config/Secrets.xcconfig.
    private static let bundledDefaultKey = "REDACTED_API_KEY"

    /// Returns the configured Google Maps key, or nil if none is set.
    static func googleMaps() -> String? {
        // Prefer the key baked into the app's Info.plist (set via Secrets.xcconfig).
        if let key = sanitize(Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String) {
            return key
        }

        // In DEBUG only, fall back to an env var injected by Xcode when running tethered.
        #if DEBUG
        if let key = sanitize(ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"]) {
            return key
        }
        #endif

        // Final fallback for standalone installs.
        return sanitize(bundledDefaultKey)
    }

    /// Treat placeholders or empty strings as missing so release builds can't silently ship without a real key.
    private static func sanitize(_ raw: String?) -> String? {
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines), trimmed.isEmpty == false else {
            return nil
        }
        // Reject common placeholder values that sneak into Info.plist when the build setting isn't provided.
        if trimmed.contains("$(") || trimmed.caseInsensitiveCompare("REPLACE_ME") == .orderedSame {
            return nil
        }
        return trimmed
    }
}

@main
struct DrawOnGMaps2App: App {
    @State private var showMissingKeyAlert: Bool
    private let missingApiKeyMessage: String?

    init() {
        let key = ApiKeyProvider.googleMaps()

        if let key, !key.isEmpty {
            let provided = GMSServices.provideAPIKey(key)
            missingApiKeyMessage = provided ? nil : "Google Maps key was present but rejected. Double-check the value and any key restrictions."
        } else {
            missingApiKeyMessage = "Google Maps API key not set. Add it to Config/Secrets.xcconfig or the scheme environment, then rebuild and reinstall."
        }

        _showMissingKeyAlert = State(initialValue: missingApiKeyMessage != nil)

        // #region agent log
        AgentDebugLogger.log(
            runId: "initial",
            hypothesisId: "H6",
            location: "DrawOnGMaps2App.swift:init",
            message: missingApiKeyMessage == nil ? "App init executed" : "App init missing API key",
            data: ["missingApiKey": missingApiKeyMessage ?? "none"]
        )
        // #endregion
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .alert("Google Maps API Key Missing", isPresented: $showMissingKeyAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(missingApiKeyMessage ?? "")
                }
        }
    }
}
