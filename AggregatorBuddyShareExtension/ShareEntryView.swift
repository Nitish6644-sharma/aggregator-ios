import SwiftUI
import SwiftData

/// Manual metadata form shown inside the Share Extension. Phase 1: purely
/// manual entry — no network calls, no metadata fetching.
struct ShareEntryView: View {
    let initialURL: String
    var onFinish: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [Item]

    @State private var url: String
    @State private var title = ""
    @State private var source = ""
    @State private var tags: [String] = []
    @State private var notes = ""

    private var existingTags: [String] {
        Array(Set(allItems.flatMap(\.tags))).sorted()
    }

    init(initialURL: String, onFinish: @escaping () -> Void) {
        self.initialURL = initialURL
        self.onFinish = onFinish
        self._url = State(initialValue: initialURL)
        self._source = State(initialValue: Item.detectSource(from: initialURL))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("URL") {
                    TextField("URL or shared text", text: $url, axis: .vertical)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(Color(red: 0x2F/255, green: 0x6F/255, blue: 0x5E/255))
                }
                Section("Title") {
                    TextField("Add a title", text: $title)
                }
                Section("Source") {
                    TextField("LinkedIn, YouTube, Article…", text: $source)
                }
                Section("Tags") {
                    TagInputField(tags: $tags, suggestions: existingTags)
                }
                Section("Notes") {
                    TextField("Add a note for later…", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("Save to AggregatorBuddy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onFinish() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        var finalTags = tags
        if let sourceTag = Item.sourceTag(from: trimmedSource), !finalTags.contains(sourceTag) {
            finalTags.insert(sourceTag, at: 0)
        }

        let item = Item(
            url: trimmedURL,
            title: trimmedTitle.isEmpty ? trimmedURL : trimmedTitle,
            source: trimmedSource,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            tags: finalTags
        )
        modelContext.insert(item)
        try? modelContext.save()
        onFinish()
    }
}
