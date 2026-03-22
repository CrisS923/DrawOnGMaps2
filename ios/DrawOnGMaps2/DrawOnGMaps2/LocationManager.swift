/**
 LocationManager.swift
 
 Observable helper around CLLocationManager.
 Responsibilities:
 - Requests authorization and manages location updates.
 - Publishes authorization status and last known location.
 - Posts a notification when a new location arrives.
 */

import Foundation
import CoreLocation
import Combine

// MARK: - Location Manager Helper
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?

    private let manager = CLLocationManager()

    // MARK: - Lifecycle
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Public API
    func requestAuthorization() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdating()
        default:
            break
        }
    }

    func startUpdating() {
        manager.startUpdatingLocation()
        // #region agent log
        AgentDebugLogger.log(
            runId: "initial",
            hypothesisId: "H1",
            location: "LocationManager.swift:startUpdating",
            message: "Requested CLLocation updates",
            data: [
                "authorizationStatus": manager.authorizationStatus.rawValue
            ]
        )
        // #endregion
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        // #region agent log
        AgentDebugLogger.log(
            runId: "initial",
            hypothesisId: "H1",
            location: "LocationManager.swift:locationManagerDidChangeAuthorization",
            message: "Authorization status changed",
            data: [
                "authorizationStatus": manager.authorizationStatus.rawValue
            ]
        )
        // #endregion
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdating()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        lastLocation = loc
        // #region agent log
        AgentDebugLogger.log(
            runId: "initial",
            hypothesisId: "H2",
            location: "LocationManager.swift:didUpdateLocations",
            message: "Received location update",
            data: [
                "count": locations.count,
                "latitude": loc.coordinate.latitude,
                "longitude": loc.coordinate.longitude
            ]
        )
        // #endregion
        NotificationCenter.default.post(name: Notification.Name("UserLocationUpdated"), object: nil)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        // #region agent log
        AgentDebugLogger.log(
            runId: "initial",
            hypothesisId: "H5",
            location: "LocationManager.swift:didFailWithError",
            message: "CLLocationManager failed with error",
            data: [
                "error": error.localizedDescription
            ]
        )
        // #endregion
    }
}
