import Foundation
import GoogleMaps

/// Provides helper functions to zoom in/out on a GMSPanoramaView.
struct StreetViewZoomController {
    /// Zooms in by a given increment (default 0.5) with animation.
    static func zoomIn(_ panoramaView: GMSPanoramaView?, increment: Float = 0.5) {
        guard let pano = panoramaView else { return }
        let newZoom = pano.camera.zoom + increment
        let updated = GMSPanoramaCamera(orientation: pano.camera.orientation, zoom: newZoom)
        pano.animate(to: updated, animationDuration: 0.35)
    }

    /// Zooms out by a given increment (default 0.5) with animation.
    static func zoomOut(_ panoramaView: GMSPanoramaView?, increment: Float = 0.5) {
        guard let pano = panoramaView else { return }
        let newZoom = pano.camera.zoom - increment
        let updated = GMSPanoramaCamera(orientation: pano.camera.orientation, zoom: newZoom)
        pano.animate(to: updated, animationDuration: 0.35)
    }
}
