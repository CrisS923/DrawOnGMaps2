/**
 StreetViewContainer.swift
 
 SwiftUI wrapper for GMSPanoramaView (Street View).
 Responsibilities:
 - Displays Street View near a target coordinate.
 - Caches last coordinate in a Coordinator to avoid redundant updates.
 */

import SwiftUI
import GoogleMaps
import CoreLocation
import UIKit

// MARK: - UIViewRepresentable
struct StreetViewContainer: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    @ObservedObject var bridge: StreetViewBridge
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> GMSPanoramaView {
        let pano = GMSPanoramaView(frame: .zero)
        pano.navigationGestures = true
        // Defer publishing to avoid “Publishing changes from within view updates”
        DispatchQueue.main.async { [weak bridge] in
            if bridge?.panoramaView !== pano {
                bridge?.panoramaView = pano
            }
        }
        context.coordinator.lastCoordinate = coordinate
        context.coordinator.panoramaView = pano
        
        // Custom pinch to ensure zooming works robustly
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        pinch.delegate = context.coordinator
        pano.addGestureRecognizer(pinch)
        
        pano.moveNearCoordinate(coordinate, radius: 50, source: .outside)
        return pano
    }
    func updateUIView(_ uiView: GMSPanoramaView, context: Context) {
        let epsilon = 0.000001
        if abs(context.coordinator.lastCoordinate.latitude - coordinate.latitude) < epsilon &&
            abs(context.coordinator.lastCoordinate.longitude - coordinate.longitude) < epsilon {
            return
        }
        uiView.moveNearCoordinate(coordinate, radius: 50, source: .outside)
        context.coordinator.lastCoordinate = coordinate
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var lastCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        weak var panoramaView: GMSPanoramaView?
        private var initialZoom: Float = 1.0
        
        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            guard let pano = panoramaView else { return }
            switch recognizer.state {
            case .began:
                initialZoom = pano.camera.zoom
            case .changed, .ended:
                let delta = Float(log2(recognizer.scale)) // scale 2x -> +1 zoom level
                let newZoom = max(0, min(5, initialZoom + delta))
                let cam = GMSPanoramaCamera(orientation: pano.camera.orientation, zoom: newZoom)
                pano.camera = cam
            default:
                break
            }
        }
        
        // Allow simultaneous gestures with built-in navigation
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
