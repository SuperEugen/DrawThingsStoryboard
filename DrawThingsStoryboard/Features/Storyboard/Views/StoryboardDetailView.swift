import SwiftUI

/// Right pane for the Storyboard section.
/// #45: Panel list for parent nodes (Act, Sequence, Scene)
struct StoryboardDetailView: View {

    @Binding var acts: [ActEntry]
    let selection: StoryboardSelection?
    @Binding var generationQueue: [GenerationJob]
    let assets: AssetsFile
    var resolvedStyleName: String? = nil
    var styleDescription: String = ""
    var config: AppConfig = AppConfig()

    var body: some View {
        if let selection {
            switch selection {
            case .act(let name):
                if let idx = acts.firstIndex(where: { $0.name == name }) {
                    NodeDetailWithPanels(
                        level: "Act", name: $acts[idx].name, color: .purple,
                        icon: "theatermask.and.paintbrush",
                        panels: panelsForAct(acts[idx]),
                        selection: Binding(
                            get: { self.selection },
                            set: { _ in }
                        )
                    )
                } else { emptyState }

            case .sequence(let name):
                if let (ai, si) = findSequence(name) {
                    NodeDetailWithPanels(
                        level: "Sequence", name: $acts[ai].sequences[si].name, color: .orange,
                        icon: "arrow.triangle.branch",
                        panels: panelsForSequence(acts[ai].sequences[si]),
                        selection: Binding(
                            get: { self.selection },
                            set: { _ in }
                        )
                    )
                } else { emptyState }

            case .scene(let name):
                if let (ai, si, sci) = findScene(name) {
                    NodeDetailWithPanels(
                        level: "Scene", name: $acts[ai].sequences[si].scenes[sci].name, color: .teal,
                        icon: "rectangle.on.rectangle",
                        panels: acts[ai].sequences[si].scenes[sci].panels,
                        selection: Binding(
                            get: { self.selection },
                            set: { _ in }
                        )
                    )
                } else { emptyState }

            case .panel(let id):
                if let (ai, si, sci, pi) = findPanel(id) {
                    PanelDetailView(
                        panel: $acts[ai].sequences[si].scenes[sci].panels[pi],
                        generationQueue: $generationQueue,
                        assets: assets,
                        resolvedStyleName: resolvedStyleName,
                        styleDescription: styleDescription,
                        config: config
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
            description: Text("Select an act, sequence, scene, or panel."))
    }

    // MARK: - Panel collection helpers

    private func panelsForAct(_ act: ActEntry) -> [PanelEntry] {
        act.sequences.flatMap { seq in
            seq.scenes.flatMap { $0.panels }
        }
    }

    private func panelsForSequence(_ seq: SequenceEntry) -> [PanelEntry] {
        seq.scenes.flatMap { $0.panels }
    }

    // MARK: - Find helpers

    private func findSequence(_ name: String) -> (Int, Int)? {
        for ai in acts.indices {
            for si in acts[ai].sequences.indices {
                if acts[ai].sequences[si].name == name { return (ai, si) }
            }
        }
        return nil
    }

    private func findScene(_ name: String) -> (Int, Int, Int)? {
        for ai in acts.indices {
            for si in acts[ai].sequences.indices {
                for sci in acts[ai].sequences[si].scenes.indices {
                    if acts[ai].sequences[si].scenes[sci].name == name { return (ai, si, sci) }
                }
            }
        }
        return nil
    }

    private func findPanel(_ id: String) -> (Int, Int, Int, Int)? {
        for ai in acts.indices {
            for si in acts[ai].sequences.indices {
                for sci in acts[ai].sequences[si].scenes.indices {
                    for pi in acts[ai].sequences[si].scenes[sci].panels.indices {
                        if acts[ai].sequences[si].scenes[sci].panels[pi].panelID == id { return (ai, si, sci, pi) }
                    }
                }
            }
        }
        return nil
    }
}

// MARK: - Node detail with panel list
/// #45: Shows name editor + list of all descendant panels

private struct NodeDetailWithPanels: View {
    let level: String
    @Binding var name: String
    let color: Color
    let icon: String
    let panels: [PanelEntry]
    @Binding var selection: StoryboardSelection?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.12))
                        .frame(maxWidth: .infinity).frame(height: 100)
                        .overlay {
                            Image(systemName: icon).font(.system(size: 40))
                                .foregroundStyle(color.opacity(0.6))
                        }
                    Text(level).font(.caption.weight(.medium))
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

                Divider().padding(.vertical, 8)

                // Panel list
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Panels (\(panels.count))")
                    if panels.isEmpty {
                        Text("No panels in this \(level.lowercased()).")
                            .font(.caption).foregroundStyle(.tertiary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(panels) { panel in
                            CompactPanelRow(panel: panel, isSelected: selection == .panel(panel.panelID))
                                .onTapGesture {
                                    selection = .panel(panel.panelID)
                                }
                        }
                    }
                }
                .padding(.bottom, 16)

                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Compact panel row for parent detail views

private struct CompactPanelRow: View {
    let panel: PanelEntry
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Thumbnail or placeholder
            if panel.hasSmallImage, let img = StorageService.shared.loadImage(id: panel.smallImageID) {
                Image(nsImage: img)
                    .resizable().scaledToFill()
                    .frame(width: 48, height: 27)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 48, height: 27)
                    .overlay {
                        Image(systemName: "photo").font(.system(size: 12))
                            .foregroundStyle(Color.yellow.opacity(0.5))
                    }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(panel.name).font(.callout).lineLimit(1)
                if !panel.description.isEmpty {
                    Text(panel.description).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }

            Spacer()

            // Status badges
            HStack(spacing: 4) {
                if panel.hasSmallImage {
                    Text("S").font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.orange)
                }
                if panel.hasLargeImage {
                    Text("L").font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.green)
                }
                if !panel.refIDs.isEmpty {
                    Text("\(panel.refIDs.count)R").font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, 4).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 7)
            .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.accentColor.opacity(0.03)))
        .contentShape(Rectangle())
    }
}

// MARK: - Panel detail
/// #42: Interactive asset slots with location-first constraint
/// #43: Location image passed as canvas/init image to gRPC
/// #44: Character images passed as moodboard/shuffle hints to gRPC

private struct PanelDetailView: View {
    @Binding var panel: PanelEntry
    @Binding var generationQueue: [GenerationJob]
    let assets: AssetsFile
    var resolvedStyleName: String? = nil
    var styleDescription: String = ""
    var config: AppConfig = AppConfig()

    @State private var showLargeImageSheet = false

    // MARK: - Asset slot helpers

    private var assignedIDs: [String] {
        [panel.ref1ID, panel.ref2ID, panel.ref3ID, panel.ref4ID].filter { !$0.isEmpty }
    }

    private func asset(for id: String) -> AssetEntry? {
        assets.assets.first { $0.assetID == id }
    }

    private func bestImageID(for entry: AssetEntry) -> String {
        if entry.hasLargeImage { return entry.largeImageID }
        if let idx = entry.approvedVariantIndex {
            let v = entry.variant(at: idx)
            if v.hasImage { return v.smallImageID }
        }
        for i in 0..<4 {
            let v = entry.variant(at: i)
            if v.hasImage { return v.smallImageID }
        }
        return ""
    }

    private var hasLocation: Bool {
        assignedIDs.contains { id in asset(for: id)?.isLocation == true }
    }

    private var locationAsset: AssetEntry? {
        for id in assignedIDs {
            if let entry = asset(for: id), entry.isLocation { return entry }
        }
        return nil
    }

    private var locationImageID: String {
        guard let loc = locationAsset else { return "" }
        return bestImageID(for: loc)
    }

    private var characterImageIDs: [String] {
        assignedIDs.compactMap { id -> String? in
            guard let entry = asset(for: id), entry.isCharacter else { return nil }
            let imgID = bestImageID(for: entry)
            return imgID.isEmpty ? nil : imgID
        }
    }

    private var refCount: Int { assignedIDs.count }
    private var canAddMoreRefs: Bool { refCount < 4 }

    private var availableCharacters: [AssetEntry] {
        assets.assets.filter { $0.isCharacter && !assignedIDs.contains($0.assetID) }
    }

    private var availableLocations: [AssetEntry] {
        guard !hasLocation else { return [] }
        return assets.assets.filter { $0.isLocation && !assignedIDs.contains($0.assetID) }
    }

    private var hasDescription: Bool {
        !panel.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isSmallQueued: Bool {
        generationQueue.contains {
            $0.panelID == panel.panelID && $0.jobType == .generatePanel && $0.size == .small
        }
    }

    private var isLargeQueued: Bool {
        generationQueue.contains {
            $0.panelID == panel.panelID && $0.jobType == .generatePanel && $0.size == .large
        }
    }

    private var combinedPrompt: String {
        var parts: [String] = []
        if !styleDescription.isEmpty { parts.append(styleDescription) }
        parts.append(panel.description)
        if !panel.cameraMovement.isEmpty { parts.append(panel.cameraMovement) }
        return parts.joined(separator: ", ")
    }

    private var largeImage: NSImage? {
        guard panel.hasLargeImage else { return nil }
        return StorageService.shared.loadImage(id: panel.largeImageID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                panelHeader
                statusSection
                Divider().padding(.vertical, 8)
                nameSection
                descriptionSection
                cameraSection
                dialogueSection
                durationSection
                Divider().padding(.vertical, 8)
                largeImageSection
                assetSlotsSection
                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showLargeImageSheet) {
            PanelLargeImageSheet(image: largeImage, panelName: panel.name, isPresented: $showLargeImageSheet)
        }
    }

    @ViewBuilder private var panelHeader: some View {
        let headerImageID = panel.hasLargeImage ? panel.largeImageID
            : panel.hasSmallImage ? panel.smallImageID : ""
        UnifiedThumbnailView(itemType: .panel, name: "", sizeMode: .header, imageID: headerImageID)
            .padding(.bottom, 16)
    }

    @ViewBuilder private var statusSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Status")
            smallImageStatusRow
            largeImageStatusRow
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder private var nameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Name")
            TextField("Name", text: $panel.name).textFieldStyle(.roundedBorder)
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Description")
            TextEditor(text: $panel.description).font(.callout).frame(minHeight: 80)
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5))
            if !hasDescription {
                Text("Add a description to enable image generation.")
                    .font(.caption2).foregroundStyle(.orange)
            }
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder private var cameraSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Camera Movement")
            TextField("e.g. Pan left, Zoom in", text: $panel.cameraMovement)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder private var dialogueSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Dialogue")
            TextEditor(text: $panel.dialogue).font(.callout).frame(minHeight: 60)
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5))
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder private var durationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Duration")
            HStack {
                TextField("Seconds", value: $panel.duration, format: .number)
                    .textFieldStyle(.roundedBorder).frame(width: 80)
                Text("seconds").font(.callout).foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder private var largeImageSection: some View {
        if panel.hasLargeImage {
            VStack(alignment: .leading, spacing: 6) {
                sectionLabel("Large Image")
                if let img = largeImage {
                    Button { showLargeImageSheet = true } label: {
                        Image(nsImage: img)
                            .resizable().scaledToFit()
                            .frame(maxWidth: .infinity).frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain).help("Click to view full size")
                }
            }
            .padding(.bottom, 12)
            Divider().padding(.vertical, 8)
        }
    }

    @ViewBuilder private var assetSlotsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Referenced Assets (\(refCount)/4)")
            if !canAddMoreRefs {
                Text("Maximum 4 asset references reached (Draw Things limit).")
                    .font(.caption2).foregroundStyle(.orange)
            }
            ForEach(Array(assignedIDs.enumerated()), id: \.element) { index, assetID in
                if let entry = asset(for: assetID) {
                    AssetSlotRow(asset: entry, slotIndex: index, onRemove: {
                        removeAsset(id: assetID)
                    })
                }
            }
            assetTransferIndicators
            if canAddMoreRefs { assetPickerMenu }
            if assignedIDs.isEmpty && !canAddMoreRefs {
                Text("No assets referenced.")
                    .font(.caption).foregroundStyle(.tertiary).padding(.vertical, 8)
            }
        }
        .padding(.bottom, 12)
        .help("Maximum 4 asset references per panel (Draw Things limitation). Location always in slot 1.")
    }

    @ViewBuilder private var assetTransferIndicators: some View {
        if hasLocation && !locationImageID.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "photo.on.rectangle.angled").font(.caption).foregroundStyle(.teal)
                Text("Location \u{2192} canvas").font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.vertical, 2).padding(.horizontal, 8)
        }
        if !characterImageIDs.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill").font(.caption).foregroundStyle(.blue)
                Text("\(characterImageIDs.count) character(s) \u{2192} moodboard hints")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.vertical, 2).padding(.horizontal, 8)
        }
    }

    @ViewBuilder private var assetPickerMenu: some View {
        Menu {
            if !availableLocations.isEmpty {
                Section("Locations") {
                    ForEach(availableLocations) { loc in
                        Button { assignAsset(id: loc.assetID) } label: {
                            Label(loc.name, systemImage: loc.subType == "exterior" ? "map" : "house.fill")
                        }
                    }
                }
            }
            if !availableCharacters.isEmpty {
                Section("Characters") {
                    ForEach(availableCharacters) { char in
                        Button { assignAsset(id: char.assetID) } label: {
                            Label(char.name, systemImage: "person.fill")
                        }
                    }
                }
            }
            if availableLocations.isEmpty && availableCharacters.isEmpty {
                Text("No assets available")
            }
        } label: {
            Label("Add Asset", systemImage: "plus.circle").font(.callout)
        }
        .menuStyle(.borderlessButton)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private func assignAsset(id: String) {
        var current = assignedIDs
        guard current.count < 4 else { return }
        current.append(id)
        writeRefIDs(compacted(current))
    }

    private func removeAsset(id: String) {
        var current = assignedIDs
        current.removeAll { $0 == id }
        writeRefIDs(compacted(current))
    }

    private func compacted(_ ids: [String]) -> [String] {
        var locationID: String? = nil
        var characterIDs: [String] = []
        for id in ids {
            if let entry = asset(for: id), entry.isLocation { locationID = id }
            else { characterIDs.append(id) }
        }
        var result: [String] = []
        if let loc = locationID { result.append(loc) }
        result.append(contentsOf: characterIDs)
        return result
    }

    private func writeRefIDs(_ ids: [String]) {
        panel.ref1ID = ids.count > 0 ? ids[0] : ""
        panel.ref2ID = ids.count > 1 ? ids[1] : ""
        panel.ref3ID = ids.count > 2 ? ids[2] : ""
        panel.ref4ID = ids.count > 3 ? ids[3] : ""
    }

    @ViewBuilder private var smallImageStatusRow: some View {
        HStack(spacing: 8) {
            Text("S").font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(panel.hasSmallImage ? .green : .gray)
            Text("Small Image:").font(.callout)
            Text(panel.hasSmallImage ? "available" : "not yet").font(.callout)
                .foregroundStyle(panel.hasSmallImage ? .green : .secondary)
            Spacer()
            if !panel.hasSmallImage {
                if isSmallQueued {
                    Text("Queued").font(.caption).foregroundStyle(.purple)
                } else {
                    Button { generateImage(size: .small) } label: {
                        Label("Generate", systemImage: "photo").font(.caption)
                    }
                    .buttonStyle(.bordered).controlSize(.mini).disabled(!hasDescription)
                }
            }
        }
        .padding(.vertical, 5).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.07)))
    }

    @ViewBuilder private var largeImageStatusRow: some View {
        HStack(spacing: 8) {
            Text("L").font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(panel.hasLargeImage ? .green : .gray)
            Text("Large Image:").font(.callout)
            Text(panel.hasLargeImage ? "available" : "not yet").font(.callout)
                .foregroundStyle(panel.hasLargeImage ? .green : .secondary)
            Spacer()
            if !panel.hasLargeImage {
                if isLargeQueued {
                    Text("Queued").font(.caption).foregroundStyle(.purple)
                } else {
                    Button { generateImage(size: .large) } label: {
                        Label("Generate", systemImage: "arrow.up.left.and.arrow.down.right").font(.caption)
                    }
                    .buttonStyle(.bordered).controlSize(.mini).disabled(!hasDescription)
                }
            }
            if panel.hasLargeImage {
                Button { showLargeImageSheet = true } label: {
                    Image(systemName: "eye").font(.caption)
                }
                .buttonStyle(.bordered).controlSize(.mini).help("View large image")
            }
        }
        .padding(.vertical, 5).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.07)))
    }

    private func generateImage(size: GenerationSize) {
        guard hasDescription else { return }
        let seed = panel.seed == 0 ? SeedHelper.randomSeed() : panel.seed
        let w = size == .large ? config.largeImageWidth : config.smallImageWidth
        let h = size == .large ? config.largeImageHeight : config.smallImageHeight
        let job = GenerationJob(
            id: UUID().uuidString, itemName: panel.name, jobType: .generatePanel,
            size: size, styleName: resolvedStyleName ?? "", queuedAt: Date(),
            estimatedDuration: size == .large ? 180 : 60, itemIcon: "video.fill",
            seed: seed, width: w, height: h, combinedPrompt: combinedPrompt,
            panelID: panel.panelID, initImageID: locationImageID,
            moodboardImageIDs: characterImageIDs
        )
        generationQueue.append(job)
    }
}

// MARK: - Asset slot row

private struct AssetSlotRow: View {
    let asset: AssetEntry
    let slotIndex: Int
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("\(slotIndex + 1)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary).frame(width: 16)
            Image(systemName: asset.isCharacter ? "person.fill" : "map")
                .foregroundStyle(asset.isCharacter ? .blue : .teal).frame(width: 16)
            Text(asset.name).font(.callout).lineLimit(1)
            Spacer()
            Text(asset.subType).font(.caption).foregroundStyle(.secondary)
            if asset.isLocation {
                Image(systemName: "pin.fill").font(.system(size: 9))
                    .foregroundStyle(.teal.opacity(0.6)).help("Location always in slot 1")
            }
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill").font(.system(size: 13))
                    .symbolRenderingMode(.hierarchical).foregroundStyle(.secondary)
            }
            .buttonStyle(.plain).help("Remove asset reference")
        }
        .padding(.vertical, 5).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.05)))
    }
}

// MARK: - Large image sheet

private struct PanelLargeImageSheet: View {
    let image: NSImage?
    let panelName: String
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(panelName).font(.headline)
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2).symbolRenderingMode(.hierarchical).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            if let img = image {
                Image(nsImage: img).resizable().scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal).padding(.bottom)
            } else {
                ContentUnavailableView("Image not found", systemImage: "photo",
                    description: Text("The large image file could not be loaded."))
            }
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}
