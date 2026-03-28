import SwiftUI
import GoogleMaps

@main
struct DrawOnGMaps2App: App {

    init() {
        GMSServices.provideAPIKey("addyourapikeyhere")
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
