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

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    EmptyStateView()
                } else if filteredItems.isEmpty {
                    NoResultsView()
                } else {
                    feedList
                }
            }
            .background(Theme.bg)
            .navigationTitle("Saved")
            .searchable(text: $searchText, prompt: "Search title, source, notes")
            .toolbar { filterToolbarItem }
            .navigationDestination(item: $selectedItem) { item in
                ItemDetailView(item: item, allTags: allTags)
            }
            .sheet(isPresented: $showingFilter) {
                FilterSheetView(allTags: allTags, allSources: allSources, filter: $filter)
            }
            .alert("Delete this item?", isPresented: deleteAlertBinding) {
                Button("Delete", role: .destructive) {
                    if let item = itemPendingDelete { delete(item) }
                }
                Button("Cancel", role: .cancel) { itemPendingDelete = nil }
            } message: {
                Text("This cannot be undone. The link and its notes will be permanently removed.")
            }
        }
        .tint(Theme.teal)
        .task { await reload() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await reload() } }
        }
        .onChange(of: selectedItem) { _, item in
            // Returning from the detail view (edit/delete) — re-sync the feed
            // so deleted objects aren't rendered stale and edits/sort update.
            if item == nil { refresh() }
        }
    }

    private var feedList: some View {
        List {
            ForEach(filteredItems) { item in
                CardView(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture { open(item) }
                    .onLongPressGesture(minimumDuration: 0.4) { selectedItem = item }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 5, leading: 14, bottom: 5, trailing: 14))
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button { toggleRead(item) } label: {
                            Label(item.isRead ? "Unread" : "Read",
                                  systemImage: item.isRead ? "circle" : "checkmark.circle")
                        }
                        .tint(Theme.teal)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) { itemPendingDelete = item } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
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

    // MARK: - Actions

    private func reload() async {
        refresh()
        await fetchMissingPreviews()
    }

    private func refresh() {
        let descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.dateAdded, order: .reverse)])
        items = (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Fetch-once-and-cache: for items never attempted, fetch a preview image
    /// (and auto-fill an empty title), store it, and mark as attempted so we
    /// never re-fetch on subsequent launches.
    private func fetchMissingPreviews() async {
        let jobs = items.filter { !$0.previewFetchAttempted }.map { ($0.id, $0.url) }
        guard !jobs.isEmpty else { return }

        // Fetch concurrently so shimmers resolve together, then apply results
        // on the main actor.
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
}
