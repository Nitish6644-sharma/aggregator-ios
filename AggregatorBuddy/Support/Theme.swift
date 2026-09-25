import SwiftUI

/// Design tokens from the Phase 1 wireframes. Calm, quiet visual language.
enum Theme {
    static let bg        = Color(hex: 0xFAFAF8)
    static let card      = Color(hex: 0xFFFFFF)
    static let ink       = Color(hex: 0x1C1C1E)
    static let ink2      = Color(hex: 0x6E6E73)
    static let teal      = Color(hex: 0x2F6F5E)
    static let tealTint  = Color(hex: 0xE7F0EC)
    static let amber     = Color(hex: 0xD9863F)
    static let red       = Color(hex: 0xC1462F)
    static let redTint   = Color(hex: 0xFBEAE6)
    static let line      = Color(hex: 0xE7E5E0)
    static let pill      = Color(hex: 0xF1F0EC)
}

extension Color {
    /// Create a Color from a 0xRRGGBB integer.
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

extension Date {
    /// Absolute, consistent card date, e.g. "Sep 20, 2026".
    var cardFormatted: String {
        formatted(.dateTime.month(.abbreviated).day().year())
    }
}
