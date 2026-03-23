import SwiftUI

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

    // MARK: - Look state (local @State for reliable refresh)

    /// Local copy of the own look ID, synced with the binding.
    @State private var localLookID: String? = nil
    @State private var showLookPicker = false
    @State private var showCastPicker = false
    @State private var showLocationPicker = false

    /// Write the local look ID back to the studios binding.
    private func syncLookToBinding() {
        switch level {
        case .studio:
            guard let si = studioIndex else { return }
            studios[si].preferredLookID = localLookID
        case .customer:
            guard let si = studioIndex, let ci = customerIndex else { return }
            studios[si].customers[ci].preferredLookID = localLookID
        case .episode:
            guard let si = studioIndex, let ci = customerIndex, let ei = episodeIndex else { return }
            studios[si].customers[ci].episodes[ei].preferredLookID = localLookID
        }
    }

    /// Read the own look ID from the studios binding.
    private var boundLookID: String? {
        switch level {
        case .studio:
            guard let si = studioIndex else { return nil }
            return studios[si].preferredLookID
        case .customer:
            guard let si = studioIndex, let ci = customerIndex else { return nil }
            return studios[si].customers[ci].preferredLookID
        case .episode:
            guard let si = studioIndex, let ci = customerIndex, let ei = episodeIndex else { return nil }
            return studios[si].customers[ci].episodes[ei].preferredLookID
        }
    }

    /// Inherited look from higher levels (not including the current level's own look).
    private var inheritedLook: (look: GenerationTemplate, source: BriefingLevel)? {
        guard let si = studioIndex else { return nil }
        let studio = studios[si]

        switch level {
        case .episode:
            guard let ci = customerIndex else { return nil }
            let customer = studio.customers[ci]
            if let id = customer.preferredLookID, let t = templates.first(where: { $0.id == id }) {
                return (t, .customer)
            }
            if let id = studio.preferredLookID, let t = templates.first(where: { $0.id == id }) {
                return (t, .studio)
            }
        case .customer:
            if let id = studio.preferredLookID, let t = templates.first(where: { $0.id == id }) {
                return (t, .studio)
            }
        case .studio:
            break
        }
        return nil
    }

    /// Resolved look: own look first, then inherited.
    private var resolvedLook: (look: GenerationTemplate, source: BriefingLevel)? {
        if let id = localLookID, let t = templates.first(where: { $0.id == id }) {
            return (t, level)
        }
        return inheritedLook
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

                // Preferred Look (all levels)
                Divider().padding(.bottom, 12)
                PreferredLookSection(
                    level: level,
                    resolvedLook: resolvedLook,
                    hasOwnLook: localLookID != nil,
                    onRemove: {
                        localLookID = nil
                        syncLookToBinding()
                    },
                    onAdd: { showLookPicker = true }
                )

                // Assets (only shown for Episode level)
                if let characters = charactersBinding,
                   let locations = locationsBinding {
                    Divider().padding(.bottom, 12)
                    EpisodeAssetsSection(
                        characters: characters,
                        locations: locations,
                        onAddCast: { showCastPicker = true },
                        onAddLocation: { showLocationPicker = true }
                    )
                }

                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { localLookID = boundLookID }
        .onChange(of: boundLookID) { _, newValue in
            if localLookID != newValue { localLookID = newValue }
        }
        .sheet(isPresented: $showLookPicker) {
            LookPickerView(
                templates: templates,
                onSelect: { template in
                    localLookID = template.id
                    syncLookToBinding()
                    showLookPicker = false
                },
                onCancel: { showLookPicker = false }
            )
        }
        .sheet(isPresented: $showCastPicker) {
            if let characters = charactersBinding {
                AssetPickerView(
                    title: "Add Cast Member",
                    availableItems: availableCharacters,
                    onSelect: { item in
                        characters.wrappedValue.append(item)
                        showCastPicker = false
                    },
                    onCancel: { showCastPicker = false }
                )
            }
        }
        .sheet(isPresented: $showLocationPicker) {
            if let locations = locationsBinding {
                AssetPickerView(
                    title: "Add Location",
                    availableItems: availableLocations,
                    onSelect: { item in
                        locations.wrappedValue.append(item)
                        showLocationPicker = false
                    },
                    onCancel: { showLocationPicker = false }
                )
            }
        }
    }

    // MARK: - Available items for pickers (library items not already assigned)

    /// Characters from studio + customer level, minus those already in the episode.
    private var availableCharacters: [CastingItem] {
        guard let si = studioIndex else { return [] }
        let studio = studios[si]
        var pool = studio.characters.filter { $0.type == .character }
        if let ci = customerIndex {
            pool += studio.customers[ci].characters.filter { $0.type == .character }
        }
        let assignedIDs = Set(charactersBinding?.wrappedValue.map(\.id) ?? [])
        return pool.filter { !assignedIDs.contains($0.id) }
    }

    /// Locations from studio + customer level, minus those already in the episode.
    private var availableLocations: [CastingItem] {
        guard let si = studioIndex else { return [] }
        let studio = studios[si]
        var pool = studio.locations.filter { $0.type == .location }
        if let ci = customerIndex {
            pool += studio.customers[ci].locations.filter { $0.type == .location }
        }
        let assignedIDs = Set(locationsBinding?.wrappedValue.map(\.id) ?? [])
        return pool.filter { !assignedIDs.contains($0.id) }
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

// MARK: - Preferred Look (with inheritance, x-remove, + pick)

private struct PreferredLookSection: View {
    let level: BriefingLevel
    let resolvedLook: (look: GenerationTemplate, source: BriefingLevel)?
    let hasOwnLook: Bool
    let onRemove: () -> Void
    let onAdd: () -> Void

    /// Whether the resolved look is inherited from a higher level.
    private var isInherited: Bool {
        guard let resolved = resolvedLook else { return false }
        return resolved.source != level
    }

    /// Badge text for the source level.
    private var sourceBadge: String {
        guard let resolved = resolvedLook else { return "" }
        switch resolved.source {
        case .studio:   return "ST"
        case .customer: return "CU"
        case .episode:  return "EP"
        }
    }

    private var sourceColor: Color {
        guard let resolved = resolvedLook else { return .gray }
        switch resolved.source {
        case .studio:   return .purple
        case .customer: return .teal
        case .episode:  return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                sectionLabel("Preferred Look")
                Spacer()
                if hasOwnLook {
                    // x-remove own look
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .secondary)
                    }
                    .buttonStyle(.plain)
                }
                if !hasOwnLook {
                    // + pick a look
                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }

            if let resolved = resolvedLook {
                let columns = [GridItem(.adaptive(minimum: 288, maximum: 320), spacing: 12)]
                LazyVGrid(columns: columns, spacing: 12) {
                    UnifiedThumbnailView(
                        itemType: .look,
                        name: resolved.look.name,
                        sizeMode: .standard,
                        badges: ThumbnailBadges(
                            showExampleIndicator: true,
                            exampleAvailable: resolved.look.lookStatus == .exampleAvailable,
                            levelBadgeText: isInherited ? sourceBadge : nil,
                            levelBadgeColor: sourceColor,
                            showInheritanceArrow: isInherited
                        )
                    )
                }


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

// MARK: - Look picker sheet

private struct LookPickerView: View {
    let templates: [GenerationTemplate]
    let onSelect: (GenerationTemplate) -> Void
    let onCancel: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 288, maximum: 320), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select a Look")
                    .font(.headline)
                Spacer()
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .padding()

            Divider()

            if templates.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No looks available",
                    systemImage: "paintpalette",
                    description: Text("Create a look in the Looks section first.")
                )
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(templates) { template in
                            UnifiedThumbnailView(
                                itemType: .look,
                                name: template.name,
                                sizeMode: .standard,
                                badges: ThumbnailBadges(
                                    showExampleIndicator: true,
                                    exampleAvailable: template.lookStatus == .exampleAvailable
                                )
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { onSelect(template) }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 350)
    }
}

// MARK: - Unified assets section (locations first, then cast)

private struct EpisodeAssetsSection: View {
    @Binding var characters: [CastingItem]
    @Binding var locations: [CastingItem]
    let onAddCast: () -> Void
    let onAddLocation: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 288, maximum: 320), spacing: 12)]

    /// Combined list: locations first, then characters.
    private var allAssets: [CastingItem] {
        locations + characters
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                sectionLabel("Assets")
                Spacer()
                Button(action: onAddLocation) {
                    Label("Add Location", systemImage: "mappin.and.ellipse")
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)

                Button(action: onAddCast) {
                    Label("Add Cast", systemImage: "person.badge.plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }

            if allAssets.isEmpty {
                Text("No assets assigned")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 12)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(allAssets) { item in
                        UnifiedThumbnailView(
                            itemType: item.thumbnailType,
                            name: item.name,
                            sizeMode: .standard,
                            badges: ThumbnailBadges(
                                assetStatus: item.assetStatusFlags,
                                showDeleteButton: true,
                                onDelete: {
                                    removeAsset(item)
                                }
                            )
                        )
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }

    private func removeAsset(_ item: CastingItem) {
        switch item.type {
        case .character:
            if let idx = characters.firstIndex(where: { $0.id == item.id }) {
                characters.remove(at: idx)
            }
        case .location:
            if let idx = locations.firstIndex(where: { $0.id == item.id }) {
                locations.remove(at: idx)
            }
        }
    }
}

// MARK: - Asset picker sheet (reusable for cast & locations)

private struct AssetPickerView: View {
    let title: String
    let availableItems: [CastingItem]
    let onSelect: (CastingItem) -> Void
    let onCancel: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 288, maximum: 320), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .padding()

            Divider()

            if availableItems.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No items available",
                    systemImage: "tray",
                    description: Text("All library items are already assigned, or none exist at studio/customer level.")
                )
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(availableItems) { item in
                            UnifiedThumbnailView(
                                itemType: item.thumbnailType,
                                name: item.name,
                                sizeMode: .standard,
                                badges: ThumbnailBadges(
                                    assetStatus: item.assetStatusFlags
                                )
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { onSelect(item) }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 350)
    }
}
