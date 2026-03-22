import SwiftUI
import Foundation
import GoogleMaps

private enum ApiKeyProvider {
    static var googleMaps: String {
        if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String, key.isEmpty == false {
            return key
        }

        if let key = ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"], key.isEmpty == false {
            return key
        }

        fatalError("Google Maps API key not set. Provide GMSApiKey in Info.plist or GOOGLE_MAPS_API_KEY at build time.")
    }
}

@main
struct DrawOnGMaps2App: App {

    init() {
        GMSServices.provideAPIKey(ApiKeyProvider.googleMaps)
        // #region agent log
        AgentDebugLogger.log(
            runId: "initial",
            hypothesisId: "H6",
            location: "DrawOnGMaps2App.swift:init",
            message: "App init executed",
            data: [:]
        )
        // #endregion
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
