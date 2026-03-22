import SwiftUI

// MARK: - Drawing Overlay (reused for map & street view)
struct DrawingOverlayView: View {
    @Binding var isDrawing: Bool
    @Binding var paths: [Path]

    @State private var current = Path()

    var body: some View {
        GeometryReader { _ in
            ZStack {
                ForEach(paths.indices, id: \.self) { idx in
                    paths[idx].stroke(Color.yellow, lineWidth: 4)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                current.stroke(Color.yellow, lineWidth: 4)
                    .opacity(isDrawing ? 1 : 0)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard isDrawing else { return }
                    if current.isEmpty { current.move(to: value.location) }
                    else { current.addLine(to: value.location) }
                }
                .onEnded { _ in
                    guard isDrawing else { return }
                    paths.append(current)
                    current = Path()
                }
            )
        }
    }
}
