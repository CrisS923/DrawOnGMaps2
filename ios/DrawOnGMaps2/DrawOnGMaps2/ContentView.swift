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
    @State private var mapCenter = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    /// Current map zoom level.
    @State private var mapZoom: Float = 16

    /// True when Street View is shown full-screen.
    @State private var isInStreetView = false
    /// Target coordinate for Street View.
    @State private var streetViewCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)

    /// Bridge exposing the underlying GMSMapView.
    @StateObject private var bridge = MapBridge()
    /// Bridge exposing the underlying GMSPanoramaView (lazy created).
    @State private var streetBridge: StreetViewBridge?
    /// Observable location manager helper.
    @StateObject private var locationManager = LocationManager()
    
    /// Prevents spamming the Locate Me action.
    @State private var isLocateMeCoolingDown = false
    
    /// Drawing state for the map overlay.
    @State private var isDrawingOnMap = false
    /// Completed user-drawn paths on the map (anchored to map coordinates).
    @State private var mapPaths: [GeoColoredPath] = []
    /// New polyline-based drawing state for floating pen menu.
    @State private var isPolylineDrawing = false
    @StateObject private var polylineStore = PolylineStore()
    /// Drawing state for the Street View overlay.
    @State private var isDrawingOnStreet = false
    /// Completed user-drawn paths on Street View.
    @State private var streetPaths: [ColoredPath] = []
    @State private var drawColor: Color = .yellow
    @State private var strokeWidth: CGFloat = 6
    /// If true, drawings remain visible while moving.
    @State private var drawingsLocked = true
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
    @State private var previewBridge: StreetViewBridge?
    @State private var previewCoordinate: CLLocationCoordinate2D?
    @State private var showStreetPreview = false
    @State private var suppressSuggestions = false
    @State private var isSearchSheet = false
    @State private var searchFieldFirstResponder = false
    /// Ensures we only auto-center to user once on launch.
    @State private var hasCenteredOnUser = false
    /// Toast message for errors like no Street View coverage.
    @State private var toastMessage: String?
    /// Panorama lookup service.
    private let panoService = GMSPanoramaService()
    private let searchDebouncer = Debouncer(delay: 0.25)

    /// Main screen content that switches between Map and Street View.
    var body: some View {
        ZStack {
            if isInStreetView {
                // Full-screen Street View (lazy bridge)
                if let streetBridge {
                    StreetViewContainer(coordinate: streetViewCoordinate, bridge: streetBridge)
                        .ignoresSafeArea()
                } else {
                    Color.black.opacity(0.2).ignoresSafeArea()
                        .onAppear {
                            if streetBridge == nil {
                                streetBridge = StreetViewBridge()
                            }
                        }
                }
                
                if drawingsLocked || isDrawingOnStreet {
                    DrawingOverlayView(isDrawing: $isDrawingOnStreet, paths: $streetPaths, strokeColor: drawColor, strokeWidth: strokeWidth)
                        .ignoresSafeArea()
                }

                // Street overlays (match map minimal UI)
                FloatingPenMenu(isDrawing: $isDrawingOnStreet,
                                selectedColor: $drawColor,
                                selectedWidth: $strokeWidth,
                                onClear: { streetPaths.removeAll() },
                                onUndo: { _ = streetPaths.popLast() })
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.leading, 16)
                .padding(.bottom, 140)

                SearchIconButton {
                    suppressSuggestions = false
                    showSuggestions = true
                    isSearchSheet = true
                    DispatchQueue.main.async {
                        searchQuery = ""
                        searchFieldFirstResponder = true
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, 12)
                .padding(.top, 12)

                AngleIconButton(isAngled: isStreetAngleView) { toggleStreetAngleView() }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.trailing, 12)
                    .padding(.top, 12)

                MapExitButton {
                    isInStreetView = false
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 12)
                .padding(.bottom, 90)
            } else {
                // Full-screen Map
                MapContainerView(centerCoordinate: $mapCenter,
                                 currentZoom: $mapZoom,
                                 bridge: bridge)
                    .ignoresSafeArea()
                
                if drawingsLocked || isDrawingOnMap {
                    MapDrawingOverlayView(isDrawing: $isDrawingOnMap,
                                          paths: $mapPaths,
                                          strokeColor: drawColor,
                                          strokeWidth: strokeWidth,
                                          bridge: bridge,
                                          centerCoordinate: $mapCenter,
                                          currentZoom: $mapZoom)
                        .ignoresSafeArea()
                }

                MapPolylineDrawingOverlay(isDrawing: $isPolylineDrawing,
                                          selectedColor: $drawColor,
                                          selectedWidth: $strokeWidth,
                                          bridge: bridge,
                                          store: polylineStore)
                    .ignoresSafeArea()
                
                FloatingPenMenu(isDrawing: $isPolylineDrawing,
                                selectedColor: $drawColor,
                                selectedWidth: $strokeWidth,
                                onClear: { polylineStore.clear() },
                                onUndo: { polylineStore.undo() })
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.leading, 16)
                .padding(.bottom, 140)

                // Search icon top-left
                SearchIconButton {
                    suppressSuggestions = false
                    showSuggestions = true
                    isSearchSheet = true
                    DispatchQueue.main.async {
                        searchFieldFirstResponder = true
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, 12)
                .padding(.top, 12)

                // Angle toggle top-right
                AngleIconButton(isAngled: isAngledView) { toggleAngleView() }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.trailing, 12)
                    .padding(.top, 12)

                // Tap-to-arm then drag Pegman (bottom-right)
                PegmanDragButton { globalPoint in
                    guard let mapView = bridge.mapView else { return }
                    let dropPointInMap = mapView.convert(globalPoint, from: nil)
                    let coord = mapView.projection.coordinate(for: dropPointInMap)
                    handleMapTap(coord)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 12)
                .padding(.bottom, 90)
                
                if let previewCoord = previewCoordinate, showStreetPreview, let previewBridge {
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
                    .shadow(radius: 2, y: 1)
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
            // If we already have a cached location, start there
            if let loc = locationManager.lastLocation, !hasCenteredOnUser {
                let coord = loc.coordinate
                mapCenter = coord
                streetViewCoordinate = coord
                mapZoom = max(mapZoom, 16)
                if let mapView = bridge.mapView {
                    let cam = GMSCameraPosition.camera(withTarget: coord, zoom: mapZoom)
                    mapView.moveCamera(GMSCameraUpdate.setCamera(cam))
                }
                hasCenteredOnUser = true
            }
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
        .onChange(of: locationManager.lastLocation) { _, newValue in
            guard let loc = newValue else { return }
            mapCenter = loc.coordinate
            streetViewCoordinate = loc.coordinate
        }
        .onChange(of: locationManager.lastLocation) { _, newValue in
            guard let loc = newValue, !hasCenteredOnUser else { return }
            let coord = loc.coordinate
            mapCenter = coord
            streetViewCoordinate = coord
            mapZoom = max(mapZoom, 16)
            if let mapView = bridge.mapView {
                let cam = GMSCameraPosition.camera(withTarget: coord, zoom: mapZoom)
                mapView.animate(to: cam)
            }
            hasCenteredOnUser = true
            locationManager.stopUpdating()
        }
        .onReceive(Just(searchQuery)) { newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            showSuggestions = !trimmed.isEmpty && !suppressSuggestions
            searchDebouncer.schedule {
                searchModel.update(query: trimmed)
            }
        }
        .onReceive(bridge.$mapView.compactMap { $0 }) { mapView in
            let disable = isDrawingOnMap || isPolylineDrawing
            mapView.settings.scrollGestures = !disable
            mapView.settings.zoomGestures = !disable
            if mapView.settings.rotateGestures != !disable {
                mapView.settings.rotateGestures = !disable
            }
            if mapView.settings.tiltGestures != !disable {
                mapView.settings.tiltGestures = !disable
            }
        }
        .onChange(of: isStreetAngleView) { _, _ in
            applyStreetAnglePitch()
        }
        .onChange(of: isDrawingOnMap) { _, newValue in
            if let mapView = bridge.mapView {
                let disable = newValue || isPolylineDrawing
                mapView.settings.scrollGestures = !disable
                mapView.settings.zoomGestures = !disable
                mapView.settings.rotateGestures = !disable
                mapView.settings.tiltGestures = !disable
            }
        }
        .onChange(of: isPolylineDrawing) { _, newValue in
            if let mapView = bridge.mapView {
                let disable = newValue || isDrawingOnMap
                mapView.settings.scrollGestures = !disable
                mapView.settings.zoomGestures = !disable
                mapView.settings.rotateGestures = !disable
                mapView.settings.tiltGestures = !disable
            }
        }
        .sheet(isPresented: $isSearchSheet, onDismiss: {
            showSuggestions = false
        }) {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    AutoFocusTextField(
                        text: searchBinding,
                        isFirstResponder: $searchFieldFirstResponder,
                        onSubmit: {
                            searchAddress(forStreetView: isInStreetView)
                            isSearchSheet = false
                            searchQuery = ""
                        }
                    )
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .frame(height: 44)
                    .padding(.horizontal, 8)
                    .padding(.top, 12)
                }
                .padding(.bottom, 8)
                
                if showSuggestions, !searchModel.completions.isEmpty {
                    ScrollView {
                        VStack(spacing: 0) {
                            SearchSuggestionsList(
                                suggestions: searchModel.completions.prefix(5).map { $0 },
                                onSelect: { completion in
                                    selectCompletion(completion, forStreetView: isInStreetView)
                                    isSearchSheet = false
                                }
                            )
                        }
                        .padding(.horizontal, 8)
                    }
                    .frame(maxHeight: 210)
                } else {
                    Spacer(minLength: 0)
                }
            }
            .padding(.bottom, 12)
            .presentationDetents([.fraction(0.35)])
            .presentationDragIndicator(.visible)
            .onAppear {
                DispatchQueue.main.async {
                    searchQuery = ""
                    searchFieldFirstResponder = true
                }
            }
            .onDisappear {
                searchFieldFirstResponder = false
            }
        }
        .overlay(alignment: .bottom) {
            if let toastMessage {
                Text(toastMessage)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(radius: 4, y: 1)
                    .transition(.opacity)
                    .padding(.bottom, 90)
            }
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
        let newCam = GMSCameraPosition.camera(withTarget: current.target,
                                              zoom: current.zoom,
                                              bearing: current.bearing,
                                              viewingAngle: targetAngle)
        if abs(current.viewingAngle - targetAngle) > 0.1 {
            mapView.animate(to: newCam)
        }
        mapView.settings.tiltGestures = true
        mapView.setMinZoom(2, maxZoom: 21)
        mapView.isBuildingsEnabled = true
        mapView.isTrafficEnabled = false
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
        guard let pano = streetBridge?.panoramaView else { return }
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

    private func handleMapTap(_ coord: CLLocationCoordinate2D) {
        panoService.requestPanoramaNearCoordinate(coord, radius: 150) { panorama, _ in
            DispatchQueue.main.async {
                if panorama != nil {
                    streetViewCoordinate = coord
                    isInStreetView = true
                } else {
                    toastMessage = "No Street View here"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        toastMessage = nil
                    }
                }
            }
        }
    }
}

// MARK: - Tap Capture Overlay
private struct TapCaptureView: UIViewRepresentable {
    var onTap: (CGPoint) -> Void

    func makeUIView(context: Context) -> UIView {
        let v = UIView(frame: .zero)
        v.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        v.addGestureRecognizer(tap)
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap) }

    final class Coordinator: NSObject {
        let onTap: (CGPoint) -> Void
        init(onTap: @escaping (CGPoint) -> Void) { self.onTap = onTap }
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            let point = recognizer.location(in: recognizer.view)
            onTap(point)
        }
    }
}

// MARK: - Small Icon Buttons
private struct SearchIconButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(.primary)
                .padding(14)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(radius: 4, y: 1)
        }
    }
}

private struct AngleIconButton: View {
    var isAngled: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "view.3d")
                .font(.title2)
                .foregroundStyle(.primary)
                    .padding(14)
                    .background(Color.black.opacity(0.1))
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(isAngled ? Color.blue : Color.clear, lineWidth: 2)
                    )
                    .shadow(radius: 1, y: 0.5)
        }
    }
}

private struct MapExitButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "map.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .padding(14)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(radius: 2, y: 1)
        }
        .accessibilityLabel("Back to map")
    }
}

private struct PegmanDragButton: View {
    var onDrop: (CGPoint) -> Void
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        let drag = DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                dragOffset = .zero
                onDrop(value.location)
            }
        
        Image(systemName: "figure.walk.circle.fill")
            .font(.title2)
            .foregroundStyle(.white)
            .padding(14)
            .background(Color.blue.opacity(0.78))
            .clipShape(Circle())
            .shadow(radius: 1, y: 0.5)
            .offset(dragOffset)
            .gesture(drag)
            .accessibilityLabel("Drag to enter Street View")
    }
}
