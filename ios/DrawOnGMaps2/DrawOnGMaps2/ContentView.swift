/**
 ContentView.swift
 
 The main screen of the app that toggles between Google Maps and Street View.
 Responsibilities:
 - Hosts MapContainerView and StreetViewContainer full-screen.
 - Presents drawing overlays for map and street view.
 - Shows map controls, street view controls, and a draggable Pegman overlay.
 - Handles user actions like locating the user and entering Street View.
 */

import SwiftUI
import CoreLocation
import GoogleMaps
import Combine

// MARK: - State
struct ContentView: View {
    /// Current map camera center coordinate.
    @State private var mapCenter = CLLocationCoordinate2D(latitude: 52.2450, longitude: -0.9229)
    /// Current map zoom level.
    @State private var mapZoom: Float = 16

    /// True when Street View is shown full-screen.
    @State private var isInStreetView = false
    /// Target coordinate for Street View.
    @State private var streetViewCoordinate = CLLocationCoordinate2D(latitude: 52.2450, longitude: -0.9229)

    /// Bridge exposing the underlying GMSMapView.
    @StateObject private var bridge = MapBridge()
    /// Bridge exposing the underlying GMSPanoramaView.
    @StateObject private var streetBridge = StreetViewBridge()
    /// Observable location manager helper.
    @StateObject private var locationManager = LocationManager()
    
    /// Prevents spamming the Locate Me action.
    @State private var isLocateMeCoolingDown = false
    
    /// Drawing state for the map overlay.
    @State private var isDrawingOnMap = false
    /// Completed user-drawn paths on the map.
    @State private var mapPaths: [Path] = []
    /// Drawing state for the Street View overlay.
    @State private var isDrawingOnStreet = false
    /// Completed user-drawn paths on Street View.
    @State private var streetPaths: [Path] = []
    /// If true, drawings remain visible while moving.
    @State private var drawingsLocked = true
    /// Controls visibility of the draggable Pegman overlay.
    @State private var showPegman = false
    /// Current drag offset for Pegman (relative to bottomTrailing alignment).
    @State private var pegmanOffset: CGSize = .zero
    @State private var awaitingLocateMe = false

    /// Main screen content that switches between Map and Street View.
    var body: some View {
        ZStack {
            if isInStreetView {
                // Full-screen Street View
                StreetViewContainer(coordinate: streetViewCoordinate, bridge: streetBridge)
                    .ignoresSafeArea()
                
                if drawingsLocked || isDrawingOnStreet {
                    DrawingOverlayView(isDrawing: $isDrawingOnStreet, paths: $streetPaths)
                        .ignoresSafeArea()
                }

                // Overlay controls for Street View
                // NOTE: Switch to a simpler background if performance is an issue on older devices
                StreetViewControlsView(
                    isDrawingOnStreet: $isDrawingOnStreet,
                    drawingsLocked: $drawingsLocked,
                    onBackToMap: { isInStreetView = false },
                    onClearStreetDrawings: { streetPaths.removeAll() }
                )
            } else {
                // Full-screen Map
                MapContainerView(centerCoordinate: $mapCenter,
                                 currentZoom: $mapZoom,
                                 bridge: bridge)
                    .ignoresSafeArea()
                
                if drawingsLocked || isDrawingOnMap {
                    DrawingOverlayView(isDrawing: $isDrawingOnMap, paths: $mapPaths)
                        .ignoresSafeArea()
                }

                // Overlay controls for Map
                // NOTE: Switch to a simpler background if performance is an issue on older devices
                MapControlsView(
                    isLocateMeCoolingDown: $isLocateMeCoolingDown,
                    isDrawingOnMap: $isDrawingOnMap,
                    drawingsLocked: $drawingsLocked,
                    onLocateMe: { goToUserLocation() },
                    onClearMapDrawings: { mapPaths.removeAll() },
                    onTogglePegman: { withAnimation { showPegman.toggle() } }
                )
                
                if showPegman {
                    PegmanView(offset: $pegmanOffset, onDrop: { globalPoint in
                        guard let mapView = bridge.mapView else { return }
                        let dropPointInMap = mapView.convert(globalPoint, from: nil)
                        let coord = mapView.projection.coordinate(for: dropPointInMap)
                        streetViewCoordinate = coord
                        isInStreetView = true
                        showPegman = false
                    }, onCancel: {
                        showPegman = false
                    })
                }
            }
        }
        .onAppear {
            locationManager.requestAuthorization()
            locationManager.startUpdating()
            // #region agent log
            AgentDebugLogger.log(
                runId: "initial",
                hypothesisId: "H1",
                location: "ContentView.swift:onAppear",
                message: "ContentView appeared and requested location setup",
                data: [
                    "authorizationStatus": locationManager.authorizationStatus.rawValue,
                    "hasLastLocation": locationManager.lastLocation != nil
                ]
            )
            // #endregion
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UserLocationUpdated"))) { _ in
            // #region agent log
            AgentDebugLogger.log(
                runId: "initial",
                hypothesisId: "H2",
                location: "ContentView.swift:onReceiveUserLocationUpdated",
                message: "Received UserLocationUpdated notification",
                data: [
                    "awaitingLocateMe": awaitingLocateMe,
                    "hasLastLocation": locationManager.lastLocation != nil,
                    "hasMapView": bridge.mapView != nil
                ]
            )
            // #endregion
            guard awaitingLocateMe, let loc = locationManager.lastLocation else { return }
            let coord = loc.coordinate
            mapCenter = coord
            mapZoom = max(mapZoom, 16)
            if let mapView = bridge.mapView {
                let camera = GMSCameraPosition.camera(withTarget: coord, zoom: mapZoom)
                mapView.animate(to: camera)
            }
            locationManager.stopUpdating()
            awaitingLocateMe = false
        }
    }

    /// Animates the map to the user's current location with a small cooldown and stops updates afterwards.
    private func goToUserLocation() {
        guard !isLocateMeCoolingDown else { return }
        isLocateMeCoolingDown = true
        // #region agent log
        AgentDebugLogger.log(
            runId: "initial",
            hypothesisId: "H1",
            location: "ContentView.swift:goToUserLocation:entry",
            message: "Locate Me tapped",
            data: [
                "authorizationStatus": locationManager.authorizationStatus.rawValue,
                "hasLastLocation": locationManager.lastLocation != nil,
                "hasMapView": bridge.mapView != nil
            ]
        )
        // #endregion
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if let loc = locationManager.lastLocation {
                let coord = loc.coordinate
                mapCenter = coord
                mapZoom = max(mapZoom, 16) // ensure a reasonable zoom
                // Optionally animate mapView directly for smoother movement
                if let mapView = bridge.mapView {
                    let camera = GMSCameraPosition.camera(withTarget: coord, zoom: mapZoom)
                    mapView.animate(to: camera)
                }
                locationManager.stopUpdating()
                // #region agent log
                AgentDebugLogger.log(
                    runId: "initial",
                    hypothesisId: "H3",
                    location: "ContentView.swift:goToUserLocation:authorizedWithLocation",
                    message: "Locate Me moved camera using cached location",
                    data: [
                        "latitude": coord.latitude,
                        "longitude": coord.longitude,
                        "mapZoom": mapZoom
                    ]
                )
                // #endregion
            } else {
                // If we don't have a location yet, start updating and wait for the next fix
                awaitingLocateMe = true
                locationManager.startUpdating()
                // #region agent log
                AgentDebugLogger.log(
                    runId: "initial",
                    hypothesisId: "H2",
                    location: "ContentView.swift:goToUserLocation:awaitingNewLocation",
                    message: "Locate Me waiting for fresh location update",
                    data: [
                        "awaitingLocateMe": awaitingLocateMe
                    ]
                )
                // #endregion
            }
        case .notDetermined:
            awaitingLocateMe = true
            locationManager.requestAuthorization()
        case .denied, .restricted:
            // Optionally present guidance to enable location in Settings
            print("Location permission denied or restricted")
        @unknown default:
            break
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLocateMeCoolingDown = false
        }
    }
}

