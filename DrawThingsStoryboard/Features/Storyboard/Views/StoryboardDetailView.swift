import SwiftUI

/// Right pane for the Storyboard section.
/// Shows properties (Name, Description) for the selected Act, Sequence, Scene, or Panel.
struct StoryboardDetailView: View {

    @Binding var acts: [MockAct]
    let selection: StoryboardSelection?
    @Binding var generationQueue: [GenerationJob]

    // Read-only access to studios for collecting available assets
    let studios: [MockStudio]
    let studioIndex: Int
    let customerIndex: Int
    let episodeIndex: Int

    /// All assets available to the current episode (studio + customer + episode level).
    private var availableAssets: [CastingItem] {
        guard studios.indices.contains(studioIndex) else { return [] }
        let studio = studios[studioIndex]
        var assets: [CastingItem] = []

        // Studio-level assets
        assets.append(contentsOf: studio.characters)
        assets.append(contentsOf: studio.locations)

        // Customer-level assets
        guard studio.customers.indices.contains(customerIndex) else { return assets }
        let customer = studio.customers[customerIndex]
        let custChars = customer.episodes.flatMap(\.characters).filter { $0.libraryLevel == .customer }
        let custLocs  = customer.episodes.flatMap(\.locations).filter { $0.libraryLevel == .customer }
        assets.append(contentsOf: custChars)
        assets.append(contentsOf: custLocs)

        // Episode-level assets
        guard customer.episodes.indices.contains(episodeIndex) else { return assets }
        let episode = customer.episodes[episodeIndex]
        assets.append(contentsOf: episode.characters.filter { $0.libraryLevel == .episode })
        assets.append(contentsOf: episode.locations.filter { $0.libraryLevel == .episode })

        return assets
    }

    var body: some View {
        if let selection {
            switch selection {
            case .act(let id):
                if let actIdx = acts.firstIndex(where: { $0.id == id }) {
                    StoryboardNodeDetailView(
                        level: .act,
                        name: $acts[actIdx].name,
                        description: $acts[actIdx].description
                    )
                } else {
                    emptyState
                }

            case .sequence(let id):
                if let (ai, si) = findSequenceIndices(id) {
                    StoryboardNodeDetailView(
                        level: .sequence,
                        name: $acts[ai].sequences[si].name,
                        description: $acts[ai].sequences[si].description
                    )
                } else {
                    emptyState
                }

            case .scene(let id):
                if let (ai, si, sci) = findSceneIndices(id) {
                    StoryboardNodeDetailView(
                        level: .scene,
                        name: $acts[ai].sequences[si].scenes[sci].name,
                        description: $acts[ai].sequences[si].scenes[sci].description
                    )
                } else {
                    emptyState
                }

            case .panel(let id):
                if let (ai, si, sci, pi) = findPanelIndices(id) {
                    StoryboardPanelDetailView(
                        panel: $acts[ai].sequences[si].scenes[sci].panels[pi],
                        generationQueue: $generationQueue,
                        availableAssets: availableAssets
                    )
                } else {
                    emptyState
                }
            }
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nothing selected",
            systemImage: "square.dashed",
            description: Text("Select an act, sequence, scene, or panel to see its properties.")
        )
    }

    // MARK: - Index lookup helpers

    private func findSequenceIndices(_ id: String) -> (Int, Int)? {
        for ai in acts.indices {
            for si in acts[ai].sequences.indices {
                if acts[ai].sequences[si].id == id {
                    return (ai, si)
                }
            }
        }
        return nil
    }

    private func findSceneIndices(_ id: String) -> (Int, Int, Int)? {
        for ai in acts.indices {
            for si in acts[ai].sequences.indices {
                for sci in acts[ai].sequences[si].scenes.indices {
                    if acts[ai].sequences[si].scenes[sci].id == id {
                        return (ai, si, sci)
                    }
                }
            }
        }
        return nil
    }

    private func findPanelIndices(_ id: String) -> (Int, Int, Int, Int)? {
        for ai in acts.indices {
            for si in acts[ai].sequences.indices {
                for sci in acts[ai].sequences[si].scenes.indices {
                    for pi in acts[ai].sequences[si].scenes[sci].panels.indices {
                        if acts[ai].sequences[si].scenes[sci].panels[pi].id == id {
                            return (ai, si, sci, pi)
                        }
                    }
                }
            }
        }
        return nil
    }
}

// MARK: - Node detail (Act / Sequence / Scene)

private struct StoryboardNodeDetailView: View {
    let level: StoryboardLevel
    @Binding var name: String
    @Binding var description: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Type badge header
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(level.color.opacity(0.12))
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .overlay {
                            Image(systemName: level.icon)
                                .font(.system(size: 40))
                                .foregroundStyle(level.color.opacity(0.6))
                        }
                    Text(level.label)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())
                        .foregroundStyle(.secondary)
                        .padding(10)
                }

                Divider().padding(.vertical, 8)

                // Name
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Name")
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.bottom, 16)

                // Description
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Description")
                    TextEditor(text: $description)
                        .font(.callout)
                        .frame(minHeight: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
                        )
                }
                .padding(.bottom, 16)

                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Panel detail

private struct StoryboardPanelDetailView: View {
    @Binding var panel: MockPanel
    @Binding var generationQueue: [GenerationJob]
    let availableAssets: [CastingItem]

    @AppStorage(SizeConfigKeys.previewVariantWidth)  private var previewVariantWidth  = SizeConfigDefaults.previewVariantWidth
    @AppStorage(SizeConfigKeys.previewVariantHeight) private var previewVariantHeight = SizeConfigDefaults.previewVariantHeight
    @AppStorage(SizeConfigKeys.finalWidth)           private var finalWidth           = SizeConfigDefaults.finalWidth
    @AppStorage(SizeConfigKeys.finalHeight)          private var finalHeight          = SizeConfigDefaults.finalHeight

    @State private var showAssetPicker = false

    /// Resolved attached assets (matched by ID from the available pool).
    private var attachedAssets: [CastingItem] {
        panel.attachedAssetIDs.compactMap { id in
            availableAssets.first { $0.id == id }
        }
    }

    /// Whether the + button is enabled.
    private var canAddAsset: Bool {
        panel.attachedAssetIDs.count < 4
    }

    /// Whether a location is already attached.
    private var hasLocation: Bool {
        attachedAssets.contains { $0.type == .location }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Thumbnail header
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(StoryboardLevel.panel.color.opacity(0.12))
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 52))
                                .foregroundStyle(StoryboardLevel.panel.color.opacity(0.6))
                        }
                    Text("Panel")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())
                        .foregroundStyle(.secondary)
                        .padding(10)
                }
                .padding(.bottom, 16)

                // Status with generate buttons
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Status")
                    HStack(spacing: 8) {
                        Circle()
                            .fill(panel.status.color)
                            .frame(width: 8, height: 8)
                        Text(panel.status.label)
                            .font(.callout)
                        Spacer()

                        if panel.status == .nothingGenerated {
                            Button {
                                generatePreviewPanel()
                            } label: {
                                Label("Generate Preview", systemImage: "photo")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }

                        if panel.status == .nothingGenerated || panel.status == .previewGenerated {
                            Button {
                                generateFinalPanel()
                            } label: {
                                Label("Generate Final", systemImage: "photo.badge.checkmark")
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

                Divider().padding(.vertical, 8)

                // Name
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Name")
                    TextField("Name", text: $panel.name)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.bottom, 12)

                // Description
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Description")
                    TextEditor(text: $panel.description)
                        .font(.callout)
                        .frame(minHeight: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
                        )
                }
                .padding(.bottom, 12)

                Divider().padding(.vertical, 8)

                // Attached Assets
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        sectionLabel("Assets (\(panel.attachedAssetIDs.count)/4)")
                        Spacer()
                        Button {
                            showAssetPicker = true
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: 22, height: 22)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .disabled(!canAddAsset)
                    }

                    if attachedAssets.isEmpty {
                        Text("No assets attached — tap + to add.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 8)
                    } else {
                        let columns = [GridItem(.adaptive(minimum: 90, maximum: 120), spacing: 8)]
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(attachedAssets) { asset in
                                PanelAssetTileView(
                                    item: asset,
                                    onRemove: {
                                        panel.attachedAssetIDs.removeAll { $0 == asset.id }
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(.bottom, 12)

                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showAssetPicker) {
            PanelAssetPickerView(
                availableAssets: availableAssets,
                alreadyAttachedIDs: Set(panel.attachedAssetIDs),
                hasLocation: hasLocation,
                onSelect: { selectedAsset in
                    panel.attachedAssetIDs.append(selectedAsset.id)
                    showAssetPicker = false
                },
                onCancel: {
                    showAssetPicker = false
                }
            )
        }
    }

    private func generatePreviewPanel() {
        let job = GenerationJob(
            id: UUID().uuidString,
            itemName: panel.name,
            itemType: .location,
            jobType: .generatePreviewPanel,
            lookName: "Panel Preview",
            queuedAt: Date(),
            estimatedDuration: 120,
            itemIcon: "photo",
            seed: Int.random(in: 1...999_999),
            width: previewVariantWidth,
            height: previewVariantHeight,
            combinedPrompt: panel.description
        )
        generationQueue.append(job)
    }

    private func generateFinalPanel() {
        let job = GenerationJob(
            id: UUID().uuidString,
            itemName: panel.name,
            itemType: .location,
            jobType: .generateFinalPanel,
            lookName: "Panel Final",
            queuedAt: Date(),
            estimatedDuration: 240,
            itemIcon: "photo",
            seed: Int.random(in: 1...999_999),
            width: finalWidth,
            height: finalHeight,
            combinedPrompt: panel.description
        )
        generationQueue.append(job)
    }
}

// MARK: - Panel asset tile (attached asset with x-remove)

private struct PanelAssetTileView: View {
    let item: CastingItem
    let onRemove: () -> Void

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

                // X-remove button — top trailing
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onRemove) {
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

                // Type badge — bottom leading
                VStack {
                    Spacer()
                    HStack {
                        Text(item.type == .character ? "CH" : "LO")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(tileColor.opacity(0.2), in: RoundedRectangle(cornerRadius: 3))
                            .foregroundStyle(tileColor)
                            .padding(3)
                        Spacer()
                    }
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

// MARK: - Asset picker sheet

private struct PanelAssetPickerView: View {
    let availableAssets: [CastingItem]
    let alreadyAttachedIDs: Set<String>
    let hasLocation: Bool
    let onSelect: (CastingItem) -> Void
    let onCancel: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 10)]

    /// Assets that can still be picked (not already attached, respecting location limit).
    private var pickableAssets: [CastingItem] {
        availableAssets.filter { asset in
            // Skip already attached
            guard !alreadyAttachedIDs.contains(asset.id) else { return false }
            // Skip locations if one is already attached
            if hasLocation && asset.type == .location { return false }
            return true
        }
    }

    private var characters: [CastingItem] {
        pickableAssets.filter { $0.type == .character }
    }

    private var locations: [CastingItem] {
        pickableAssets.filter { $0.type == .location }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Asset to Panel")
                    .font(.headline)
                Spacer()
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .padding()

            Divider()

            if pickableAssets.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No assets available",
                    systemImage: "tray",
                    description: Text("All assets are already attached or no assets exist.")
                )
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if !characters.isEmpty {
                            Text("Characters")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 16)

                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(characters) { asset in
                                    PickerAssetTileView(item: asset)
                                        .onTapGesture { onSelect(asset) }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        if !locations.isEmpty {
                            Text("Locations")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 16)

                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(locations) { asset in
                                    PickerAssetTileView(item: asset)
                                        .onTapGesture { onSelect(asset) }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 350)
    }
}

// MARK: - Picker tile (for the asset picker sheet)

private struct PickerAssetTileView: View {
    let item: CastingItem

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(tileColor.opacity(0.13))
                    .frame(height: 64)
                    .overlay {
                        Image(systemName: tileIcon)
                            .font(.system(size: 22))
                            .foregroundStyle(tileColor.opacity(0.7))
                    }

                // Level badge — bottom leading
                VStack {
                    Spacer()
                    HStack {
                        Text(item.libraryLevel.rawValue.prefix(2).uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(levelColor.opacity(0.2), in: RoundedRectangle(cornerRadius: 3))
                            .foregroundStyle(levelColor)
                            .padding(3)
                        Spacer()
                    }
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
            }

            Text(item.name)
                .font(.caption2)
                .lineLimit(1)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.04))
        )
        .contentShape(Rectangle())
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

    private var levelColor: Color {
        switch item.libraryLevel {
        case .studio:   return .purple
        case .customer: return .teal
        case .episode:  return .blue
        }
    }
}

// MARK: - Shared section label helper

private func sectionLabel(_ title: String) -> some View {
    Text(title)
        .font(.caption)
        .foregroundStyle(.tertiary)
        .textCase(.uppercase)
        .tracking(0.5)
}

#Preview {
    @Previewable @State var acts = MockData.sampleActs
    @Previewable @State var queue: [GenerationJob] = []
    StoryboardDetailView(
        acts: $acts,
        selection: .act("act-01"),
        generationQueue: $queue,
        studios: MockData.defaultStudios,
        studioIndex: 0,
        customerIndex: 0,
        episodeIndex: 0
    )
    .frame(width: 300, height: 600)
}
