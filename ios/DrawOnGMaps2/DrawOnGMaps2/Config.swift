import Foundation

struct Config {
    static let googleMapsAPIKey: String = {
        // Read from environment variable or use placeholder
        return ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"] ?? "ADD_YOUR_API_KEY_HERE"
    }()
}