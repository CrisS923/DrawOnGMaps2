/**
 MapContainerView.swift
 
 SwiftUI wrapper for GMSMapView.
 Responsibilities:
 - Creates and configures the Google map view.
 - Keeps camera bindings (center/zoom) in sync with SwiftUI state.
 - Disables heavy features by default for performance.
 */

import SwiftUI
import GoogleMaps
import CoreLocation

// MARK: - UIViewRepresentable
struct MapContainerView: UIViewRepresentable {
    @Binding var centerCoordinate: CLLocationCoordinate2D
    @Binding var currentZoom: Float
    @ObservedObject var bridge: MapBridge
    var onMapTap: ((CLLocationCoordinate2D) -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: centerCoordinate.latitude,
                                              longitude: centerCoordinate.longitude,
                                              zoom: currentZoom,
                                              bearing: 0,
                                              viewingAngle: 0)
        let options = GMSMapViewOptions()
        options.camera = camera
        let mapView = GMSMapView(options: options)
        mapView.mapType = .satellite
        mapView.delegate = context.coordinator
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.allowScrollGesturesDuringRotateOrZoom = true
        
        // Turn off heavy features by default for better performance
        mapView.settings.tiltGestures = true
        mapView.settings.rotateGestures = true
        mapView.isBuildingsEnabled = true
        mapView.isTrafficEnabled = false
        mapView.setMinZoom(1, maxZoom: 21)
        
        // Enable user location display and location button
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        
        context.coordinator.mapView = mapView
        // Defer publishing bridge.mapView to avoid "Publishing changes from within view updates" during makeUIView/updateUIView
        DispatchQueue.main.async { [weak bridge] in
            // Only set once if not already set to this instance
            if bridge?.mapView !== mapView {
                bridge?.mapView = mapView
            }
        }
        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        if context.coordinator.isUserGesture { return } // avoid fighting active gestures
        // Avoid redundant animation if camera is already at target and zoom close enough
        if uiView.camera.target.latitude == centerCoordinate.latitude &&
            uiView.camera.target.longitude == centerCoordinate.longitude &&
            abs(uiView.camera.zoom - currentZoom) < 0.001 {
            return
        }
        
        let update = GMSCameraUpdate.setTarget(centerCoordinate, zoom: currentZoom)
        uiView.moveCamera(update)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: MapContainerView
        weak var mapView: GMSMapView?
        var isUserGesture = false

        init(_ parent: MapContainerView) { self.parent = parent }

        func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
            isUserGesture = gesture
        }

        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            isUserGesture = false
            parent.centerCoordinate = position.target
            parent.currentZoom = position.zoom
        }
        
        // Handle built-in "locate me" button to recentre map on user location.
        func mapView(_ mapView: GMSMapView, didTapMyLocationButtonFor locationButton: UIView) -> Bool {
            guard let location = mapView.myLocation else { return true }
            let targetZoom = max(parent.currentZoom, 16)
            let camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: targetZoom)
            mapView.animate(to: camera)
            parent.centerCoordinate = location.coordinate
            parent.currentZoom = targetZoom
            return true // consume default behavior
        }

        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            parent.onMapTap?(coordinate)
        }
    }
}
