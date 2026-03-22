import Foundation
import GoogleMaps

// MARK: - Bridge to expose GMSMapView
final class MapBridge: ObservableObject {
    weak var mapView: GMSMapView?
}
