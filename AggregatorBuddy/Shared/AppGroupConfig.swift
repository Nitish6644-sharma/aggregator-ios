import Foundation
import SwiftData

/// Central place for the App Group identifier and the shared SwiftData container.
///
/// IMPORTANT: This file must belong to BOTH targets (main app + Share Extension)
/// so they open the *same* store. In Xcode, select this file and tick both
/// targets under File Inspector → Target Membership.
enum AppGroup {
    /// Must match the App Group capability enabled on both targets.
    static let identifier = "group.com.nitishsharma.aggregatorbuddy"
}

enum SharedModelContainer {
    /// A single container pointed at the App Group so writes from the Share
    /// Extension are visible to the main app (and vice versa).
    static let shared: ModelContainer = {
        let config = ModelConfiguration(
            groupContainer: .identifier(AppGroup.identifier)
        )
        do {
            return try ModelContainer(for: Item.self, configurations: config)
        } catch {
            fatalError("Failed to create shared ModelContainer: \(error)")
        }
    }()
}
