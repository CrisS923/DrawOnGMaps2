/**
 DrawingOverlayView.swift
 
 A reusable freehand drawing overlay for SwiftUI screens.
 Responsibilities:
 - Captures drag gestures to build Path strokes.
 - Renders existing paths and the in-progress path.
 */

import SwiftUI
import GoogleMaps
import CoreLocation

// MARK: - Street/overlay drawing (screen-space)
struct DrawingOverlayView: View {
    @Binding var isDrawing: Bool
    @Binding var paths: [ColoredPath]
    let strokeColor: Color

    @State private var current = Path()

    var body: some View {
        GeometryReader { _ in
            ZStack {
                ForEach(paths.indices, id: \.self) { idx in
                    paths[idx].path.stroke(paths[idx].color, lineWidth: 4)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                current.stroke(strokeColor, lineWidth: 4)
                    .opacity(isDrawing ? 1 : 0)
            }
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .allowsHitTesting(isDrawing) // let map/street gestures (pinch/zoom) pass through when not drawing
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard isDrawing else { return }
                if current.isEmpty { current.move(to: value.location) }
                else { current.addLine(to: value.location) }
            }
            .onEnded { _ in
                guard isDrawing else { return }
                paths.append(ColoredPath(path: current, color: strokeColor))
                current = Path()
            }
    }
}

// MARK: - Map drawing anchored to map coordinates
struct MapDrawingOverlayView: View {
    @Binding var isDrawing: Bool
    @Binding var paths: [GeoColoredPath]
    let strokeColor: Color
    @ObservedObject var bridge: MapBridge
    @Binding var centerCoordinate: CLLocationCoordinate2D
    @Binding var currentZoom: Float

    @State private var currentCoords: [CLLocationCoordinate2D] = []
    
    private var mapView: GMSMapView? { bridge.mapView }

    var body: some View {
        GeometryReader { geo in
            let overlayOrigin = geo.frame(in: .global).origin
            ZStack {
                ForEach(paths.indices, id: \.self) { idx in
                    path(for: paths[idx].coords, overlayOrigin: overlayOrigin)
                        .stroke(paths[idx].color, lineWidth: 4)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                if !currentCoords.isEmpty {
                    path(for: currentCoords, overlayOrigin: overlayOrigin)
                        .stroke(strokeColor, lineWidth: 4)
                        .opacity(isDrawing ? 1 : 0)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        guard isDrawing, let mapView else { return }
                        // Convert drag point (global) into mapView coordinates using its global frame.
                        let mapOriginGlobal = mapView.convert(CGPoint.zero, to: nil)
                        let pointInMap = CGPoint(x: value.location.x - mapOriginGlobal.x,
                                                 y: value.location.y - mapOriginGlobal.y)
                        let coord = mapView.projection.coordinate(for: pointInMap)
                        currentCoords.append(coord)
                    }
                    .onEnded { _ in
                        guard isDrawing, !currentCoords.isEmpty else { return }
                        paths.append(GeoColoredPath(coords: currentCoords, color: strokeColor))
                        currentCoords = []
                    }
            )
            .allowsHitTesting(isDrawing)
        }
        // trigger redraw when camera changes
        .id(redrawKey)
    }

    private var redrawKey: String {
        "\(centerCoordinate.latitude)-\(centerCoordinate.longitude)-\(currentZoom)"
    }
    
    private func path(for coords: [CLLocationCoordinate2D], overlayOrigin: CGPoint) -> Path {
        guard let mapView else { return Path() }
        let mapOriginGlobal = mapView.convert(CGPoint.zero, to: nil)
        var path = Path()
        guard let first = coords.first else { return path }
        let firstPointMap = mapView.projection.point(for: first)
        let firstPointGlobal = CGPoint(x: firstPointMap.x + mapOriginGlobal.x,
                                       y: firstPointMap.y + mapOriginGlobal.y)
        path.move(to: CGPoint(x: firstPointGlobal.x - overlayOrigin.x,
                              y: firstPointGlobal.y - overlayOrigin.y))
        for coord in coords.dropFirst() {
            let pMap = mapView.projection.point(for: coord)
            let pGlobal = CGPoint(x: pMap.x + mapOriginGlobal.x,
                                  y: pMap.y + mapOriginGlobal.y)
            path.addLine(to: CGPoint(x: pGlobal.x - overlayOrigin.x,
                                     y: pGlobal.y - overlayOrigin.y))
        }
        return path
    }
}

// MARK: - Models
struct ColoredPath {
    var path: Path
    var color: Color
}

struct GeoColoredPath {
    var coords: [CLLocationCoordinate2D]
    var color: Color
}
