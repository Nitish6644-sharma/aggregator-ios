import SwiftUI
import SwiftData
import UIKit

/// View / edit a single saved item. Tap "Edit" to make every field editable.
struct ItemDetailView: View {
    @Bindable var item: Item
    var allTags: [String] = []

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var isEditing = false
    @State private var showDeleteConfirm = false

    // Edit drafts
    @State private var draftURL = ""
    @State private var draftTitle = ""
    @State private var draftSource = ""
    @State private var draftTags: [String] = []
    @State private var draftNotes = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !isEditing, let data = item.previewImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
                        .clipped()
                        .clipShape(.rect(cornerRadius: 14))
                        .padding(.bottom, 14)
                }

                Text(item.title.isEmpty ? "Untitled" : item.title)
                    .font(.title2.bold())
                    .foregroundStyle(Theme.ink)
                    .padding(.bottom, 8)

                if isEditing {
                    editFields
                } else {
                    readOnlyFields
                    actionButtons
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .background(Theme.bg)
        .navigationTitle("Saved")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isEditing {
                    Button("Save") { saveEdits() }.fontWeight(.semibold).tint(Theme.teal)
                } else {
                    Button("Edit") { beginEditing() }.tint(Theme.teal)
                }
            }
            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isEditing = false }.tint(Theme.ink2)
                }
            }
        }
        .alert("Delete this item?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { deleteItem() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone. The link and its notes will be permanently removed.")
        }
    }

    // MARK: - Read-only

    private var readOnlyFields: some View {
        VStack(alignment: .leading, spacing: 0) {
            detailRow("URL") {
                Text(item.url).font(.subheadline).foregroundStyle(Theme.teal)
            }
            if !item.source.isEmpty {
                detailRow("Source") {
                    Text(item.source).font(.subheadline).foregroundStyle(Theme.ink)
                }
            }
            if !item.tags.isEmpty {
                detailRow("Tags") {
                    FlowLayout(spacing: 6) {
                        ForEach(item.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .foregroundStyle(Theme.ink2)
                                .padding(.horizontal, 9).padding(.vertical, 4)
                                .background(Theme.pill, in: .capsule)
                        }
                    }
                }
            }
            if let notes = item.notes, !notes.isEmpty {
                detailRow("Notes") {
                    Text(notes).font(.subheadline).foregroundStyle(Theme.ink2)
                }
            }
            detailRow("Added") {
                Text("\(item.dateAdded.cardFormatted) · \(item.isRead ? "Read" : "Unread")")
                    .font(.subheadline).foregroundStyle(Theme.ink)
            }
        }
    }

    private func detailRow<Content: View>(_ key: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(key.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.ink2)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.line).frame(height: 1) }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button { openLink() } label: {
                Text("Open Link").fontWeight(.bold).frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 12)
            .background(Theme.teal, in: .rect(cornerRadius: 11))
            .foregroundStyle(.white)

            Button { showDeleteConfirm = true } label: {
                Text("Delete Item").fontWeight(.bold).frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 12)
            .background(Theme.redTint, in: .rect(cornerRadius: 11))
            .foregroundStyle(Theme.red)
        }
        .padding(.top, 16)
    }

    // MARK: - Edit

    private var editFields: some View {
        VStack(alignment: .leading, spacing: 14) {
            editField("URL", text: $draftURL)
            editField("Title", text: $draftTitle)
            editField("Source", text: $draftSource)
            VStack(alignment: .leading, spacing: 5) {
                fieldLabel("Tags")
                TagInputField(tags: $draftTags, suggestions: allTags)
            }
            VStack(alignment: .leading, spacing: 5) {
                fieldLabel("Notes")
                TextField("Add a note…", text: $draftNotes, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.plain)
                    .padding(11)
                    .background(Theme.pill, in: .rect(cornerRadius: 9))
            }
        }
    }

    private func editField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            fieldLabel(label)
            TextField(label, text: text)
                .textFieldStyle(.plain)
                .autocorrectionDisabled(label.hasPrefix("URL") || label.hasPrefix("Tags"))
                .textInputAutocapitalization(label.hasPrefix("URL") || label.hasPrefix("Tags") ? .never : .sentences)
                .padding(11)
                .background(Theme.pill, in: .rect(cornerRadius: 9))
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Theme.ink2)
    }

    // MARK: - Actions

    private func beginEditing() {
        draftURL = item.url
        draftTitle = item.title
        draftSource = item.source
        draftTags = item.tags
        draftNotes = item.notes ?? ""
        isEditing = true
    }

    private func saveEdits() {
        item.url = draftURL.trimmingCharacters(in: .whitespacesAndNewlines)
        item.title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        item.source = draftSource.trimmingCharacters(in: .whitespacesAndNewlines)
        item.tags = draftTags
        let trimmedNotes = draftNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        item.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        try? modelContext.save()
        isEditing = false
    }

    private func openLink() {
        guard let url = LinkOpener.url(from: item.url) else { return }
        item.isRead = true
        try? modelContext.save()
        openURL(url)
    }

    private func deleteItem() {
        modelContext.delete(item)
        try? modelContext.save()
        dismiss()
    }
}
