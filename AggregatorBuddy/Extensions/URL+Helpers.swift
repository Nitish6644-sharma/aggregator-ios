import Foundation

enum LinkOpener {
    /// Build a normalized URL from a stored string. Adds https:// if the user
    /// stored a bare host (e.g. "youtube.com/…"). Returns nil if unusable.
    static func url(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let u = URL(string: trimmed), u.scheme != nil {
            return u
        }
        return URL(string: "https://\(trimmed)")
    }
}

extension String {
    /// First detected URL inside arbitrary shared text, or nil.
    var firstDetectedURL: String? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        let range = NSRange(startIndex..<endIndex, in: self)
        let match = detector.firstMatch(in: self, options: [], range: range)
        return match?.url?.absoluteString
    }
}
