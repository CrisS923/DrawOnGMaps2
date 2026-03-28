/**
 FloatingPenMenu.swift
 
 A lightweight floating pen button for map drawing.
 - Shows only in map mode (wired from ContentView).
 - Primary pen button toggles a dropdown with five colors and a draw on/off toggle.
 - Placed bottom-left, outside the existing control bars.
 */

import SwiftUI

struct FloatingPenMenu: View {
    @Binding var isDrawing: Bool
    @Binding var selectedColor: Color
    @Binding var selectedWidth: CGFloat
    var onClear: () -> Void
    var onUndo: () -> Void
    
    @State private var isOpen = false
    @State private var showWidths = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isOpen {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(colorChoices, id: \.self) { color in
                        Button {
                            selectedColor = color
                            isDrawing = true
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                isOpen = false
                                showWidths = true
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(selectedColor == color ? 0.9 : 0), lineWidth: 2)
                                    )
                                Text(colorName(color))
                                    .foregroundStyle(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(12)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(radius: 6)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            if showWidths {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Line thickness")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        ForEach(strokeWidthPresets, id: \.self) { width in
                            Button {
                                selectedWidth = width
                                showWidths = false
                            } label: {
                                VStack(spacing: 2) {
                                    Capsule()
                                        .fill(selectedColor)
                                        .frame(width: 36, height: width)
                                    Text(strokeWidthLabel(width))
                                        .font(.caption2)
                                }
                                .padding(6)
                                .frame(width: 60)
                                .background(width == selectedWidth ? Color.blue.opacity(0.12) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(10)
                .background(Color.black.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 1, y: 0.5)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    isOpen.toggle()
                    showWidths = false
                }
            } label: {
                Image(systemName: "pencil.tip")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(isDrawing ? Color.blue : Color.primary)
                    .clipShape(Circle())
                .shadow(radius: 3, y: 1)
            }
            .accessibilityLabel("Drawing menu")
            
            VStack(alignment: .leading, spacing: 8) {
                Button(action: onUndo) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: onClear) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
