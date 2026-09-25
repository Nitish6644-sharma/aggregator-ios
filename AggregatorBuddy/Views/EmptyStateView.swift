import SwiftUI

/// Shown in place of the list when nothing has been saved yet.
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray.and.arrow.down.fill")
                .font(.system(size: 26))
                .foregroundStyle(Theme.teal)
                .frame(width: 56, height: 56)
                .background(Theme.tealTint, in: .rect(cornerRadius: 16))
                .padding(.bottom, 6)

            Text("Nothing saved yet")
                .font(.headline)
                .foregroundStyle(Theme.ink)

            Text("Share a link from any app — LinkedIn, YouTube, Instagram, Safari — and choose AggregatorBuddy to save it here.")
                .font(.subheadline)
                .foregroundStyle(Theme.ink2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Shown when filters/search exclude everything but items do exist.
struct NoResultsView: View {
    var body: some View {
        ContentUnavailableView(
            "No matches",
            systemImage: "line.3.horizontal.decrease.circle",
            description: Text("Try adjusting your search or filters.")
        )
    }
}
