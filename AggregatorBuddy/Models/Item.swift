import Foundation
import SwiftData

/// A saved link ("card"). Phase 1: all metadata is entered manually — no
/// auto-fetch of title/thumbnail/OG data.
///
/// NOTE: This file must belong to BOTH targets (main app + Share Extension).
/// In Xcode, tick both targets under File Inspector → Target Membership.
@Model
final class Item {
    var id: UUID
    var url: String
    var title: String
    var source: String          // free-text, e.g. "LinkedIn", "YouTube", "Article"
    var notes: String?          // optional, manual
    var dateAdded: Date
    var isRead: Bool
    var tags: [String]          // simple string array for Phase 1

    // Phase 2: cached link preview (fetched once, then read from disk).
    @Attribute(.externalStorage) var previewImageData: Data?
    var previewFetchAttempted: Bool = false

    init(
        id: UUID = UUID(),
        url: String,
        title: String,
        source: String,
        notes: String? = nil,
        dateAdded: Date = .now,
        isRead: Bool = false,
        tags: [String] = [],
        previewImageData: Data? = nil,
        previewFetchAttempted: Bool = false
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.source = source
        self.notes = notes
        self.dateAdded = dateAdded
        self.isRead = isRead
        self.tags = tags
        self.previewImageData = previewImageData
        self.previewFetchAttempted = previewFetchAttempted
    }

    /// Parse a comma-separated tag string into a normalized array:
    /// trimmed, lowercased, empties removed, de-duplicated (order preserved).
    static func parseTags(_ raw: String) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for piece in raw.split(separator: ",") {
            let tag = piece.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !tag.isEmpty, !seen.contains(tag) else { continue }
            seen.insert(tag)
            result.append(tag)
        }
        return result
    }

    /// Friendly source name derived from a URL's domain (no network).
    /// Returns "" if no host can be parsed (e.g. plain-text share).
    static func detectSource(from urlString: String) -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        let host = URLComponents(string: trimmed)?.host
            ?? URLComponents(string: "https://\(trimmed)")?.host
        guard var h = host?.lowercased() else { return "" }
        if h.hasPrefix("www.") { h.removeFirst(4) }

        let map: [String: String] = [
            "linkedin.com": "LinkedIn",
            "instagram.com": "Instagram",
            "twitter.com": "Twitter/X",
            "x.com": "Twitter/X",
            "youtube.com": "YouTube",
            "youtu.be": "YouTube",
            "facebook.com": "Facebook",
            "fb.com": "Facebook",
            "medium.com": "Medium",
            "reddit.com": "Reddit",
            "github.com": "GitHub",
            "tiktok.com": "TikTok",
            "threads.net": "Threads",
        ]
        // Match the domain or any subdomain of it (e.g. in.linkedin.com, m.youtube.com).
        for (domain, name) in map where h == domain || h.hasSuffix("." + domain) {
            return name
        }
        return h   // fallback: the bare domain, e.g. "nytimes.com"
    }
}
