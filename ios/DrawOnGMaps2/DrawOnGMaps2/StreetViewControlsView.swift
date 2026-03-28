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
    @State private var isSearchSheet = false
    
    // Actions
    var onBackToMap: () -> Void
    var onLocateMe: () -> Void
    var onToggleStreetAngle: () -> Void
    var onSearchAddress: () -> Void
    var onSelectSuggestion: (MKLocalSearchCompletion) -> Void
    var onClearStreetDrawings: () -> Void
    var onUndoLastDrawing: () -> Void
    
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
                
                Button(action: { isSearchSheet = true }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                }
                .buttonStyle(.borderedProminent)
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

                    Button(action: onUndoLastDrawing) {
                        Label("Undo", systemImage: "arrow.uturn.backward")
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
        .sheet(isPresented: $isSearchSheet, onDismiss: { showSuggestions = false }) {
            NavigationView {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Search address", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.search)
                        .onSubmit {
                            onSearchAddress()
                            isSearchSheet = false
                        }
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .padding(.top, 6)
                    
                    if showSuggestions, !suggestions.isEmpty {
                        SearchSuggestionsList(suggestions: suggestions) { completion in
                            onSelectSuggestion(completion)
                            isSearchSheet = false
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Search")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { isSearchSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Search") {
                            onSearchAddress()
                            isSearchSheet = false
                        }
                    }
                }
                .onAppear { showSuggestions = true }
            }
            .presentationDetents([.medium])
        }
    }
}
