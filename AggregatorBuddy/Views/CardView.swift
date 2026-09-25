import SwiftUI
import UIKit

/// A single saved-link card in the Home Feed. Compact layout: a fixed 56×56
/// thumbnail on the left (loading / loaded / no-preview states, same footprint
/// so nothing shifts on resolve), content on the right, unread dot top-right.
struct CardView: View {
    let item: Item

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail
                .frame(width: 56, height: 56)
                .clipShape(.rect(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    Text(item.title.isEmpty ? item.url : item.title)
                        .font(.subheadline)
                        .fontWeight(item.isRead ? .semibold : .bold)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !item.isRead {
                        Circle().fill(Theme.teal).frame(width: 7, height: 7).padding(.top, 5)
                    }
                }

                HStack(spacing: 8) {
                    if !item.source.isEmpty {
                        Text(item.source)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.teal)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.tealTint, in: .rect(cornerRadius: 6))
                    }
                    Text(item.dateAdded.cardFormatted)
                        .font(.caption)
                        .foregroundStyle(Theme.ink2)
                }

                if !item.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(item.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .foregroundStyle(Theme.ink2)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4)
                                    .background(Theme.pill, in: .capsule)
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 1))
        .opacity(item.isRead ? 0.55 : 1)   // read = muted; tap/long-press unchanged
    }

    @ViewBuilder private var thumbnail: some View {
        if let data = item.previewImageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else if !item.previewFetchAttempted {
            ShimmerBox()                                   // fetch in flight
        } else {
            ZStack {                                        // attempted, no image
                Theme.pill
                Image(systemName: SourceIcon.symbol(for: item.source))
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.ink2)
            }
        }
    }
}
