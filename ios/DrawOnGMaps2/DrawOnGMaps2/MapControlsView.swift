/**
 MapControlsView.swift
 
 Stateless view that renders map mode controls.
 Responsibilities:
 - Search bar with suggestions.
 - Toggle Pegman overlay and angled map view.
 - Drawing controls (Draw/Clear/Lock) for map overlay.
 */

import SwiftUI
import MapKit

// MARK: - View
struct MapControlsView: View {
    // Bindings/state
    @Binding var isDrawingOnMap: Bool
    @Binding var drawingsLocked: Bool
    @Binding var isAngledView: Bool
    @Binding var selectedColor: Color
    @Binding var searchText: String
    @Binding var showSuggestions: Bool
    var suggestions: [MKLocalSearchCompletion]

    // Actions
    var onSearchAddress: () -> Void
    var onSelectSuggestion: (MKLocalSearchCompletion) -> Void
    var onClearMapDrawings: () -> Void
    var onTogglePegman: () -> Void
    var onToggleAngle: () -> Void

    var body: some View {
        GeometryReader { rootProxy in
            VStack(spacing: 0) {
                // Top banner with search
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 12) {
                        Spacer(minLength: 0)

                        HStack(spacing: 8) {
                            TextField("Search address", text: $searchText)
                                .textFieldStyle(.roundedBorder)
                                .submitLabel(.search)
                                .onSubmit(onSearchAddress)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .frame(maxWidth: 420)

                            Button(action: onSearchAddress) {
                                Label("Search", systemImage: "magnifyingglass")
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        Spacer(minLength: 0)

                        Button(action: onTogglePegman) {
                            Label("Street View", systemImage: "figure.walk.circle.fill")
                        }
                        .buttonStyle(.bordered)

                        Button(action: onToggleAngle) {
                            Label(isAngledView ? "Flat View" : "Angle View", systemImage: "view.3d")
                        }
                        .buttonStyle(.bordered)
                    }

                    if showSuggestions, !suggestions.isEmpty {
                        SearchSuggestionsList(suggestions: suggestions, onSelect: onSelectSuggestion)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
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
                HStack(spacing: 10) {
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

                    Menu {
                        ForEach(colorChoices, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Label(colorName(color), systemImage: "circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(color)
                            }
                        }
                    } label: {
                        Label("Color", systemImage: "paintpalette.fill")
                    }

                    Spacer(minLength: 0)

                    Toggle("Lock Drawings", isOn: $drawingsLocked)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .labelsHidden()
                        .frame(maxWidth: 140, alignment: .trailing)
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

// MARK: - Color helpers
let colorChoices: [Color] = [.yellow, .blue, .black, .red, .gray]

func colorName(_ color: Color) -> String {
    switch color {
    case .yellow: return "Yellow"
    case .blue: return "Blue"
    case .black: return "Black"
    case .red: return "Red"
    case .gray: return "Silver"
    default: return "Custom"
    }
}

// MARK: - Suggestions List
struct SearchSuggestionsList: View {
    let suggestions: [MKLocalSearchCompletion]
    var onSelect: (MKLocalSearchCompletion) -> Void
    
    var body: some View {
        let limited = Array(suggestions.prefix(5))
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(limited.enumerated()), id: \.offset) { index, suggestion in
                Button {
                    onSelect(suggestion)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.title)
                            .font(.body)
                        if !suggestion.subtitle.isEmpty {
                            Text(suggestion.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                }
                .buttonStyle(.plain)
                
                if index < limited.count - 1 {
                    Divider()
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 4)
    }
}
