import SwiftUI

// MARK: - Asset detail pane (center pane for Assets section)

struct AssetDetailPane: View {
    @Binding var studios: [MockStudio]
    @Binding var selectedItem: CastingItem?
    @Binding var libraryRefreshToken: UUID
    @Binding var generationQueue: [GenerationJob]
    let studioIndex: Int
    let customerIndex: Int
    let episodeIndex: Int

    /// The item currently being edited (either selected from library or a new blank one).
    @State private var editingItem: CastingItem? = nil
    /// Snapshot of the item when it was loaded from the library, for dirty tracking.
    @State private var originalItem: CastingItem? = nil
    /// Tracks whether we initialized the default blank form.
    @State private var didInitialize = false
    /// When true, the editing item was loaded from the library and can be updated in place.
    @State private var isEditingLibraryItem = false

    private var displayItem: Binding<CastingItem>? {
        if editingItem != nil {
            return Binding(
                get: { editingItem! },
                set: { editingItem = $0 }
            )
        }
        return nil
    }

    /// The name must not be empty for Add to Library.
    private var canAddToLibrary: Bool {
        guard let item = editingItem else { return false }
        return !item.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Accept Changes is enabled only when a field was actually edited (dirty).
    private var canAcceptChanges: Bool {
        guard let item = editingItem, let original = originalItem else { return false }
        return !item.contentEquals(original)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack(spacing: 12) {
                Image(systemName: "photo.stack")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Asset")
                    .font(.title2.bold())
                if let item = editingItem {
                    Text("— \(item.name.isEmpty ? "Untitled" : item.name)")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // New Character
                Button {
                    createNewItem(type: .character)
                } label: {
                    Label("New Character", systemImage: "person.fill.badge.plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                // New Location
                Button {
                    createNewItem(type: .location)
                } label: {
                    Label("New Location", systemImage: "mappin.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                // Add to Library / Accept Changes
                if isEditingLibraryItem {
                    Button {
                        acceptChanges()
                    } label: {
                        Label("Accept Changes", systemImage: "checkmark.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(!canAcceptChanges)
                } else {
                    Button {
                        addToLibrary()
                    } label: {
                        Label("Add to Library", systemImage: "plus.rectangle.on.folder")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(!canAddToLibrary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // Detail content
            if let binding = displayItem {
                CastingItemDetailView(
                    item: binding,
                    generationQueue: $generationQueue,
                    onLevelChange: handleLevelChange,
                    onMoveToNextEpisode: handleMoveToNextEpisode
                )
            } else {
                ContentUnavailableView(
                    "No asset",
                    systemImage: "square.dashed",
                    description: Text("Create a new character or location, or select one from the library.")
                )
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            if !didInitialize {
                createNewItem(type: .character)
                didInitialize = true
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            if let newItem {
                editingItem = newItem
                originalItem = newItem
                isEditingLibraryItem = true
            }
        }
    }

    private func createNewItem(type: CastingItemType) {
        let newID = UUID().uuidString
        editingItem = CastingItem(
            id: newID,
            name: "",
            description: "",
            type: type,
            gender: type == .character ? .male : nil,
            locationSetting: type == .location ? .interior : nil,
            status: .nothingGenerated,
            libraryLevel: .episode,
            variants: CastingItem.emptyVariants(prefix: newID)
        )
        originalItem = nil
        selectedItem = nil
        isEditingLibraryItem = false
    }

    private func addToLibrary() {
        guard let item = editingItem,
              studios.indices.contains(studioIndex) else { return }
        let customers = studios[studioIndex].customers
        guard customers.indices.contains(customerIndex) else { return }
        let episodes = customers[customerIndex].episodes
        guard episodes.indices.contains(episodeIndex) else { return }

        // Add to episode level
        if item.type == .character {
            studios[studioIndex].customers[customerIndex].episodes[episodeIndex].characters.append(item)
        } else {
            studios[studioIndex].customers[customerIndex].episodes[episodeIndex].locations.append(item)
        }

        // Switch to editing mode for the newly added item
        selectedItem = item
        originalItem = item
        isEditingLibraryItem = true
        libraryRefreshToken = UUID()
    }

    /// Writes the edited item back into its position in the library tree.
    private func acceptChanges() {
        guard let item = editingItem else { return }
        updateItemInStudios(item)
        // Update the snapshot so the button disables again until further edits
        originalItem = item
        libraryRefreshToken = UUID()
    }

    /// Handles a library level change (promote/demote) by moving the item
    /// in the studios tree and refreshing the library view.
    private func handleLevelChange(newLevel: LibraryLevel) {
        guard var item = editingItem else { return }
        let oldLevel = item.libraryLevel

        // Remove from current position in the tree
        removeItemFromStudios(id: item.id)

        // Update the level
        item.libraryLevel = newLevel

        // Insert at the new level in the tree
        insertItemAtLevel(item, level: newLevel, oldLevel: oldLevel)

        // Update local state
        editingItem = item
        originalItem = item
        selectedItem = item
        libraryRefreshToken = UUID()
    }

    /// Moves an episode-level item to the next episode within the same customer.
    private func handleMoveToNextEpisode() {
        guard let item = editingItem else { return }
        guard studios.indices.contains(studioIndex),
              studios[studioIndex].customers.indices.contains(customerIndex) else { return }

        let episodes = studios[studioIndex].customers[customerIndex].episodes

        // Find which episode currently holds this item
        var sourceEpisodeIndex: Int? = nil
        for ei in episodes.indices {
            let hasChar = episodes[ei].characters.contains { $0.id == item.id }
            let hasLoc = episodes[ei].locations.contains { $0.id == item.id }
            if hasChar || hasLoc {
                sourceEpisodeIndex = ei
                break
            }
        }

        guard let srcEI = sourceEpisodeIndex else { return }
        let nextEI = srcEI + 1

        // If there is no next episode, wrap around to the first
        let targetEI = episodes.indices.contains(nextEI) ? nextEI : 0
        // Don't move if source and target are the same (only one episode)
        guard targetEI != srcEI else { return }

        // Remove from source episode
        if let idx = studios[studioIndex].customers[customerIndex].episodes[srcEI].characters.firstIndex(where: { $0.id == item.id }) {
            studios[studioIndex].customers[customerIndex].episodes[srcEI].characters.remove(at: idx)
        } else if let idx = studios[studioIndex].customers[customerIndex].episodes[srcEI].locations.firstIndex(where: { $0.id == item.id }) {
            studios[studioIndex].customers[customerIndex].episodes[srcEI].locations.remove(at: idx)
        }

        // Insert into target episode
        if item.type == .character {
            studios[studioIndex].customers[customerIndex].episodes[targetEI].characters.append(item)
        } else {
            studios[studioIndex].customers[customerIndex].episodes[targetEI].locations.append(item)
        }

        // Update local state
        editingItem = item
        originalItem = item
        selectedItem = item
        libraryRefreshToken = UUID()
    }

    /// Removes an item by ID from wherever it lives in the studios tree.
    private func removeItemFromStudios(id: String) {
        for si in studios.indices {
            if let idx = studios[si].characters.firstIndex(where: { $0.id == id }) {
                studios[si].characters.remove(at: idx); return
            }
            if let idx = studios[si].locations.firstIndex(where: { $0.id == id }) {
                studios[si].locations.remove(at: idx); return
            }
            for ci in studios[si].customers.indices {
                for ei in studios[si].customers[ci].episodes.indices {
                    if let idx = studios[si].customers[ci].episodes[ei].characters.firstIndex(where: { $0.id == id }) {
                        studios[si].customers[ci].episodes[ei].characters.remove(at: idx); return
                    }
                    if let idx = studios[si].customers[ci].episodes[ei].locations.firstIndex(where: { $0.id == id }) {
                        studios[si].customers[ci].episodes[ei].locations.remove(at: idx); return
                    }
                }
            }
        }
    }

    /// Inserts an item at the target level in the studios tree.
    private func insertItemAtLevel(_ item: CastingItem, level: LibraryLevel, oldLevel: LibraryLevel) {
        guard studios.indices.contains(studioIndex) else { return }

        switch level {
        case .studio:
            if item.type == .character {
                studios[studioIndex].characters.append(item)
            } else {
                studios[studioIndex].locations.append(item)
            }
        case .customer:
            guard studios[studioIndex].customers.indices.contains(customerIndex) else { return }
            // Customer-level items are stored in the first episode of this customer
            // (they're filtered by libraryLevel in the library view)
            guard let firstEpisodeIndex = studios[studioIndex].customers[customerIndex].episodes.indices.first else { return }
            if item.type == .character {
                studios[studioIndex].customers[customerIndex].episodes[firstEpisodeIndex].characters.append(item)
            } else {
                studios[studioIndex].customers[customerIndex].episodes[firstEpisodeIndex].locations.append(item)
            }
        case .episode:
            guard studios[studioIndex].customers.indices.contains(customerIndex) else { return }
            let episodes = studios[studioIndex].customers[customerIndex].episodes
            guard episodes.indices.contains(episodeIndex) else { return }
            if item.type == .character {
                studios[studioIndex].customers[customerIndex].episodes[episodeIndex].characters.append(item)
            } else {
                studios[studioIndex].customers[customerIndex].episodes[episodeIndex].locations.append(item)
            }
        }
    }

    /// Recursively finds the item by ID in the studios tree and replaces it.
    private func updateItemInStudios(_ item: CastingItem) {
        for si in studios.indices {
            // Studio-level
            if let idx = studios[si].characters.firstIndex(where: { $0.id == item.id }) {
                studios[si].characters[idx] = item; return
            }
            if let idx = studios[si].locations.firstIndex(where: { $0.id == item.id }) {
                studios[si].locations[idx] = item; return
            }
            for ci in studios[si].customers.indices {
                for ei in studios[si].customers[ci].episodes.indices {
                    if let idx = studios[si].customers[ci].episodes[ei].characters.firstIndex(where: { $0.id == item.id }) {
                        studios[si].customers[ci].episodes[ei].characters[idx] = item; return
                    }
                    if let idx = studios[si].customers[ci].episodes[ei].locations.firstIndex(where: { $0.id == item.id }) {
                        studios[si].customers[ci].episodes[ei].locations[idx] = item; return
                    }
                }
            }
        }
    }
}
