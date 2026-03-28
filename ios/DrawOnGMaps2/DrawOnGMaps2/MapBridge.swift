/**
 MapBridge.swift
 
 A tiny ObservableObject that exposes a weak reference to GMSMapView for SwiftUI layers.
 Responsibilities:
 - Allows converting screen points to coordinates and other direct map interactions from SwiftUI.
 */

import Foundation
import GoogleMaps
import Combine

// MARK: - Bridge to expose GMSMapView
final class MapBridge: ObservableObject {
    // Publish the map view so SwiftUI overlays re-render once it exists.
    @Published var mapView: GMSMapView?
}
