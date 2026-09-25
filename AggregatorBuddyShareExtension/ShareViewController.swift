import UIKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Principal class for the Share Extension. Extracts a shared URL (or plain
/// text containing a link), then hosts the SwiftUI entry form.
///
/// No storyboard: Info.plist sets NSExtensionPrincipalClass to this class.
class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        extractSharedText { [weak self] initialText in
            self?.presentForm(initialText: initialText)
        }
    }

    // MARK: - UI

    private func presentForm(initialText: String) {
        let root = ShareEntryView(
            initialURL: initialText,
            onFinish: { [weak self] in self?.complete() }
        )
        .modelContainer(SharedModelContainer.shared)

        let host = UIHostingController(rootView: root)

        // Three-step containment (required).
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)
    }

    // MARK: - Input extraction

    /// Look for a URL attachment first; fall back to plain text (from which we
    /// try to detect a link). Returns "" if nothing usable is found.
    private func extractSharedText(completion: @escaping (String) -> Void) {
        let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
        let providers = items.flatMap { $0.attachments ?? [] }

        let urlType = UTType.url.identifier
        let textType = UTType.plainText.identifier

        // Prefer a real URL attachment.
        if let urlProvider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(urlType) }) {
            urlProvider.loadItem(forTypeIdentifier: urlType, options: nil) { value, _ in
                let urlString = (value as? URL)?.absoluteString
                    ?? (value as? String)
                    ?? ""
                DispatchQueue.main.async { completion(urlString) }
            }
            return
        }

        // Fall back to plain text; detect an embedded link if present.
        if let textProvider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(textType) }) {
            textProvider.loadItem(forTypeIdentifier: textType, options: nil) { value, _ in
                let text = (value as? String) ?? ""
                let result = Self.firstDetectedURL(in: text) ?? text
                DispatchQueue.main.async { completion(result) }
            }
            return
        }

        DispatchQueue.main.async { completion("") }
    }

    /// First detected URL inside arbitrary shared text, or nil.
    private static func firstDetectedURL(in text: String) -> String? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return detector.firstMatch(in: text, options: [], range: range)?.url?.absoluteString
    }

    // MARK: - Exit

    private func complete() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
