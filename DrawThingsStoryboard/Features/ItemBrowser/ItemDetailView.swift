import SwiftUI

/// Right pane — switches between project detail and generic detail.
struct ItemDetailView: View {

    let section: AppSection?

    // Project hierarchy (mutable for editing name/rules)
    @Binding var studios: [MockStudio]
    let selectedStudioID: String?
    let selectedCustomerID: String?
    let selectedEpisodeID: String?
    let selectedBriefingLevel: BriefingLevel

    // Generic
    let selectedItemID: String?

    // Looks (templates) for Preferred Look display
    let templates: [GenerationTemplate]

    var body: some View {
        switch section {
        case .projects:
            BriefingDetailView(
                studios: $studios,
                selectedStudioID: selectedStudioID,
                selectedCustomerID: selectedCustomerID,
                selectedEpisodeID: selectedEpisodeID,
                level: selectedBriefingLevel,
                templates: templates
            )
        default:
            if let itemID = selectedItemID,
               let item = MockData.items(for: section).first(where: { $0.id == itemID }) {
                GenericDetailView(item: item)
            } else {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nothing selected",
            systemImage: "square.dashed",
            description: Text("Select an item to see its properties.")
        )
    }
}

// MARK: - Briefing detail

/// Shows Name and Rules for the selected Studio, Customer, or Episode.
struct BriefingDetailView: View {

    @Binding var studios: [MockStudio]
    let selectedStudioID: String?
    let selectedCustomerID: String?
    let selectedEpisodeID: String?
    let level: BriefingLevel
    let templates: [GenerationTemplate]

    // MARK: - Index helpers

    private var studioIndex: Int? {
        studios.firstIndex { $0.id == selectedStudioID }
    }
    private var customerIndex: Int? {
        guard let si = studioIndex else { return nil }
        return studios[si].customers.firstIndex { $0.id == selectedCustomerID }
    }
    private var episodeIndex: Int? {
        guard let si = studioIndex, let ci = customerIndex else { return nil }
        return studios[si].customers[ci].episodes.firstIndex { $0.id == selectedEpisodeID }
    }

    // MARK: - Bindings into the correct level

    private var nameBinding: Binding<String> {
        switch level {
        case .studio:
            guard let si = studioIndex else { return .constant("") }
            return $studios[si].name
        case .customer:
            guard let si = studioIndex, let ci = customerIndex else { return .constant("") }
            return $studios[si].customers[ci].name
        case .episode:
            guard let si = studioIndex, let ci = customerIndex, let ei = episodeIndex else { return .constant("") }
            return $studios[si].customers[ci].episodes[ei].name
        }
    }

    private var rulesBinding: Binding<String> {
        switch level {
        case .studio:
            guard let si = studioIndex else { return .constant("") }
            return $studios[si].rules
        case .customer:
            guard let si = studioIndex, let ci = customerIndex else { return .constant("") }
            return $studios[si].customers[ci].rules
        case .episode:
            guard let si = studioIndex, let ci = customerIndex, let ei = episodeIndex else { return .constant("") }
            return $studios[si].customers[ci].episodes[ei].rules
        }
    }

    private var themeColor: Color {
        switch level {
        case .studio:   return .purple
        case .customer: return .teal
        case .episode:  return .blue
        }
    }

    // MARK: - Episode characters & locations bindings

    private var charactersBinding: Binding<[CastingItem]>? {
        guard level == .episode,
              let si = studioIndex, let ci = customerIndex, let ei = episodeIndex else { return nil }
        return $studios[si].customers[ci].episodes[ei].characters
    }

    private var locationsBinding: Binding<[CastingItem]>? {
        guard level == .episode,
              let si = studioIndex, let ci = customerIndex, let ei = episodeIndex else { return nil }
        return $studios[si].customers[ci].episodes[ei].locations
    }

    private var preferredLookID: String? {
        guard level == .episode,
              let si = studioIndex, let ci = customerIndex, let ei = episodeIndex else { return nil }
        return studios[si].customers[ci].episodes[ei].preferredLookID
    }

    private var preferredLook: GenerationTemplate? {
        guard let lookID = preferredLookID else { return nil }
        return templates.first { $0.id == lookID }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Type badge header
                BriefingTypeHeader(level: level, color: themeColor)

                Divider().padding(.vertical, 8)

                // Name
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Name")
                    TextField("Name", text: nameBinding)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.bottom, 16)

                // Rules
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Rules")
                    Text("Prompt fragment applied to all images at this level.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    TextEditor(text: rulesBinding)
                        .font(.callout)
                        .frame(minHeight: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
                        )
                }
                .padding(.bottom, 16)

                // Preferred Look (only shown for Episode level)
                if level == .episode {
                    Divider().padding(.bottom, 12)
                    PreferredLookSection(look: preferredLook)
                }

                // Cast & Locations (only shown for Episode level)
                if let characters = charactersBinding,
                   let locations = locationsBinding {
                    Divider().padding(.bottom, 12)
                    EpisodeCastSection(
                        characters: characters,
                        locations: locations
                    )
                }

                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Briefing type header

private struct BriefingTypeHeader: View {
    let level: BriefingLevel
    let color: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.12))
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .overlay {
                    Image(systemName: level.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(color.opacity(0.6))
                }
            Text(level.label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial, in: Capsule())
                .foregroundStyle(.secondary)
                .padding(10)
        }
    }
}

// MARK: - Preferred Look (read-only template display)

private struct PreferredLookSection: View {
    let look: GenerationTemplate?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Preferred Look")
            if let look {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(look.jobType.color.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: look.jobType.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(look.jobType.color)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(look.name)
                            .font(.callout.weight(.medium))
                        Text(look.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.accentColor.opacity(0.07))
                )
            } else {
                Text("No look assigned")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 4)
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Episode cast & locations (embedded in briefing detail)

private struct EpisodeCastSection: View {
    @Binding var characters: [CastingItem]
    @Binding var locations: [CastingItem]

    private let columns = [GridItem(.adaptive(minimum: 90, maximum: 120), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Characters
            EpisodeCastSubSection(
                title: "Cast",
                items: $characters,
                itemType: .character,
                columns: columns
            )

            Divider().padding(.vertical, 8)

            // Locations
            EpisodeCastSubSection(
                title: "Locations",
                items: $locations,
                itemType: .location,
                columns: columns
            )
        }
    }
}

private struct EpisodeCastSubSection: View {
    let title: String
    @Binding var items: [CastingItem]
    let itemType: CastingItemType
    let columns: [GridItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel(title)

            if items.isEmpty {
                Text("No \(title.lowercased()) yet.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 12)
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(items) { item in
                        EpisodeCastTileView(
                            item: item,
                            onDelete: {
                                if let idx = items.firstIndex(where: { $0.id == item.id }) {
                                    items.remove(at: idx)
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }
}

private struct EpisodeCastTileView: View {
    let item: CastingItem
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(tileColor.opacity(0.15))
                    .frame(height: 56)
                    .overlay {
                        Image(systemName: tileIcon)
                            .font(.system(size: 20))
                            .foregroundStyle(tileColor)
                    }

                // Status dot — bottom trailing
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(item.status.color)
                            .frame(width: 6, height: 6)
                            .padding(4)
                    }
                }

                // Delete button — top trailing
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            onDelete?()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .secondary)
                        }
                        .buttonStyle(.plain)
                        .padding(2)
                    }
                    Spacer()
                }
            }

            Text(item.name)
                .font(.caption2)
                .lineLimit(1)
        }
    }

    private var tileColor: Color {
        item.type == .character ? .blue : .teal
    }

    private var tileIcon: String {
        if item.type == .character {
            return item.gender?.icon ?? "person.fill"
        } else {
            return item.locationSetting?.icon ?? "map"
        }
    }
}

// MARK: - Asset detail pane (center pane for Assets section)

struct AssetDetailPane: View {
    @Binding var studios: [MockStudio]
    @Binding var selectedItem: CastingItem?
    @Binding var libraryRefreshToken: UUID
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

// MARK: - Casting detail (used by Assets)

struct CastingItemDetailView: View {
    @Binding var item: CastingItem
    /// Called when the user promotes or demotes the library level.
    var onLevelChange: ((LibraryLevel) -> Void)? = nil
    /// Called when the user moves an episode-level item to the next episode.
    var onMoveToNextEpisode: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ThumbnailSection(item: item)
                StatusSection(item: $item)
                Divider().padding(.vertical, 8)
                LibraryLevelSection(item: $item, onLevelChange: onLevelChange, onMoveToNextEpisode: onMoveToNextEpisode)
                Divider().padding(.vertical, 8)
                NameSection(item: $item)
                // Read-only type indicator
                AssetTypeIndicator(type: item.type)
                if item.type == .character {
                    GenderSection(item: $item)
                } else {
                    LocationSettingSection(item: $item)
                }
                DescriptionSection(item: $item)
                Divider().padding(.vertical, 8)
                VariantsSection(item: $item)
                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Asset type indicator (read-only)

private struct AssetTypeIndicator: View {
    let type: CastingItemType

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Type")
            HStack(spacing: 6) {
                Image(systemName: type == .character ? "person.fill" : "map")
                    .foregroundStyle(type == .character ? .blue : .teal)
                    .frame(width: 16)
                Text(type == .character ? "Character" : "Location")
                    .font(.callout)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.accentColor.opacity(0.07))
            )
        }
        .padding(.bottom, 12)
    }
}

// MARK: - ThumbnailSection

private struct ThumbnailSection: View {
    let item: CastingItem
    private var typeLabel: String     { item.type == .character ? "Character" : "Location" }
    private var thumbnailColor: Color { item.type == .character ? .blue : .teal }
    private var thumbnailIcon: String {
        if item.type == .character {
            return item.gender?.icon ?? "person.fill"
        } else {
            return item.locationSetting?.icon ?? "map"
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(thumbnailColor.opacity(0.12))
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .overlay {
                    Image(systemName: thumbnailIcon)
                        .font(.system(size: 52))
                        .foregroundStyle(thumbnailColor.opacity(0.6))
                }
            Text(typeLabel)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial, in: Capsule())
                .foregroundStyle(.secondary)
                .padding(10)
        }
        .padding(.bottom, 16)
    }
}

// MARK: - StatusSection (compact: single-line + context-dependent action)

private struct StatusSection: View {
    @Binding var item: CastingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Status")
            HStack(spacing: 8) {
                Circle()
                    .fill(item.status.color)
                    .frame(width: 8, height: 8)
                Text(item.status.label)
                    .font(.callout)
                Spacer()
                statusAction
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.accentColor.opacity(0.07))
            )
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var statusAction: some View {
        switch item.status {
        case .nothingGenerated:
            Button {
                // TODO: trigger variant generation
            } label: {
                Label("Generate Variants", systemImage: "play.circle")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        case .variantsGenerated:
            Text("Approve a variant below")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .variantApproved:
            Button {
                // TODO: trigger final generation
            } label: {
                Label("Generate Final", systemImage: "checkmark.circle")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        case .finalGenerated:
            EmptyView()
        }
    }
}

// MARK: - LibraryLevelSection (promote + demote buttons)

private struct LibraryLevelSection: View {
    @Binding var item: CastingItem
    /// Called when the user promotes or demotes — the parent handles the actual tree move.
    var onLevelChange: ((LibraryLevel) -> Void)? = nil
    /// Called when the user moves an episode-level item to the next episode.
    var onMoveToNextEpisode: (() -> Void)? = nil

    /// The next higher library level, or nil if already at studio.
    private var promoteLevel: LibraryLevel? {
        switch item.libraryLevel {
        case .episode:  return .customer
        case .customer: return .studio
        case .studio:   return nil
        }
    }

    private var promoteLabel: String {
        guard let level = promoteLevel else { return "" }
        return "Promote to \(level.rawValue)"
    }

    /// The next lower library level label.
    private var demoteLabel: String {
        switch item.libraryLevel {
        case .studio:   return "Move to Customer"
        case .customer: return "Move to Episode"
        case .episode:  return "Move to next Episode"
        }
    }

    /// The level to demote to, or nil if already at episode (special case: move to next episode).
    private var demoteLevel: LibraryLevel? {
        switch item.libraryLevel {
        case .studio:   return .customer
        case .customer: return .episode
        case .episode:  return nil  // special: stays episode, moves to next
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Library level")
            HStack(spacing: 8) {
                Image(systemName: item.libraryLevel.icon)
                    .frame(width: 16)
                    .foregroundStyle(.secondary)
                Text(item.libraryLevel.rawValue)
                    .font(.callout)
                Spacer()
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.accentColor.opacity(0.07))
            )

            // Promote / Demote buttons
            HStack(spacing: 6) {
                // Demote button
                Button {
                    if let level = demoteLevel {
                        onLevelChange?(level)
                    } else {
                        // Episode → next episode: stays at .episode
                        onMoveToNextEpisode?()
                    }
                } label: {
                    Label(demoteLabel, systemImage: "arrow.down.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)

                // Promote button (only if not already at studio)
                if let level = promoteLevel {
                    Button {
                        onLevelChange?(level)
                    } label: {
                        Label(promoteLabel, systemImage: "arrow.up.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
        }
        .padding(.bottom, 12)
    }
}

// MARK: - GenderSection

private struct GenderSection: View {
    @Binding var item: CastingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Gender")
            Picker("Gender", selection: Binding(
                get: { item.gender ?? .male },
                set: { item.gender = $0 }
            )) {
                ForEach(CharacterGender.allCases, id: \.rawValue) { g in
                    Label(g.label, systemImage: g.icon).tag(g)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.bottom, 12)
    }
}

// MARK: - LocationSettingSection

private struct LocationSettingSection: View {
    @Binding var item: CastingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Setting")
            Picker("Setting", selection: Binding(
                get: { item.locationSetting ?? .interior },
                set: { item.locationSetting = $0 }
            )) {
                ForEach(LocationSetting.allCases, id: \.rawValue) { s in
                    Label(s.label, systemImage: s.icon).tag(s)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.bottom, 12)
    }
}

// MARK: - NameSection

private struct NameSection: View {
    @Binding var item: CastingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Name")
            TextField("Name", text: $item.name)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.bottom, 12)
    }
}

// MARK: - DescriptionSection

private struct DescriptionSection: View {
    @Binding var item: CastingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Description")
            TextEditor(text: $item.description)
                .font(.callout)
                .frame(minHeight: 72)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
                )
        }
        .padding(.bottom, 12)
    }
}

// MARK: - VariantsSection (4 variant thumbnails with approve / delete)

private struct VariantsSection: View {
    @Binding var item: CastingItem

    private var placeholderIcon: String {
        if item.type == .character {
            return item.gender?.icon ?? "person.fill"
        } else {
            return item.locationSetting?.icon ?? "map"
        }
    }

    private var themeColor: Color {
        item.type == .character ? .blue : .teal
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Variants")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(0..<4, id: \.self) { idx in
                    variantTile(index: idx)
                }
            }
        }
        .padding(.bottom, 12)
    }

    private func variantTile(index idx: Int) -> some View {
        let variant = item.variants[idx]
        return VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(variant.isGenerated ? themeColor.opacity(0.2) : Color.secondary.opacity(0.08))
                    .frame(height: 72)
                    .overlay {
                        Image(systemName: placeholderIcon)
                            .font(.system(size: 24))
                            .foregroundStyle(variant.isGenerated ? themeColor : Color.secondary.opacity(0.3))
                    }

                // Delete button (top-right) — only if variant is generated
                if variant.isGenerated {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                deleteVariant(at: idx)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 13))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .secondary)
                            }
                            .buttonStyle(.plain)
                            .padding(3)
                        }
                        Spacer()
                    }
                }

                // Approved badge (top-left)
                if variant.isApproved {
                    VStack {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.green)
                                .padding(4)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(variant.isApproved ? Color.green : Color.clear, lineWidth: 1.5)
            )

            // Approve / Disapprove controls — only if variant is generated
            if variant.isGenerated {
                HStack(spacing: 8) {
                    Button {
                        approveVariant(at: idx)
                    } label: {
                        Image(systemName: variant.isApproved ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.caption2)
                            .foregroundStyle(variant.isApproved ? .green : .secondary)
                    }
                    .buttonStyle(.plain)

                    Button {
                        disapproveVariant(at: idx)
                    } label: {
                        Image(systemName: "hand.thumbsdown")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .disabled(!variant.isApproved)
                }
            } else {
                Text("Empty")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
        }
    }

    // MARK: - Actions

    private func approveVariant(at idx: Int) {
        // Clear any existing approval
        for i in 0..<item.variants.count {
            item.variants[i].isApproved = false
        }
        item.variants[idx].isApproved = true
        item.status = .variantApproved
    }

    private func disapproveVariant(at idx: Int) {
        item.variants[idx].isApproved = false
        // If no variant is approved, drop back to variantsGenerated (if all 4 generated)
        if item.approvedIndex == nil {
            item.status = item.generatedCount == 4 ? .variantsGenerated : .nothingGenerated
        }
    }

    private func deleteVariant(at idx: Int) {
        let wasApproved = item.variants[idx].isApproved
        item.variants[idx].isGenerated = false
        item.variants[idx].isApproved = false

        // Recalculate status
        if wasApproved || item.approvedIndex == nil {
            item.status = item.generatedCount == 4 ? .variantsGenerated : .nothingGenerated
        }
    }
}

// MARK: - Production job detail (read-only view of a queued job)

struct ProductionJobDetailView: View {
    let queue: [GenerationJob]
    let selectedJobID: String?

    private var selectedJob: GenerationJob? {
        guard let id = selectedJobID else { return nil }
        return queue.first { $0.id == id }
    }

    var body: some View {
        if let job = selectedJob {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header thumbnail
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(job.jobType.color.opacity(0.12))
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .overlay {
                                Image(systemName: job.itemIcon)
                                    .font(.system(size: 40))
                                    .foregroundStyle(job.jobType.color.opacity(0.6))
                            }
                        Text(job.jobType.rawValue)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.thinMaterial, in: Capsule())
                            .foregroundStyle(.secondary)
                            .padding(10)
                    }
                    .padding(.bottom, 16)

                    // Item name
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Item")
                        HStack(spacing: 6) {
                            Image(systemName: job.itemIcon)
                                .foregroundStyle(job.jobType.color)
                            Text(job.itemName)
                                .font(.callout.weight(.medium))
                        }
                    }
                    .padding(.bottom, 12)

                    Divider().padding(.vertical, 8)

                    // Job type
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Job Type")
                        HStack(spacing: 6) {
                            Image(systemName: job.jobType.icon)
                                .foregroundStyle(job.jobType.color)
                            Text(job.jobType.rawValue)
                                .font(.callout)
                        }
                    }
                    .padding(.bottom, 12)

                    // Look
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Look")
                        Text(job.lookName)
                            .font(.callout)
                    }
                    .padding(.bottom, 12)

                    // Item type
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Item Type")
                        Text(job.itemType == .character ? "Character" : "Location")
                            .font(.callout)
                    }
                    .padding(.bottom, 12)

                    Divider().padding(.vertical, 8)

                    // Timing
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Queued At")
                        Text(job.queuedAt, style: .time)
                            .font(.callout)
                    }
                    .padding(.bottom, 12)

                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Estimated Duration")
                        let mins = Int(job.estimatedDuration) / 60
                        let secs = Int(job.estimatedDuration) % 60
                        Text(mins > 0 ? "\(mins)m \(secs)s" : "\(secs)s")
                            .font(.callout)
                    }
                    .padding(.bottom, 12)

                    Spacer(minLength: 20)
                }
                .padding(14)
            }
            .background(Color(NSColor.windowBackgroundColor))
        } else {
            ContentUnavailableView(
                "No job selected",
                systemImage: "tray",
                description: Text("Select a job from the queue to see its details.")
            )
        }
    }
}

// MARK: - Looks detail (template editor)

struct LooksDetailView: View {
    @Binding var templates: [GenerationTemplate]
    @Binding var selectedTemplateID: String?
    @Binding var generationQueue: [GenerationJob]

    private var selectedIndex: Int? {
        guard let id = selectedTemplateID else { return nil }
        return templates.firstIndex { $0.id == id }
    }

    private func durationString(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 && secs > 0 { return "\(mins)m \(secs)s" }
        if mins > 0 { return "\(mins)m" }
        return "\(secs)s"
    }

    var body: some View {
        if let idx = selectedIndex {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(templates[idx].jobType.color.opacity(0.12))
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .overlay {
                                Image(systemName: templates[idx].jobType.icon)
                                    .font(.system(size: 40))
                                    .foregroundStyle(templates[idx].jobType.color.opacity(0.6))
                            }
                        Text("Look")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.thinMaterial, in: Capsule())
                            .foregroundStyle(.secondary)
                            .padding(10)
                    }
                    .padding(.bottom, 16)

                    // Status
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Status")
                        HStack(spacing: 8) {
                            Circle()
                                .fill(templates[idx].lookStatus.color)
                                .frame(width: 8, height: 8)
                            Text(templates[idx].lookStatus.rawValue)
                                .font(.callout)
                            Spacer()
                            if templates[idx].lookStatus == .noExample {
                                Button {
                                    generateExample(at: idx)
                                } label: {
                                    Label("Generate Example", systemImage: "eye")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(Color.accentColor.opacity(0.07))
                        )
                    }
                    .padding(.bottom, 12)

                    // Name
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Name")
                        TextField("Template name", text: $templates[idx].name)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.bottom, 12)

                    // Description
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Description")
                        TextEditor(text: $templates[idx].description)
                            .font(.callout)
                            .frame(minHeight: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
                            )
                    }
                    .padding(.bottom, 12)

                    Divider().padding(.vertical, 8)

                    // Generation type (exclude generateExample — that's for looks only)
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Generation Type")
                        Picker("Generation Type", selection: $templates[idx].jobType) {
                            Text("Generate Variants").tag(GenerationJobType.generateVariants)
                            Text("Generate Final").tag(GenerationJobType.generateFinal)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.bottom, 12)

                    // Item type
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Item Type")
                        Picker("Item Type", selection: $templates[idx].itemType) {
                            Text("Character").tag(CastingItemType.character)
                            Text("Location").tag(CastingItemType.location)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.bottom, 12)

                    Divider().padding(.vertical, 8)

                    // Average Duration
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Average Duration")
                        HStack(spacing: 6) {
                            TextField("Seconds", value: $templates[idx].averageDuration, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            Text("seconds")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(durationString(templates[idx].averageDuration))
                                .font(.callout)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.bottom, 12)

                    // Generation Model
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Generation Model")
                        TextField("Model name", text: $templates[idx].generationModel)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.bottom, 12)

                    // Generation Steps
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Generation Steps")
                        HStack(spacing: 6) {
                            TextField("Steps", value: $templates[idx].generationSteps, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            Text("steps")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 12)

                    Spacer(minLength: 20)
                }
                .padding(14)
            }
            .background(Color(NSColor.windowBackgroundColor))
        } else {
            ContentUnavailableView(
                "No template selected",
                systemImage: "doc.text",
                description: Text("Select a template from the list to edit its properties.")
            )
        }
    }

    private func generateExample(at idx: Int) {
        let template = templates[idx]
        let job = GenerationJob(
            id: UUID().uuidString,
            itemName: template.name,
            itemType: template.itemType,
            jobType: .generateExample,
            lookName: template.name,
            queuedAt: Date(),
            estimatedDuration: TimeInterval(template.averageDuration),
            itemIcon: template.itemType == .character ? "person.fill" : "map"
        )
        generationQueue.append(job)
    }
}

// MARK: - Generic detail

private struct GenericDetailView: View {
    let item: MockItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color.opacity(0.12))
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .overlay {
                        Image(systemName: item.icon)
                            .font(.system(size: 44))
                            .foregroundStyle(item.color)
                    }
                Text(item.name).font(.title3.bold())
                Divider()
                LabeledContent("Status")   { Text(item.status).foregroundStyle(.secondary) }
                LabeledContent("Variants") { Text("\(item.variantCount)").foregroundStyle(.secondary) }
                LabeledContent("ID")       { Text(item.id).font(.caption.monospaced()).foregroundStyle(.tertiary) }
                Spacer()
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Shared free function

private func sectionLabel(_ title: String) -> some View {
    Text(title)
        .font(.caption)
        .foregroundStyle(.tertiary)
        .textCase(.uppercase)
        .tracking(0.5)
}

#Preview("Project — Episode") {
    @Previewable @State var studios = MockData.defaultStudios
    ItemDetailView(
        section: .projects,
        studios: $studios,
        selectedStudioID: MockData.defaultStudios[0].id,
        selectedCustomerID: MockData.defaultStudios[0].customers[0].id,
        selectedEpisodeID: MockData.defaultStudios[0].customers[0].episodes[0].id,
        selectedBriefingLevel: .episode,
        selectedItemID: nil,
        templates: MockData.defaultTemplates
    )
    .frame(width: 280, height: 700)
}
#Preview("Project — Studio") {
    @Previewable @State var studios = MockData.defaultStudios
    ItemDetailView(
        section: .projects,
        studios: $studios,
        selectedStudioID: MockData.defaultStudios[0].id,
        selectedCustomerID: MockData.defaultStudios[0].customers[0].id,
        selectedEpisodeID: MockData.defaultStudios[0].customers[0].episodes[0].id,
        selectedBriefingLevel: .studio,
        selectedItemID: nil,
        templates: MockData.defaultTemplates
    )
    .frame(width: 280, height: 700)
}

