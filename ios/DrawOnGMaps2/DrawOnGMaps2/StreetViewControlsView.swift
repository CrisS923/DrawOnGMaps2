import SwiftUI

struct StreetViewControlsView: View {
    // Bindings/state
    @Binding var isDrawingOnStreet: Bool
    @Binding var drawingsLocked: Bool

    // Actions
    var onBackToMap: () -> Void
    var onClearStreetDrawings: () -> Void

    var body: some View {
        VStack {
            HStack {
                Button(action: onBackToMap) {
                    Label("Back to Map", systemImage: "map")
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding([.top, .horizontal], 16)

            HStack {
                Button {
                    isDrawingOnStreet.toggle()
                } label: {
                    Label("Draw", systemImage: isDrawingOnStreet ? "pencil.slash" : "pencil")
                }
                .buttonStyle(.bordered)

                Button(action: onClearStreetDrawings) {
                    Label("Clear", systemImage: "trash")
                }
                .buttonStyle(.bordered)

                Toggle("Lock Drawings", isOn: $drawingsLocked)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding([.horizontal, .bottom], 16)

            Spacer()
        }
    }
}
