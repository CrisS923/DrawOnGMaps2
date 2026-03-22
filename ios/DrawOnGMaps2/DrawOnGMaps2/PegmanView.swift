import SwiftUI

struct PegmanView: View {
    @Binding var offset: CGSize
    var onDrop: (_ globalDropPoint: CGPoint) -> Void
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
                    .onEnded { value in
                        // Compute a global drop point relative to screen center + offset
                        if let window = UIApplication.shared.connectedScenes
                            .compactMap({ $0 as? UIWindowScene })
                            .flatMap({ $0.windows })
                            .first(where: { $0.isKeyWindow }) {
                            let center = CGPoint(x: window.bounds.midX, y: window.bounds.midY)
                            let dropPointGlobal = CGPoint(x: center.x + offset.width, y: center.y + offset.height)
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
