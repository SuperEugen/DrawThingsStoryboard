import SwiftUI

/// Right pane for the Storyboard section.
struct StoryboardDetailView: View {

    @Binding var acts: [MockAct]
    let selection: StoryboardSelection?
    @Binding var generationQueue: [GenerationJob]

    let studios: [MockStudio]
    let studioIndex: Int
    let customerIndex: Int
    let episodeIndex: Int
    var resolvedLookName: String? = nil
    var templates: [GenerationTemplate] = []

    private var availableAssets: [CastingItem] {
        guard studios.indices.contains(studioIndex) else { return [] }
        let studio = studios[studioIndex]
        var assets: [CastingItem] = []
        assets.append(contentsOf: studio.characters)
        assets.append(contentsOf: studio.locations)
        guard studio.customers.indices.contains(customerIndex) else { return assets }
        let customer = studio.customers[customerIndex]
        assets.append(contentsOf: customer.characters)
        assets.append(contentsOf: customer.locations)
        guard customer.episodes.indices.contains(episodeIndex) else { return assets }
        let episode = customer.episodes[episodeIndex]
        assets.append(contentsOf: episode.characters)
        assets.append(contentsOf: episode.locations)
        return assets
    }

    var body: some View {
        if let selection {
            switch selection {
            case .act(let id):
                if let actIdx = acts.firstIndex(where: { $0.id == id }) {
                    StoryboardNodeDetailView(level: .act,
                        name: $acts[actIdx].name,
                        description: $acts[actIdx].description)
                } else { emptyState }

            case .sequence(let id):
                if let (ai, si) = findSequenceIndices(id) {
                    StoryboardNodeDetailView(level: .sequence,
                        name: $acts[ai].sequences[si].name,
                        description: $acts[ai].sequences[si].description)
                } else { emptyState }

            case .scene(let id):
                if let (ai, si, sci) = findSceneIndices(id) {
                    StoryboardNodeDetailView(level: .scene,
                        name: $acts[ai].sequences[si].scenes[sci].name,
                        description: $acts[ai].sequences[si].scenes[sci].description)
                } else { emptyState }

            case .panel(let id):
                if let (ai, si, sci, pi) = findPanelIndices(id) {
                    StoryboardPanelDetailView(
                        panel: $acts[ai].sequences[si].scenes[sci].panels[pi],
                        generationQueue: $generationQueue,
                        availableAssets: availableAssets,
                        resolvedLookName: resolvedLookName,
                        lookDescription: templates.first { $0.name == resolvedLookName }?.description ?? ""
                    )
                } else { emptyState }
            }
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nothing selected", systemImage: "square.dashed",
            description: Text("Select an act, sequence, scene, or panel to see its properties.")
        )
    }

    private func findSequenceIndices(_ id: String) -> (Int, Int)? {
        for ai in acts.indices {
            for si in acts[ai].sequences.indices {
                if acts[ai].sequences[si].id == id { return (ai, si) }
            }
        }
        return nil
    }

    private func findSceneIndices(_ id: String) -> (Int, Int, Int)? {
        for ai in acts.indices {
            for si in acts[ai].sequences.indices {
                for sci in acts[ai].sequences[si].scenes.indices {
                    if acts[ai].sequences[si].scenes[sci].id == id { return (ai, si, sci) }
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
                        if acts[ai].sequences[si].scenes[sci].panels[pi].id == id { return (ai, si, sci, pi) }
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
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(level.color.opacity(0.12))
                        .frame(maxWidth: .infinity).frame(height: 100)
                        .overlay {
                            Image(systemName: level.icon).font(.system(size: 40))
                                .foregroundStyle(level.color.opacity(0.6))
                        }
                    Text(level.label).font(.caption.weight(.medium))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())
                        .foregroundStyle(.secondary).padding(10)
                }

                Divider().padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Name")
                    TextField("Name", text: $name).textFieldStyle(.roundedBorder)
                }
                .padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Description")
                    TextEditor(text: $description).font(.callout).frame(minHeight: 120)
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5))
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
    var resolvedLookName: String? = nil
    var lookDescription: String = ""

    @AppStorage(SizeConfigKeys.previewVariantWidth)  private var previewVariantWidth  = SizeConfigDefaults.previewVariantWidth
    @AppStorage(SizeConfigKeys.previewVariantHeight) private var previewVariantHeight = SizeConfigDefaults.previewVariantHeight
    @AppStorage(SizeConfigKeys.finalWidth)           private var finalWidth           = SizeConfigDefaults.finalWidth
    @AppStorage(SizeConfigKeys.finalHeight)          private var finalHeight          = SizeConfigDefaults.finalHeight

    @State private var showAssetPicker = false
    @State private var attachedIDs: [String] = []

    private var attachedAssets: [CastingItem] {
        let resolved = attachedIDs.compactMap { id in availableAssets.first { $0.id == id } }
        return resolved.sorted { a, b in
            if a.type == .location && b.type != .location { return true }
            if a.type != .location && b.type == .location { return false }
            return false
        }
    }

    private var canAddAsset: Bool { attachedIDs.count < 4 }

    private var smallPanelQueued: Bool {
        generationQueue.contains { $0.itemName == panel.name && $0.jobType == .generatePanel && $0.size == .small }
    }
    private var largePanelQueued: Bool {
        generationQueue.contains { $0.itemName == panel.name && $0.jobType == .generatePanel && $0.size == .large }
    }

    private func syncToBinding() { panel.attachedAssetIDs = attachedIDs }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                UnifiedThumbnailView(itemType: .panel, name: "", sizeMode: .header)
                    .padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Status")

                    HStack(spacing: 8) {
                        Text("S").font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(panel.smallPanelAvailable ? .green : .gray)
                        Text("Small Panel available:").font(.callout)
                        Text(panel.smallPanelAvailable ? "yes" : "not yet").font(.callout)
                            .foregroundStyle(panel.smallPanelAvailable ? .green : .secondary)
                        Spacer()
                        if !panel.smallPanelAvailable {
                            if smallPanelQueued {
                                Text("queued").font(.caption).foregroundStyle(.orange)
                            } else {
                                Button { generateSmallPanel() } label: {
                                    Label("Generate Small Panel", systemImage: "photo").font(.caption)
                                }
                                .buttonStyle(.bordered).controlSize(.mini)
                            }
                        }
                    }
                    .padding(.vertical, 5).padding(.horizontal, 8)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.07)))

                    HStack(spacing: 8) {
                        Text("L").font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(panel.largePanelAvailable ? .green : .gray)
                        Text("Large Panel available:").font(.callout)
                        Text(panel.largePanelAvailable ? "yes" : (panel.smallPanelAvailable ? "not yet" : "no Small Panel"))
                            .font(.callout).foregroundStyle(panel.largePanelAvailable ? .green : .secondary)
                        Spacer()
                        if panel.smallPanelAvailable && !panel.largePanelAvailable {
                            if largePanelQueued {
                                Text("queued").font(.caption).foregroundStyle(.green)
                            } else {
                                Button { generateLargePanel() } label: {
                                    Label("Generate Large Panel", systemImage: "photo.badge.checkmark").font(.caption)
                                }
                                .buttonStyle(.bordered).controlSize(.mini)
                            }
                        }
                    }
                    .padding(.vertical, 5).padding(.horizontal, 8)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.07)))
                }
                .padding(.bottom, 12)

                Divider().padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Name")
                    TextField("Name", text: $panel.name).textFieldStyle(.roundedBorder)
                }
                .padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Description")
                    TextEditor(text: $panel.description).font(.callout).frame(minHeight: 80)
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5))
                }
                .padding(.bottom, 12)

                if !panel.fileName.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("File Name")
                        Text(panel.fileName).font(.callout).foregroundStyle(.secondary)
                            .textSelection(.enabled).padding(.vertical, 5).padding(.horizontal, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.07)))
                    }
                    .padding(.bottom, 12)
                }

                Divider().padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        sectionLabel("Assets (\(attachedIDs.count)/4)")
                        Spacer()
                        Button { showAssetPicker = true } label: {
                            Image(systemName: "plus").frame(width: 22, height: 22)
                        }
                        .buttonStyle(.bordered).controlSize(.mini).disabled(!canAddAsset)
                    }
                    if attachedAssets.isEmpty {
                        Text("No assets attached — tap + to add.")
                            .font(.caption).foregroundStyle(.tertiary).padding(.vertical, 8)
                    } else {
                        let columns = [GridItem(.adaptive(minimum: 288, maximum: 320), spacing: 12)]
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(attachedAssets) { asset in
                                PanelAssetTileView(item: asset, onRemove: {
                                    attachedIDs.removeAll { $0 == asset.id }
                                    syncToBinding()
                                })
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
        .onAppear { attachedIDs = panel.attachedAssetIDs }
        .onChange(of: panel.attachedAssetIDs) { _, newValue in
            if attachedIDs != newValue { attachedIDs = newValue }
        }
        .sheet(isPresented: $showAssetPicker) {
            PanelAssetPickerView(
                panelName: panel.name,
                availableAssets: availableAssets,
                attachedIDs: $attachedIDs,
                allAvailableAssets: availableAssets,
                onDone: { syncToBinding(); showAssetPicker = false }
            )
        }
    }

    private var assetInfos: [JobAssetInfo] {
        attachedAssets.map { asset in
            let icon = asset.type == .character
                ? (asset.gender?.icon ?? "person.fill")
                : (asset.locationSetting?.icon ?? "map")
            return JobAssetInfo(id: asset.id, name: asset.name, type: asset.type, icon: icon,
                                gender: asset.gender, locationSetting: asset.locationSetting)
        }
    }

    private func generateSmallPanel() {
        var job = GenerationJob(
            id: UUID().uuidString, itemName: panel.name, itemType: .character,
            jobType: .generatePanel, size: .small, lookName: resolvedLookName ?? "—",
            queuedAt: Date(), estimatedDuration: 120, itemIcon: "photo",
            seed: Int64.random(in: 1...999_999),
            width: previewVariantWidth, height: previewVariantHeight,
            combinedPrompt: buildCombinedPrompt()
        )
        job.attachedAssets = assetInfos
        generationQueue.append(job)
    }

    private func generateLargePanel() {
        var job = GenerationJob(
            id: UUID().uuidString, itemName: panel.name, itemType: .character,
            jobType: .generatePanel, size: .large, lookName: resolvedLookName ?? "—",
            queuedAt: Date(), estimatedDuration: 240, itemIcon: "photo",
            seed: Int64.random(in: 1...999_999),
            width: finalWidth, height: finalHeight,
            combinedPrompt: buildCombinedPrompt()
        )
        job.attachedAssets = assetInfos
        generationQueue.append(job)
    }

    /// Combined prompt: look description + panel description
    private func buildCombinedPrompt() -> String {
        [lookDescription, panel.description]
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: ", ")
    }
}

// MARK: - Panel asset tile

private struct PanelAssetTileView: View {
    let item: CastingItem
    let onRemove: () -> Void

    var body: some View {
        UnifiedThumbnailView(
            itemType: item.thumbnailType, name: item.name, sizeMode: .standard,
            badges: ThumbnailBadges(
                showDeleteButton: true, onDelete: onRemove,
                levelBadgeText: item.type == .character ? "CH" : "LO",
                levelBadgeColor: item.thumbnailType.backgroundColor
            )
        )
    }
}

// MARK: - Asset picker sheet

private struct PanelAssetPickerView: View {
    let panelName: String
    let availableAssets: [CastingItem]
    @Binding var attachedIDs: [String]
    let allAvailableAssets: [CastingItem]
    let onDone: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 288, maximum: 320), spacing: 12)]

    private var hasLocation: Bool {
        attachedIDs.contains { id in allAvailableAssets.first { $0.id == id }?.type == .location }
    }

    private var pickableAssets: [CastingItem] {
        let attached = Set(attachedIDs)
        return availableAssets.filter { asset in
            guard !attached.contains(asset.id) else { return false }
            if hasLocation && asset.type == .location { return false }
            return true
        }
    }

    private var characters: [CastingItem] { pickableAssets.filter { $0.type == .character } }
    private var locations:  [CastingItem] { pickableAssets.filter { $0.type == .location  } }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add Asset to Panel: \(panelName)").font(.headline)
                Spacer()
                Button("Cancel", action: onDone).buttonStyle(.bordered).controlSize(.small)
            }
            .padding()
            Divider()

            if pickableAssets.isEmpty {
                Spacer()
                ContentUnavailableView("No assets available", systemImage: "tray",
                    description: Text("All assets are already attached or no assets exist."))
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if !characters.isEmpty {
                            Text("Characters").font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary).padding(.horizontal, 16)
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(characters) { asset in
                                    PickerAssetTileView(item: asset)
                                        .onTapGesture { attachedIDs.append(asset.id); onDone() }
                                }
                            }.padding(.horizontal, 16)
                        }
                        if !locations.isEmpty {
                            Text("Locations").font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary).padding(.horizontal, 16)
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(locations) { asset in
                                    PickerAssetTileView(item: asset)
                                        .onTapGesture { attachedIDs.append(asset.id); onDone() }
                                }
                            }.padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 350)
    }
}

// MARK: - Picker tile

private struct PickerAssetTileView: View {
    let item: CastingItem

    private var levelColor: Color {
        switch item.libraryLevel {
        case .studio: return .purple; case .customer: return .teal; case .episode: return .blue
        }
    }

    var body: some View {
        UnifiedThumbnailView(
            itemType: item.thumbnailType, name: item.name, sizeMode: .standard,
            badges: ThumbnailBadges(
                assetStatus: item.assetStatusFlags,
                levelBadgeText: String(item.libraryLevel.rawValue.prefix(2)).uppercased(),
                levelBadgeColor: levelColor
            )
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    @Previewable @State var acts: [MockAct] = []
    @Previewable @State var queue: [GenerationJob] = []
    StoryboardDetailView(
        acts: $acts, selection: nil, generationQueue: $queue,
        studios: [], studioIndex: 0, customerIndex: 0, episodeIndex: 0
    )
    .frame(width: 300, height: 600)
}
