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
    var mapView: GMSMapView?
    @Binding var centerCoordinate: CLLocationCoordinate2D
    @Binding var currentZoom: Float

    @State private var currentCoords: [CLLocationCoordinate2D] = []

    var body: some View {
        GeometryReader { _ in
            ZStack {
                ForEach(paths.indices, id: \.self) { idx in
                    if let mapView {
                        path(for: paths[idx].coords, mapView: mapView)
                            .stroke(paths[idx].color, lineWidth: 4)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                }
                if let mapView, !currentCoords.isEmpty {
                    path(for: currentCoords, mapView: mapView)
                        .stroke(strokeColor, lineWidth: 4)
                        .opacity(isDrawing ? 1 : 0)
                }
            }
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .allowsHitTesting(isDrawing)
        }
        // trigger redraw when camera changes
        .id(redrawKey)
    }

    private var redrawKey: String {
        "\(centerCoordinate.latitude)-\(centerCoordinate.longitude)-\(currentZoom)"
    }
    
    private func path(for coords: [CLLocationCoordinate2D], mapView: GMSMapView) -> Path {
        var path = Path()
        guard let first = coords.first else { return path }
        path.move(to: mapView.projection.point(for: first))
        for coord in coords.dropFirst() {
            path.addLine(to: mapView.projection.point(for: coord))
        }
        return path
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard isDrawing, let mapView else { return }
                let coord = mapView.projection.coordinate(for: value.location)
                currentCoords.append(coord)
            }
            .onEnded { _ in
                guard isDrawing, !currentCoords.isEmpty else { return }
                paths.append(GeoColoredPath(coords: currentCoords, color: strokeColor))
                currentCoords = []
            }
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
