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
import MapKit
import GoogleMaps
import Combine

// MARK: - Address Search Helper
final class AddressSearchModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var completions: [MKLocalSearchCompletion] = []
    private let completer: MKLocalSearchCompleter = {
        let c = MKLocalSearchCompleter()
        c.resultTypes = [.address]
        return c
    }()
    
    override init() {
        super.init()
        completer.delegate = self
    }
    
    func update(query: String) {
        completer.queryFragment = query
    }
    
    // MARK: - MKLocalSearchCompleterDelegate
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async { [weak self] in
            self?.completions = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error.localizedDescription)")
    }
}

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
    @State private var mapPaths: [ColoredPath] = []
    /// Drawing state for the Street View overlay.
    @State private var isDrawingOnStreet = false
    /// Completed user-drawn paths on Street View.
    @State private var streetPaths: [ColoredPath] = []
    @State private var drawColor: Color = .yellow
    /// If true, drawings remain visible while moving.
    @State private var drawingsLocked = true
    /// Controls visibility of the draggable Pegman overlay.
    @State private var showPegman = false
    /// Current drag offset for Pegman (relative to bottomTrailing alignment).
    @State private var pegmanOffset: CGSize = .zero
    @State private var awaitingLocateMe = false
    @State private var awaitingStreetView = false
    /// Whether the map is currently tilted for angled view.
    @State private var isAngledView = false
    /// Whether Street View is pitched down to show road markings.
    @State private var isStreetAngleView = false
    /// Shared address query for map and street view search.
    @State private var searchQuery = ""
    /// Controls showing autocomplete suggestions.
    @State private var showSuggestions = false
    /// Autocomplete model
    @StateObject private var searchModel = AddressSearchModel()
    @StateObject private var previewBridge = StreetViewBridge()
    @State private var previewCoordinate: CLLocationCoordinate2D?
    @State private var showStreetPreview = false
    @State private var suppressSuggestions = false

    /// Main screen content that switches between Map and Street View.
    var body: some View {
        ZStack {
            if isInStreetView {
                // Full-screen Street View
                StreetViewContainer(coordinate: streetViewCoordinate, bridge: streetBridge)
                    .ignoresSafeArea()
                
                if drawingsLocked || isDrawingOnStreet {
                    DrawingOverlayView(isDrawing: $isDrawingOnStreet, paths: $streetPaths, strokeColor: drawColor)
                        .ignoresSafeArea()
                }

                // Overlay controls for Street View
                // NOTE: Switch to a simpler background if performance is an issue on older devices
                StreetViewControlsView(
                    isDrawingOnStreet: $isDrawingOnStreet,
                    drawingsLocked: $drawingsLocked,
                    isStreetAngleView: $isStreetAngleView,
                    selectedColor: $drawColor,
                    searchText: searchBinding,
                    showSuggestions: $showSuggestions,
                    suggestions: searchModel.completions,
                    onBackToMap: { isInStreetView = false },
                    onLocateMe: { goToUserLocation(forStreetView: true) },
                    onToggleStreetAngle: { toggleStreetAngleView() },
                    onSearchAddress: { searchAddress(forStreetView: true) },
                    onSelectSuggestion: { selectCompletion($0, forStreetView: true) },
                    onClearStreetDrawings: { streetPaths.removeAll() }
                )
            } else {
                // Full-screen Map
                MapContainerView(centerCoordinate: $mapCenter,
                                 currentZoom: $mapZoom,
                                 bridge: bridge)
                    .ignoresSafeArea()
                
                if drawingsLocked || isDrawingOnMap {
                    DrawingOverlayView(isDrawing: $isDrawingOnMap, paths: $mapPaths, strokeColor: drawColor)
                        .ignoresSafeArea()
                }

                // Overlay controls for Map
                // NOTE: Switch to a simpler background if performance is an issue on older devices
                MapControlsView(
                    isDrawingOnMap: $isDrawingOnMap,
                    drawingsLocked: $drawingsLocked,
                    isAngledView: $isAngledView,
                    selectedColor: $drawColor,
                    searchText: searchBinding,
                    showSuggestions: $showSuggestions,
                    suggestions: searchModel.completions,
                    onSearchAddress: { searchAddress(forStreetView: false) },
                    onSelectSuggestion: { selectCompletion($0, forStreetView: false) },
                    onClearMapDrawings: { mapPaths.removeAll() },
                    onTogglePegman: { withAnimation { showPegman.toggle() } },
                    onToggleAngle: { toggleAngleView() }
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
                
                if let previewCoord = previewCoordinate, showStreetPreview {
                    VStack(spacing: 6) {
                        HStack {
                            Text("Street Preview")
                                .font(.caption).bold()
                                .padding(.leading, 8)
                            Spacer()
                            Button(role: .destructive) { showStreetPreview = false } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.plain)
                        }
                        StreetViewContainer(coordinate: previewCoord, bridge: previewBridge)
                            .frame(width: 200, height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(radius: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
                            )
                        HStack {
                            Button("Open Full Street View") {
                                streetViewCoordinate = previewCoord
                                isInStreetView = true
                                showStreetPreview = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    applyStreetAnglePitch()
                                }
                            }
                            .font(.caption)
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 6)
                    }
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 16)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            locationManager.requestAuthorization()
            locationManager.startUpdating()
            searchModel.update(query: searchQuery)
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
            if awaitingStreetView {
                streetViewCoordinate = coord
                isInStreetView = true
                awaitingStreetView = false
            }
            locationManager.stopUpdating()
            awaitingLocateMe = false
        }
        .onReceive(Just(searchQuery)) { newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            showSuggestions = !trimmed.isEmpty && !suppressSuggestions
            searchModel.update(query: trimmed)
        }
        .onChange(of: isStreetAngleView) { _, _ in
            applyStreetAnglePitch()
        }
        .overlay(alignment: .topLeading) {
            Button(action: { goToUserLocation(forStreetView: isInStreetView) }) {
                Label("Locate Me", systemImage: "location.fill.viewfinder")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLocateMeCoolingDown)
            .padding(.top, 10)
            .padding(.leading, 12)
        }
    }

    /// Animates the map to the user's current location with a small cooldown and stops updates afterwards.
    private func goToUserLocation(forStreetView: Bool = false) {
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
                if forStreetView {
                    streetViewCoordinate = coord
                    isInStreetView = true
                    // Apply angled pitch if enabled
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        applyStreetAnglePitch()
                    }
                    awaitingStreetView = false
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
                awaitingStreetView = forStreetView
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
            awaitingStreetView = forStreetView
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
    
    /// Toggle angled / overhead map view.
    private func toggleAngleView() {
        isAngledView.toggle()
        guard let mapView = bridge.mapView else { return }
        let targetAngle: Double = isAngledView ? 60 : 0
        let current = mapView.camera
        let update = GMSCameraUpdate.setCamera(
            GMSCameraPosition.camera(withTarget: current.target,
                                     zoom: current.zoom,
                                     bearing: current.bearing,
                                     viewingAngle: targetAngle)
        )
        mapView.animate(with: update)
        mapView.settings.tiltGestures = true
        mapView.setMinZoom(2, maxZoom: 21)
        mapView.isBuildingsEnabled = true
        mapView.isTrafficEnabled = true
    }
    
    /// Toggle Street View pitch for top-down road markings view.
    private func toggleStreetAngleView() {
        isStreetAngleView.toggle()
        applyStreetAnglePitch()
    }
    
    private var searchBinding: Binding<String> {
        Binding(
            get: { searchQuery },
            set: { newValue in
                suppressSuggestions = false
                searchQuery = newValue
            }
        )
    }
    
    private func applyStreetAnglePitch() {
        guard let pano = streetBridge.panoramaView else { return }
        let current = pano.camera
        let targetPitch: Double = isStreetAngleView ? -70 : 0
        let newCam = GMSPanoramaCamera(heading: current.orientation.heading,
                                       pitch: targetPitch,
                                       zoom: current.zoom)
        pano.animate(to: newCam, animationDuration: 0.6)
    }
    
    /// Geocodes an address and moves the map (and Street View when requested).
    private func searchAddress(forStreetView: Bool) {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        suppressSuggestions = true
        showSuggestions = false
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(query) { placemarks, error in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                return
            }
            
            guard let location = placemarks?.first?.location else { return }
            let coord = location.coordinate
            
            DispatchQueue.main.async {
                mapCenter = coord
                mapZoom = max(mapZoom, 16)
                
                if let mapView = bridge.mapView {
                    let camera = GMSCameraPosition.camera(withTarget: coord, zoom: mapZoom)
                    mapView.animate(to: camera)
                }
                
                if forStreetView {
                    streetViewCoordinate = coord
                    isInStreetView = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        applyStreetAnglePitch()
                    }
                }
                previewCoordinate = coord
                showStreetPreview = !forStreetView
                
                showSuggestions = false
            }
        }
    }
    
    /// Uses MKLocalSearch completion to move map/street view.
    private func selectCompletion(_ completion: MKLocalSearchCompletion, forStreetView: Bool) {
        suppressSuggestions = true
        showSuggestions = false
        searchQuery = completion.title + (completion.subtitle.isEmpty ? "" : " \(completion.subtitle)")
        
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                print("Autocomplete search error: \(error.localizedDescription)")
                return
            }
            guard let item = response?.mapItems.first, let loc = item.placemark.location else { return }
            let coord = loc.coordinate
            
            DispatchQueue.main.async {
                mapCenter = coord
                mapZoom = max(mapZoom, 16)
                
                if let mapView = bridge.mapView {
                    let camera = GMSCameraPosition.camera(withTarget: coord, zoom: mapZoom)
                    mapView.animate(to: camera)
                }
                
                if forStreetView {
                    streetViewCoordinate = coord
                    isInStreetView = true
                }
            }
        }
    }
}
