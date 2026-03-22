import SwiftUI
import GoogleMaps
import CoreLocation

struct MapContainerView: UIViewRepresentable {
    @Binding var centerCoordinate: CLLocationCoordinate2D
    @Binding var currentZoom: Float
    @ObservedObject var bridge: MapBridge

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: centerCoordinate.latitude,
                                              longitude: centerCoordinate.longitude,
                                              zoom: currentZoom,
                                              bearing: 0,
                                              viewingAngle: 0)
        let mapView = GMSMapView(frame: .zero)
        mapView.camera = camera
        mapView.delegate = context.coordinator
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        
        // Turn off heavy features by default for better performance
        mapView.settings.tiltGestures = false
        mapView.settings.rotateGestures = false
        mapView.isBuildingsEnabled = false
        
        // Enable user location display and location button
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        
        context.coordinator.mapView = mapView
        bridge.mapView = mapView
        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        // Avoid redundant animation if camera is already at target and zoom close enough
        if uiView.camera.target.latitude == centerCoordinate.latitude &&
            uiView.camera.target.longitude == centerCoordinate.longitude &&
            abs(uiView.camera.zoom - currentZoom) < 0.001 {
            return
        }
        
        let camera = GMSCameraPosition.camera(withLatitude: centerCoordinate.latitude,
                                              longitude: centerCoordinate.longitude,
                                              zoom: currentZoom,
                                              bearing: uiView.camera.bearing,
                                              viewingAngle: uiView.camera.viewingAngle)
        uiView.animate(to: camera)
    }

    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: MapContainerView
        weak var mapView: GMSMapView?

        init(_ parent: MapContainerView) { self.parent = parent }

        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            parent.centerCoordinate = position.target
            parent.currentZoom = position.zoom
        }
    }
}
