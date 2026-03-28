/**
 StreetViewControlsView.swift
 
 Stateless view that renders street view mode controls.
 Responsibilities:
 - Back to Map button.
 - Drawing controls (Draw/Clear/Lock) for street overlay.
 */

import SwiftUI
import MapKit

// MARK: - View
struct StreetViewControlsView: View {
    // Bindings/state
    @Binding var isDrawingOnStreet: Bool
    @Binding var drawingsLocked: Bool
    @Binding var isStreetAngleView: Bool
    @Binding var selectedColor: Color
    @Binding var searchText: String
    @Binding var showSuggestions: Bool
    var suggestions: [MKLocalSearchCompletion]
    
    // Actions
    var onBackToMap: () -> Void
    var onLocateMe: () -> Void
    var onToggleStreetAngle: () -> Void
    var onSearchAddress: () -> Void
    var onSelectSuggestion: (MKLocalSearchCompletion) -> Void
    var onClearStreetDrawings: () -> Void
    
    var body: some View {
        
        // Top banner
        VStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    Button(action: onLocateMe) {
                        Label("Locate Me", systemImage: "location.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: onBackToMap) {
                        Label("Back to Map", systemImage: "map")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: onToggleStreetAngle) {
                        Label(isStreetAngleView ? "Driver View" : "Angle View", systemImage: "view.3d")
                    }
                    .buttonStyle(.bordered)
                    
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
                        Spacer(minLength: 0)
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
                
                Spacer()
                
                // Bottom banner
                HStack(spacing: 10) {
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
                    
                    Toggle(isOn: $drawingsLocked) {
                        Label("Lock drawings", systemImage: drawingsLocked ? "lock.fill" : "lock.open")
                            .labelStyle(.titleAndIcon)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .frame(maxWidth: 180, alignment: .trailing)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding([.horizontal, .bottom], 16)
            }
            .frame (maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
