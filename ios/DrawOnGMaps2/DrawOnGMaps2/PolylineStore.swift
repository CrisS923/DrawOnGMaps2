import Foundation
import Combine
import GoogleMaps

/// Stores polylines added by the floating pen overlay to support undo/clear.
final class PolylineStore: ObservableObject {
    @Published private(set) var polylines: [GMSPolyline] = []
    
    func add(_ polyline: GMSPolyline) {
        polylines.append(polyline)
    }
    
    func clear() {
        polylines.forEach { $0.map = nil }
        polylines.removeAll()
    }
    
    func undo() {
        guard let last = polylines.popLast() else { return }
        last.map = nil
    }
}
