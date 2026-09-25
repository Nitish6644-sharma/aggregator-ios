import SwiftUI
import SwiftData

struct HomeFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    @State private var items: [Item] = []
    @State private var searchText = ""
    @State private var filter = FilterState()
    @State private var showingFilter = false
    @State private var selectedItem: Item?
    @State private var itemPendingDelete: Item?

    // Multi-select state
    @State private var isEditing = false
    @State private var selectedIDs: Set<UUID> = []
    @State private var showingBatchDeleteAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !allSources.isEmpty {
                    sourceChipsRow
                }
                if items.isEmpty {
                    EmptyStateView()
                } else if filteredItems.isEmpty {
                    NoResultsView()
                } else {
                    feedList
                }
            }
            .background(Theme.bg)
            .navigationTitle(isEditing
                ? (selectedIDs.isEmpty ? "Select Items" : "\(selectedIDs.count) Selected")
                : "Saved")
            .navigationBarTitleDisplayMode(isEditing ? .inline : .large)
            .searchable(text: $searchText, prompt: "Search title, source, notes")
            .toolbar { toolbarContent }
            .navigationDestination(item: $selectedItem) { item in
                ItemDetailView(item: item, allTags: allTags)
            }
            .sheet(isPresented: $showingFilter) {
                FilterSheetView(allTags: allTags, filter: $filter)
            }
            .alert("Delete this item?", isPresented: deleteAlertBinding) {
                Button("Delete", role: .destructive) {
                    if let item = itemPendingDelete { delete(item) }
                }
                Button("Cancel", role: .cancel) { itemPendingDelete = nil }
            } message: {
                Text("This cannot be undone. The link and its notes will be permanently removed.")
            }
            .alert(batchDeleteTitle, isPresented: $showingBatchDeleteAlert) {
                Button("Delete", role: .destructive) { batchDelete() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
        }
        .tint(Theme.teal)
        .task { await reload() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await reload() } }
        }
        .onChange(of: selectedItem) { _, item in
            if item == nil { refresh() }
        }
    }

    private var feedList: some View {
        List {
            ForEach(filteredItems) { item in
                CardView(item: item, isEditing: isEditing, isSelected: selectedIDs.contains(item.id))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isEditing {
                            toggleSelection(item)
                        } else {
                            open(item)
                        }
                    }
                    .onLongPressGesture(minimumDuration: 0.4) {
                        if !isEditing { selectedItem = item }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 5, leading: 14, bottom: 5, trailing: 14))
                    .swipeActions(edge: .leading, allowsFullSwipe: !isEditing) {
                        if !isEditing {
                            Button { toggleRead(item) } label: {
                                Label(item.isRead ? "Unread" : "Read",
                                      systemImage: item.isRead ? "circle" : "checkmark.circle")
                            }
                            .tint(Theme.teal)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if !isEditing {
                            Button(role: .destructive) { itemPendingDelete = item } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isEditing {
            // Leading: Select All / Deselect All
            ToolbarItem(placement: .topBarLeading) {
                let allSelected = !filteredItems.isEmpty && selectedIDs.count == filteredItems.count
                Button(allSelected ? "Deselect All" : "Select All") {
                    withAnimation {
                        if allSelected {
                            selectedIDs.removeAll()
                        } else {
                            selectedIDs = Set(filteredItems.map(\.id))
                        }
                    }
                }
            }
            // Trailing: Done
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditing = false
                        selectedIDs.removeAll()
                    }
                }
                .fontWeight(.semibold)
            }
            // Bottom bar batch actions
            ToolbarItemGroup(placement: .bottomBar) {
                Button(role: .destructive) {
                    showingBatchDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(selectedIDs.isEmpty)

                Spacer()

                Button { batchMarkRead() } label: {
                    Label("Mark Read", systemImage: "checkmark.circle")
                }
                .disabled(selectedIDs.isEmpty)

                Spacer()

                Button { batchMarkUnread() } label: {
                    Label("Mark Unread", systemImage: "circle")
                }
                .disabled(selectedIDs.isEmpty)
            }
        } else {
            // Normal mode: Edit trailing + filter trailing
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditing = true
                    }
                }
            }
            filterToolbarItem
        }
    }

    private var filterToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showingFilter = true } label: {
                Image(systemName: "line.3.horizontal.decrease.circle\(filter.isActive ? ".fill" : "")")
                    .overlay(alignment: .topTrailing) {
                        if filter.activeCount > 0 {
                            Text("\(filter.activeCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(3)
                                .background(Theme.teal, in: .circle)
                                .offset(x: 6, y: -6)
                        }
                    }
            }
        }
    }

    // MARK: - Source chips

    private var sourceChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(allSources, id: \.self) { source in
                    ChoiceChip(label: source, isOn: filter.sources.contains(source)) {
                        if filter.sources.contains(source) {
                            filter.sources.remove(source)
                        } else {
                            filter.sources.insert(source)
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(Theme.bg)
    }

    // MARK: - Derived data

    private var filteredItems: [Item] {
        items.filter { item in
            filter.matches(item) && matchesSearch(item)
        }
    }

    private func matchesSearch(_ item: Item) -> Bool {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return true }
        return item.title.localizedCaseInsensitiveContains(q)
            || item.source.localizedCaseInsensitiveContains(q)
            || (item.notes?.localizedCaseInsensitiveContains(q) ?? false)
    }

    private var allTags: [String] {
        Array(Set(items.flatMap(\.tags))).sorted()
    }

    private var allSources: [String] {
        Array(Set(items.map(\.source).filter { !$0.isEmpty })).sorted()
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(get: { itemPendingDelete != nil }, set: { if !$0 { itemPendingDelete = nil } })
    }

    private var batchDeleteTitle: String {
        "Delete \(selectedIDs.count) item\(selectedIDs.count == 1 ? "" : "s")?"
    }

    // MARK: - Actions

    private func toggleSelection(_ item: Item) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if selectedIDs.contains(item.id) {
                selectedIDs.remove(item.id)
            } else {
                selectedIDs.insert(item.id)
            }
        }
    }

    private func reload() async {
        refresh()
        await fetchMissingPreviews()
    }

    private func refresh() {
        let descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.dateAdded, order: .reverse)])
        items = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchMissingPreviews() async {
        let jobs = items.filter { !$0.previewFetchAttempted }.map { ($0.id, $0.url) }
        guard !jobs.isEmpty else { return }

        await withTaskGroup(of: (UUID, LinkPreviewFetcher.Result).self) { group in
            for (id, url) in jobs {
                group.addTask { (id, await LinkPreviewFetcher.fetch(url)) }
            }
            for await (id, result) in group {
                guard let item = items.first(where: { $0.id == id }) else { continue }
                item.previewFetchAttempted = true
                if let data = result.imageData {
                    item.previewImageData = data
                }
                if let fetchedTitle = result.title, !fetchedTitle.isEmpty,
                   item.title.isEmpty || item.title == item.url {
                    item.title = fetchedTitle
                }
                try? modelContext.save()
            }
        }
    }

    private func open(_ item: Item) {
        guard let url = LinkOpener.url(from: item.url) else { return }
        item.isRead = true
        try? modelContext.save()
        openURL(url)
    }

    private func toggleRead(_ item: Item) {
        item.isRead.toggle()
        try? modelContext.save()
    }

    private func delete(_ item: Item) {
        modelContext.delete(item)
        try? modelContext.save()
        items.removeAll { $0.id == item.id }
        itemPendingDelete = nil
    }

    // MARK: - Batch actions

    private func batchDelete() {
        let targets = items.filter { selectedIDs.contains($0.id) }
        targets.forEach { modelContext.delete($0) }
        try? modelContext.save()
        items.removeAll { selectedIDs.contains($0.id) }
        selectedIDs.removeAll()
        withAnimation { isEditing = false }
    }

    private func batchMarkRead() {
        items.filter { selectedIDs.contains($0.id) }.forEach { $0.isRead = true }
        try? modelContext.save()
        selectedIDs.removeAll()
        withAnimation { isEditing = false }
    }

    private func batchMarkUnread() {
        items.filter { selectedIDs.contains($0.id) }.forEach { $0.isRead = false }
        try? modelContext.save()
        selectedIDs.removeAll()
        withAnimation { isEditing = false }
    }
}
