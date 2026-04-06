import SwiftUI

/// Right pane for the Storyboard section.
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
                    NodeDetailView(level: "Act", name: $acts[idx].name, color: .purple, icon: "theatermask.and.paintbrush")
                } else { emptyState }

            case .sequence(let name):
                if let (ai, si) = findSequence(name) {
                    NodeDetailView(level: "Sequence", name: $acts[ai].sequences[si].name, color: .orange, icon: "arrow.triangle.branch")
                } else { emptyState }

            case .scene(let name):
                if let (ai, si, sci) = findScene(name) {
                    NodeDetailView(level: "Scene", name: $acts[ai].sequences[si].scenes[sci].name, color: .teal, icon: "rectangle.on.rectangle")
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

// MARK: - Node detail (Act / Sequence / Scene)

private struct NodeDetailView: View {
    let level: String
    @Binding var name: String
    let color: Color
    let icon: String

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

                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Panel detail
/// #42: Interactive asset slots with location-first constraint
/// #43: Location image passed as canvas/init image to gRPC

private struct PanelDetailView: View {
    @Binding var panel: PanelEntry
    @Binding var generationQueue: [GenerationJob]
    let assets: AssetsFile
    var resolvedStyleName: String? = nil
    var styleDescription: String = ""
    var config: AppConfig = AppConfig()

    @State private var showLargeImageSheet = false

    // MARK: - Asset slot helpers

    /// Ordered list of currently assigned asset IDs (non-empty refs).
    private var assignedIDs: [String] {
        [panel.ref1ID, panel.ref2ID, panel.ref3ID, panel.ref4ID].filter { !$0.isEmpty }
    }

    /// Resolve an asset entry by ID.
    private func asset(for id: String) -> AssetEntry? {
        assets.assets.first { $0.assetID == id }
    }

    /// Whether a location is already assigned.
    private var hasLocation: Bool {
        assignedIDs.contains { id in
            asset(for: id)?.isLocation == true
        }
    }

    /// The assigned location asset, if any.
    private var locationAsset: AssetEntry? {
        for id in assignedIDs {
            if let entry = asset(for: id), entry.isLocation {
                return entry
            }
        }
        return nil
    }

    /// #43: Resolve the best image ID from a location asset for use as init image.
    /// Prefers largeImageID, then approved variant, then first variant with image.
    private var locationImageID: String {
        guard let loc = locationAsset else { return "" }
        if loc.hasLargeImage { return loc.largeImageID }
        if let idx = loc.approvedVariantIndex {
            let v = loc.variant(at: idx)
            if v.hasImage { return v.smallImageID }
        }
        for i in 0..<4 {
            let v = loc.variant(at: i)
            if v.hasImage { return v.smallImageID }
        }
        return ""
    }

    /// Number of currently assigned refs.
    private var refCount: Int { assignedIDs.count }
    private var canAddMoreRefs: Bool { refCount < 4 }

    /// Assets available for the picker (not already assigned).
    private var availableCharacters: [AssetEntry] {
        assets.assets.filter { $0.isCharacter && !assignedIDs.contains($0.assetID) }
    }

    /// Locations available — only if no location is assigned yet.
    private var availableLocations: [AssetEntry] {
        guard !hasLocation else { return [] }
        return assets.assets.filter { $0.isLocation && !assignedIDs.contains($0.assetID) }
    }

    /// Whether the description is filled in enough to generate.
    private var hasDescription: Bool {
        !panel.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Check if a small image job is already queued.
    private var isSmallQueued: Bool {
        generationQueue.contains {
            $0.panelID == panel.panelID && $0.jobType == .generatePanel && $0.size == .small
        }
    }

    /// Check if a large image job is already queued.
    private var isLargeQueued: Bool {
        generationQueue.contains {
            $0.panelID == panel.panelID && $0.jobType == .generatePanel && $0.size == .large
        }
    }

    /// Build the combined prompt for this panel.
    private var combinedPrompt: String {
        var parts: [String] = []
        if !styleDescription.isEmpty { parts.append(styleDescription) }
        parts.append(panel.description)
        if !panel.cameraMovement.isEmpty { parts.append(panel.cameraMovement) }
        return parts.joined(separator: ", ")
    }

    /// Load large image from disk.
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

    // MARK: - Header

    @ViewBuilder
    private var panelHeader: some View {
        let headerImageID = panel.hasLargeImage ? panel.largeImageID
            : panel.hasSmallImage ? panel.smallImageID : ""
        UnifiedThumbnailView(itemType: .panel, name: "", sizeMode: .header, imageID: headerImageID)
            .padding(.bottom, 16)
    }

    // MARK: - Status

    @ViewBuilder
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Status")
            smallImageStatusRow
            largeImageStatusRow
        }
        .padding(.bottom, 12)
    }

    // MARK: - Fields

    @ViewBuilder
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Name")
            TextField("Name", text: $panel.name).textFieldStyle(.roundedBorder)
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var descriptionSection: some View {
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

    @ViewBuilder
    private var cameraSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Camera Movement")
            TextField("e.g. Pan left, Zoom in", text: $panel.cameraMovement)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var dialogueSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Dialogue")
            TextEditor(text: $panel.dialogue).font(.callout).frame(minHeight: 60)
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5))
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var durationSection: some View {
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

    // MARK: - Large image preview

    @ViewBuilder
    private var largeImageSection: some View {
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
                    .buttonStyle(.plain)
                    .help("Click to view full size")
                }
            }
            .padding(.bottom, 12)
            Divider().padding(.vertical, 8)
        }
    }

    // MARK: - #42 Asset Slots

    @ViewBuilder
    private var assetSlotsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Referenced Assets (\(refCount)/4)")
            if !canAddMoreRefs {
                Text("Maximum 4 asset references reached (Draw Things limit).")
                    .font(.caption2).foregroundStyle(.orange)
            }

            // Show assigned slots
            ForEach(Array(assignedIDs.enumerated()), id: \.element) { index, assetID in
                if let entry = asset(for: assetID) {
                    AssetSlotRow(asset: entry, slotIndex: index, onRemove: {
                        removeAsset(id: assetID)
                    })
                }
            }

            // #43: Show init image indicator when location has an image
            if hasLocation && !locationImageID.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.caption).foregroundStyle(.teal)
                    Text("Location image will be sent as canvas to Draw Things")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                .padding(.vertical, 3).padding(.horizontal, 8)
            }

            // Add button when slots available
            if canAddMoreRefs {
                assetPickerMenu
            }

            if assignedIDs.isEmpty && !canAddMoreRefs {
                Text("No assets referenced.")
                    .font(.caption).foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            }
        }
        .padding(.bottom, 12)
        .help("Maximum 4 asset references per panel (Draw Things limitation). Location always in slot 1.")
    }

    @ViewBuilder
    private var assetPickerMenu: some View {
        Menu {
            if !availableLocations.isEmpty {
                Section("Locations") {
                    ForEach(availableLocations) { loc in
                        Button {
                            assignAsset(id: loc.assetID)
                        } label: {
                            Label(loc.name, systemImage: loc.subType == "exterior" ? "map" : "house.fill")
                        }
                    }
                }
            }
            if !availableCharacters.isEmpty {
                Section("Characters") {
                    ForEach(availableCharacters) { char in
                        Button {
                            assignAsset(id: char.assetID)
                        } label: {
                            Label(char.name, systemImage: "person.fill")
                        }
                    }
                }
            }
            if availableLocations.isEmpty && availableCharacters.isEmpty {
                Text("No assets available")
            }
        } label: {
            Label("Add Asset", systemImage: "plus.circle")
                .font(.callout)
        }
        .menuStyle(.borderlessButton)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    // MARK: - Assign / Remove with location-first compaction

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

    /// Compact: location always first, then characters in order.
    private func compacted(_ ids: [String]) -> [String] {
        var locationID: String? = nil
        var characterIDs: [String] = []
        for id in ids {
            if let entry = asset(for: id), entry.isLocation {
                locationID = id
            } else {
                characterIDs.append(id)
            }
        }
        var result: [String] = []
        if let loc = locationID { result.append(loc) }
        result.append(contentsOf: characterIDs)
        return result
    }

    /// Write up to 4 ref IDs back to the panel, padding with empty strings.
    private func writeRefIDs(_ ids: [String]) {
        panel.ref1ID = ids.count > 0 ? ids[0] : ""
        panel.ref2ID = ids.count > 1 ? ids[1] : ""
        panel.ref3ID = ids.count > 2 ? ids[2] : ""
        panel.ref4ID = ids.count > 3 ? ids[3] : ""
    }

    // MARK: - Status rows with Generate buttons

    @ViewBuilder
    private var smallImageStatusRow: some View {
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
                    .buttonStyle(.bordered).controlSize(.mini)
                    .disabled(!hasDescription)
                }
            }
        }
        .padding(.vertical, 5).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.07)))
    }

    @ViewBuilder
    private var largeImageStatusRow: some View {
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
                    .buttonStyle(.bordered).controlSize(.mini)
                    .disabled(!hasDescription)
                }
            }
            if panel.hasLargeImage {
                Button { showLargeImageSheet = true } label: {
                    Image(systemName: "eye").font(.caption)
                }
                .buttonStyle(.bordered).controlSize(.mini)
                .help("View large image")
            }
        }
        .padding(.vertical, 5).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.07)))
    }

    // MARK: - Generate
    /// #43: Includes initImageID when a location asset with an image is assigned.

    private func generateImage(size: GenerationSize) {
        guard hasDescription else { return }
        let seed = panel.seed == 0 ? SeedHelper.randomSeed() : panel.seed
        let w = size == .large ? config.largeImageWidth : config.smallImageWidth
        let h = size == .large ? config.largeImageHeight : config.smallImageHeight
        let job = GenerationJob(
            id: UUID().uuidString,
            itemName: panel.name,
            jobType: .generatePanel,
            size: size,
            styleName: resolvedStyleName ?? "",
            queuedAt: Date(),
            estimatedDuration: size == .large ? 180 : 60,
            itemIcon: "video.fill",
            seed: seed,
            width: w,
            height: h,
            combinedPrompt: combinedPrompt,
            panelID: panel.panelID,
            initImageID: locationImageID
        )
        generationQueue.append(job)
    }
}

// MARK: - #42 Asset slot row

private struct AssetSlotRow: View {
    let asset: AssetEntry
    let slotIndex: Int
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Slot number badge
            Text("\(slotIndex + 1)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Image(systemName: asset.isCharacter ? "person.fill" : "map")
                .foregroundStyle(asset.isCharacter ? .blue : .teal)
                .frame(width: 16)

            Text(asset.name).font(.callout).lineLimit(1)

            Spacer()

            Text(asset.subType).font(.caption).foregroundStyle(.secondary)

            if asset.isLocation {
                Image(systemName: "pin.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.teal.opacity(0.6))
                    .help("Location always in slot 1")
            }

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Remove asset reference")
        }
        .padding(.vertical, 5).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.05)))
    }
}

// MARK: - Large image sheet for panels

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
