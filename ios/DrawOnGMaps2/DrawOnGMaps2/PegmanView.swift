/**
 PegmanView.swift
 
 Draggable Street View activation icon.
 Responsibilities:
 - Lets the user drag a Pegman icon on top of the map.
 - Calls back with the global drop point so the parent can convert to coordinates.
 */

import SwiftUI
import UIKit

// MARK: - View

/// Draggable Pegman overlay. Use onDrop to handle conversion to map coordinates.
struct PegmanView: View {
    /// Current drag offset relative to the bottomTrailing alignment.
    @Binding var offset: CGSize
    /// Called when the user releases the drag. Parameter is the global drop point in screen coordinates.
    var onDrop: (_ globalDropPoint: CGPoint) -> Void
    /// Called when the drag ends but a global point couldn't be computed (e.g., no key window).
    var onCancel: () -> Void

    var body: some View {
        Image(systemName: "figure.walk.circle.fill")
            .font(.system(size: 36))
            .foregroundStyle(.white)
            .background(Circle().fill(Color.blue))
            .shadow(radius: 4)
            .offset(offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                    }
                    // We derive a global drop point using the bottomTrailing baseline (with padding) + accumulated offset.
                    .onEnded { value in
                        // Compute a global drop point relative to bottomTrailing baseline + offset
                        if let window = UIApplication.shared.connectedScenes
                            .compactMap({ $0 as? UIWindowScene })
                            .flatMap({ $0.windows })
                            .first(where: { $0.isKeyWindow }) {
                            let baseline = CGPoint(x: window.bounds.maxX - 24, y: window.bounds.maxY - 24)
                            let dropPointGlobal = CGPoint(x: baseline.x + offset.width, y: baseline.y + offset.height)
                            onDrop(dropPointGlobal)
                        } else {
                            onCancel()
                        }
                        offset = .zero
                    }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(24)
    }
}
