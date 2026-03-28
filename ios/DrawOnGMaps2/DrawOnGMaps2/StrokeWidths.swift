import SwiftUI

/// Preset stroke widths in points for drawing.
let strokeWidthPresets: [CGFloat] = [2, 4, 6, 8, 12]

func strokeWidthLabel(_ width: CGFloat) -> String {
    switch width {
    case 2: return "Thin"
    case 4: return "Fine"
    case 6: return "Medium"
    case 8: return "Bold"
    case 12: return "Marker"
    default: return "Custom"
    }
}
