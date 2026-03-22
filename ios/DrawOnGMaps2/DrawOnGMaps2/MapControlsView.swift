/**
 MapControlsView.swift
 
 Stateless view that renders map mode controls.
 Responsibilities:
 - Locate Me button with cooldown (binding provided by parent).
 - Toggle Pegman overlay.
 - Drawing controls (Draw/Clear/Lock) for map overlay.
 */

import SwiftUI

// MARK: - View
struct MapControlsView: View {
    // Bindings/state
    @Binding var isLocateMeCoolingDown: Bool
    @Binding var isDrawingOnMap: Bool
    @Binding var drawingsLocked: Bool

    // Actions
    var onLocateMe: () -> Void
    var onClearMapDrawings: () -> Void
    var onTogglePegman: () -> Void

    var body: some View {
        GeometryReader { rootProxy in
            VStack(spacing: 0) {
                // Top banner
                HStack {
                    Button(action: onLocateMe) {
                        Label("Locate Me", systemImage: "location.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLocateMeCoolingDown)

                    Spacer()

                    Button(action: onTogglePegman) {
                        Label("Street View", systemImage: "figure.walk.circle.fill")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding([.top, .horizontal], 16)
                .frame(maxWidth: .infinity, alignment: .top)
                .background(
                    GeometryReader { bannerProxy in
                        Color.clear
                            .onAppear {
                                // #region agent log
                                AgentDebugLogger.log(
                                    runId: "initial",
                                    hypothesisId: "H4",
                                    location: "MapControlsView.swift:topBanner",
                                    message: "Top banner rendered",
                                    data: [
                                        "minY": bannerProxy.frame(in: .global).minY,
                                        "maxY": bannerProxy.frame(in: .global).maxY,
                                        "rootHeight": rootProxy.size.height
                                    ]
                                )
                                // #endregion
                            }
                    }
                )

                Spacer(minLength: 0)

                // Bottom banner
                HStack {
                    Button {
                        isDrawingOnMap.toggle()
                    } label: {
                        Label("Draw", systemImage: isDrawingOnMap ? "pencil.slash" : "pencil")
                    }
                    .buttonStyle(.bordered)

                    Button(action: onClearMapDrawings) {
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
                .frame(maxWidth: .infinity, alignment: .bottom)
                .background(
                    GeometryReader { bannerProxy in
                        Color.clear
                            .onAppear {
                                // #region agent log
                                AgentDebugLogger.log(
                                    runId: "initial",
                                    hypothesisId: "H4",
                                    location: "MapControlsView.swift:bottomBanner",
                                    message: "Bottom banner rendered",
                                    data: [
                                        "minY": bannerProxy.frame(in: .global).minY,
                                        "maxY": bannerProxy.frame(in: .global).maxY,
                                        "rootHeight": rootProxy.size.height
                                    ]
                                )
                                // #endregion
                            }
                    }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                // #region agent log
                AgentDebugLogger.log(
                    runId: "initial",
                    hypothesisId: "H4",
                    location: "MapControlsView.swift:container",
                    message: "Map controls container appeared",
                    data: [
                        "rootHeight": rootProxy.size.height,
                        "rootWidth": rootProxy.size.width
                    ]
                )
                // #endregion
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

