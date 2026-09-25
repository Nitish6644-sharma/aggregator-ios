import Foundation
import LinkPresentation
import UIKit

/// Fetches a link's preview image + title using Apple's LinkPresentation
/// framework. Network call — used once per item, then cached on the `Item`.
///
/// `nonisolated` so it can run concurrently off the main actor (the project
/// defaults to MainActor isolation).
enum LinkPreviewFetcher {
    struct Result: Sendable {
        var imageData: Data?
        var title: String?
    }

    nonisolated static func fetch(_ urlString: String) async -> Result {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return Result() }

        let url: URL?
        if let parsed = URL(string: trimmed), parsed.scheme != nil {
            url = parsed
        } else {
            url = URL(string: "https://\(trimmed)")
        }
        guard let url else { return Result() }

        // LPMetadataProvider is single-use: one fetch per instance.
        let provider = LPMetadataProvider()
        provider.timeout = 10

        do {
            let metadata = try await provider.startFetchingMetadata(for: url)
            var imageData: Data?
            if let imageProvider = metadata.imageProvider {
                imageData = await imageProvider.asImageData()
            }
            return Result(imageData: imageData, title: metadata.title)
        } catch {
            return Result()   // no network / blocked / no preview — caller shows fallback
        }
    }
}

private extension NSItemProvider {
    /// Load this provider's image as JPEG data, or nil.
    nonisolated func asImageData() async -> Data? {
        guard canLoadObject(ofClass: UIImage.self) else { return nil }
        return await withCheckedContinuation { continuation in
            _ = loadObject(ofClass: UIImage.self) { object, _ in
                let data = (object as? UIImage)?.jpegData(compressionQuality: 0.8)
                continuation.resume(returning: data)
            }
        }
    }
}
