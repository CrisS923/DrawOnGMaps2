import SwiftUI
import GoogleMaps
import CoreLocation

struct StreetViewContainer: UIViewRepresentable {
    let coordinate: CLLocationCoordinate2D
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> GMSPanoramaView {
        let pano = GMSPanoramaView(frame: .zero)
        context.coordinator.lastCoordinate = coordinate
        pano.moveNearCoordinate(coordinate, radius: 250)
        return pano
    }
    func updateUIView(_ uiView: GMSPanoramaView, context: Context) {
        let epsilon = 0.000001
        if abs(context.coordinator.lastCoordinate.latitude - coordinate.latitude) < epsilon &&
            abs(context.coordinator.lastCoordinate.longitude - coordinate.longitude) < epsilon {
            return
        }
        uiView.moveNearCoordinate(coordinate, radius: 250)
        context.coordinator.lastCoordinate = coordinate
    }
    
    class Coordinator {
        var lastCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
}
