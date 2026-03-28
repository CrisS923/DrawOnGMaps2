import Foundation
import GoogleMaps
import Combine

/// Bridge that exposes the underlying GMSPanoramaView to SwiftUI layers.
final class StreetViewBridge: ObservableObject {
    // Publish to allow SwiftUI to refresh when the panorama view is created.
    @Published var panoramaView: GMSPanoramaView?
}
