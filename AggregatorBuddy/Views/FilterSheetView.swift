import SwiftUI

enum ReadFilter: String, CaseIterable, Identifiable {
    case all = "All", unread = "Unread", read = "Read"
    var id: String { rawValue }
}

/// The set of active filters. Tags/sources use OR-within-category matching,
/// combined with AND across categories and the search text (applied separately).
struct FilterState: Equatable {
    var tags: Set<String> = []
    var sources: Set<String> = []
    var readStatus: ReadFilter = .all

    /// Number of active filter categories — drives the toolbar badge.
    var activeCount: Int {
        var n = 0
        if !tags.isEmpty { n += 1 }
        if !sources.isEmpty { n += 1 }
        if readStatus != .all { n += 1 }
        return n
    }
    var isActive: Bool { activeCount > 0 }

    func matches(_ item: Item) -> Bool {
        switch readStatus {
        case .all: break
        case .unread where item.isRead: return false
        case .read where !item.isRead: return false
        default: break
        }
        if !sources.isEmpty, !sources.contains(item.source) { return false }
        if !tags.isEmpty, tags.isDisjoint(with: Set(item.tags)) { return false }
        return true
    }
}

struct FilterSheetView: View {
    let allTags: [String]
    let allSources: [String]
    @Binding var filter: FilterState

    @Environment(\.dismiss) private var dismiss
    @State private var draft: FilterState

    init(allTags: [String], allSources: [String], filter: Binding<FilterState>) {
        self.allTags = allTags
        self.allSources = allSources
        self._filter = filter
        self._draft = State(initialValue: filter.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    readStatusSection
                    if !allTags.isEmpty { tagsSection }
                    if !allSources.isEmpty { sourcesSection }
                }
                .padding(20)
            }
            .background(Theme.bg)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear", role: .destructive) { draft = FilterState() }
                        .tint(Theme.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") { filter = draft; dismiss() }
                        .fontWeight(.semibold)
                        .tint(Theme.teal)
                }
            }
            .safeAreaInset(edge: .bottom) { bottomActions }
        }
    }

    private var readStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("READ STATUS")
            Picker("Read status", selection: $draft.readStatus) {
                ForEach(ReadFilter.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("TAGS")
            FlowLayout {
                ForEach(allTags, id: \.self) { tag in
                    ChoiceChip(label: tag, isOn: draft.tags.contains(tag)) {
                        toggle(tag, in: &draft.tags)
                    }
                }
            }
        }
    }

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("SOURCE")
            FlowLayout {
                ForEach(allSources, id: \.self) { source in
                    ChoiceChip(label: source, isOn: draft.sources.contains(source)) {
                        toggle(source, in: &draft.sources)
                    }
                }
            }
        }
    }

    private var bottomActions: some View {
        HStack(spacing: 10) {
            Button { draft = FilterState() } label: {
                Text("Clear filters").frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 12)
            .background(Theme.pill, in: .rect(cornerRadius: 11))
            .foregroundStyle(Theme.ink)

            Button { filter = draft; dismiss() } label: {
                Text("Apply").fontWeight(.bold).frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 12)
            .background(Theme.teal, in: .rect(cornerRadius: 11))
            .foregroundStyle(.white)
        }
        .padding(16)
        .background(Theme.bg)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(Theme.ink2)
            .kerning(0.5)
    }

    private func toggle(_ value: String, in set: inout Set<String>) {
        if set.contains(value) { set.remove(value) } else { set.insert(value) }
    }
}

/// A pill toggle used for tag/source multi-select.
struct ChoiceChip: View {
    let label: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.footnote)
                .padding(.horizontal, 13)
                .padding(.vertical, 7)
                .background(isOn ? Theme.teal : Theme.card, in: .capsule)
                .foregroundStyle(isOn ? .white : Theme.ink2)
                .overlay(
                    Capsule().stroke(isOn ? Theme.teal : Theme.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
