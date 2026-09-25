import SwiftUI

/// Maps a (free-text) source name to a fitting SF Symbol for the no-preview
/// fallback thumbnail. Falls back to a generic link glyph.
enum SourceIcon {
    static func symbol(for source: String) -> String {
        let s = source.lowercased()
        switch true {
        case s.contains("youtube"):   return "play.rectangle.fill"
        case s.contains("instagram"): return "camera.fill"
        case s.contains("linkedin"):  return "briefcase.fill"
        case s.contains("twitter"), s == "x", s.contains("x.com"): return "bubble.left.fill"
        case s.contains("facebook"):  return "person.2.fill"
        case s.contains("reddit"):    return "bubble.left.and.bubble.right.fill"
        case s.contains("github"):    return "chevron.left.forwardslash.chevron.right"
        case s.contains("medium"):    return "doc.text.fill"
        case s.contains("tiktok"):    return "music.note"
        case s.contains("threads"):   return "at"
        default:                      return "link"
        }
    }
}

/// A shimmering skeleton box used while a preview is being fetched. Fills its
/// frame, so the parent controls the size (keeps the 56×56 footprint fixed).
struct ShimmerBox: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            Rectangle()
                .fill(Color(white: 0.90))
                .overlay(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.75), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: w * 0.7)
                    .offset(x: animate ? w : -w)
                )
                .clipped()
        }
        .onAppear {
            withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }
}
