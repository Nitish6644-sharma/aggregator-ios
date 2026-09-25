import SwiftUI
import SwiftData

@main
struct AggregatorBuddyApp: App {
    var body: some Scene {
        WindowGroup {
            HomeFeedView()
        }
        .modelContainer(SharedModelContainer.shared)
    }
}
