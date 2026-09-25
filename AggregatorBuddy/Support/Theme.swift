import SwiftUI

/// Design tokens. Colors are defined as named assets in Assets.xcassets with
/// Light and Dark appearance slots — swap values there, no code changes needed.
enum Theme {
    static let bg       = Color("AppBackground")
    static let card     = Color("AppCard")
    static let ink      = Color("AppInk")
    static let ink2     = Color("AppInk2")
    static let teal     = Color("AppTeal")
    static let tealTint = Color("AppTealTint")
    static let amber    = Color("AppAmber")
    static let red      = Color("AppRed")
    static let redTint  = Color("AppRedTint")
    static let line     = Color("AppLine")
    static let pill     = Color("AppPill")
}

extension Date {
    /// Absolute, consistent card date, e.g. "Sep 20, 2026".
    var cardFormatted: String {
        formatted(.dateTime.month(.abbreviated).day().year())
    }
}
