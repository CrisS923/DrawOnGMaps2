/**
 DrawingOverlayView.swift
 
 A reusable freehand drawing overlay for SwiftUI screens.
 Responsibilities:
 - Captures drag gestures to build Path strokes.
 - Renders existing paths and the in-progress path.
 */

import SwiftUI

// MARK: - View
// MARK: - Drawing Overlay (reused for map & street view)
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
// MARK: - Model
struct ColoredPath {
    var path: Path
    var color: Color
}
