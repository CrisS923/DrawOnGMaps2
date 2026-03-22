import Foundation
import GoogleMaps
import Combine

/// Bridge that exposes the underlying GMSPanoramaView to SwiftUI layers.
final class StreetViewBridge: ObservableObject {
    weak var panoramaView: GMSPanoramaView?
}
