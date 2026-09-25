import SwiftUI

/// Tag editor: shows current tags as removable chips, a text field to add new
/// ones, and live suggestions drawn from `suggestions` (existing tags) as you
/// type. Commit a typed tag with Return or a comma, or tap a suggestion.
///
/// Self-contained (inlined colors + wrap layout) so it can be a member of BOTH
/// the app and the Share Extension targets without pulling in Theme/FlowLayout.
/// Only external dependency is `Item.parseTags` (already shared with both).
struct TagInputField: View {
    @Binding var tags: [String]
    let suggestions: [String]

    @State private var input = ""
    @FocusState private var focused: Bool

    private var matches: [String] {
        let q = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        return suggestions
            .filter { $0.contains(q) && !tags.contains($0) }
            .prefix(8)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !tags.isEmpty {
                WrapLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        Button { remove(tag) } label: {
                            HStack(spacing: 4) {
                                Text(tag)
                                Image(systemName: "xmark").font(.system(size: 8, weight: .bold))
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(tagTealTint, in: .capsule)
                            .foregroundStyle(tagTeal)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            TextField("Add a tag…", text: $input)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focused)
                .submitLabel(.done)
                .onSubmit { commitTyped() }
                .onChange(of: input) { _, v in if v.contains(",") { commitTyped() } }
                .onChange(of: focused) { _, isFocused in if !isFocused { commitTyped() } }

            if !matches.isEmpty {
                WrapLayout(spacing: 6) {
                    ForEach(matches, id: \.self) { suggestion in
                        Button { add(suggestion) } label: {
                            Text(suggestion)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(tagPill, in: .capsule)
                                .foregroundStyle(tagInk2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Mutations

    private func commitTyped() {
        for tag in Item.parseTags(input) { addNormalized(tag) }
        input = ""
    }

    private func add(_ tag: String) {
        addNormalized(tag.lowercased())
        input = ""
    }

    private func addNormalized(_ tag: String) {
        guard !tag.isEmpty, !tags.contains(tag) else { return }
        tags.append(tag)
    }

    private func remove(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

// MARK: - Inlined styling (kept local so the extension needs no shared theme file)

private let tagTeal     = Color(red: 0x2F/255, green: 0x6F/255, blue: 0x5E/255)
private let tagTealTint = Color(red: 0xE7/255, green: 0xF0/255, blue: 0xEC/255)
private let tagInk2     = Color(red: 0x6E/255, green: 0x6E/255, blue: 0x73/255)
private let tagPill     = Color(red: 0xF1/255, green: 0xF0/255, blue: 0xEC/255)

/// Minimal wrapping layout (a private twin of the app's FlowLayout) so this file
/// stays self-contained across both targets.
private struct WrapLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
