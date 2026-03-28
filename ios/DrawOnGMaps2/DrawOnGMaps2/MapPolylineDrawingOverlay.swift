/**
 MapPolylineDrawingOverlay.swift
 
 Captures drag gestures over the map and renders strokes as GMSPolyline overlays
 so they stay anchored to map coordinates. Independent from the existing map
 drawing overlay used by the bottom bar.
 */

import SwiftUI
import GoogleMaps
import UIKit

struct MapPolylineDrawingOverlay: View {
    @Binding var isDrawing: Bool
    @Binding var selectedColor: Color
    @Binding var selectedWidth: CGFloat
    @ObservedObject var bridge: MapBridge
    @ObservedObject var store: PolylineStore
    
    @State private var currentCoords: [CLLocationCoordinate2D] = []
    @State private var currentPath = GMSMutablePath()
    @State private var currentPolyline: GMSPolyline?
    
    private var mapView: GMSMapView? { bridge.mapView }
    
    var body: some View {
        GeometryReader { _ in
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onChanged { value in
                            guard isDrawing, let mapView else { return }
                            let mapOriginGlobal = mapView.convert(CGPoint.zero, to: nil)
                            let pointInMap = CGPoint(x: value.location.x - mapOriginGlobal.x,
                                                     y: value.location.y - mapOriginGlobal.y)
                            let coord = mapView.projection.coordinate(for: pointInMap)
                            if let last = currentCoords.last {
                                let dx = coord.latitude - last.latitude
                                let dy = coord.longitude - last.longitude
                                if (dx*dx + dy*dy) < 1e-10 { return }
                            }
                            currentCoords.append(coord)
                            
                            if currentCoords.count == 1 {
                                // start a live polyline
                                currentPath = GMSMutablePath()
                                currentPath.add(coord)
                                let polyline = GMSPolyline(path: currentPath)
                                polyline.strokeWidth = selectedWidth
                                polyline.strokeColor = UIColor(selectedColor)
                                polyline.map = mapView
                                currentPolyline = polyline
                            } else {
                                currentPath.add(coord)
                                currentPolyline?.path = currentPath
                            }
                        }
                        .onEnded { _ in
                            guard isDrawing else {
                                resetCurrent()
                                return
                            }
                            if let polyline = currentPolyline {
                                store.add(polyline)
                            }
                            isDrawing = false
                            resetCurrent()
                        }
                )
                .allowsHitTesting(isDrawing)
        }
    }
    
    private func resetCurrent() {
        currentCoords.removeAll()
        currentPath = GMSMutablePath()
        currentPolyline = nil
    }
}
