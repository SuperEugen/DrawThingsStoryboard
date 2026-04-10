import SwiftUI

/// Right pane for the Storyboard section.
/// Selection cases now carry index paths for direct storyboard access.
struct StoryboardDetailView: View {

    @Binding var storyboards: StoryboardsFile
    let selectedStoryboardIndex: Int
    let selection: StoryboardSelection?
    @Binding var generationQueue: [GenerationJob]
    let assets: AssetsFile
    let styles: StylesFile
    let models: ModelsFile
    var config: AppConfig = AppConfig()

    // MARK: - Resolved from selection

    /// The storyboard index from the selection (acts/sequences/scenes carry it).
    private var activeStoryboardIndex: Int {
        switch selection {
        case .storyboard(let si): return si
        case .act(let si, _): return si
        case .sequence(let si, _, _): return si
        case .scene(let si, _, _, _): return si
        case .panel: return selectedStoryboardIndex
        case .none: return selectedStoryboardIndex
        }
    }

    private var storyboard: StoryboardEntry? {
        guard storyboards.storyboards.indices.contains(activeStoryboardIndex) else { return nil }
        return storyboards.storyboards[activeStoryboardIndex]
    }

    private var storyboardStyleID: String { storyboard?.styleID ?? "" }
    private var storyboardModelID: String { storyboard?.modelID ?? "" }

    private var resolvedStyleName: String {
        styles.styles.first { $0.styleID == storyboardStyleID }?.name ?? ""
    }

    private var resolvedStyleDescription: String {
        styles.styles.first { $0.styleID == storyboardStyleID }?.style ?? ""
    }

    var body: some View {
        if let selection {
            switch selection {
            case .storyboard(let si):
                if storyboards.storyboards.indices.contains(si) {
                    storyboardSettingsView(index: si)
                } else { emptyState }

            case .act(let si, let ai):
                if storyboards.storyboards.indices.contains(si),
                   storyboards.storyboards[si].acts.indices.contains(ai) {
                    NodeDetailWithPanels(
                        level: "Act",
                        name: $storyboards.storyboards[si].acts[ai].name,
                        color: .purple, icon: "theatermasks",
                        panels: panelsForAct(storyboards.storyboards[si].acts[ai]),
                        selection: Binding(get: { self.selection }, set: { _ in })
                    )
                } else { emptyState }

            case .sequence(let si, let ai, let seqi):
                if storyboards.storyboards.indices.contains(si),
                   storyboards.storyboards[si].acts.indices.contains(ai),
                   storyboards.storyboards[si].acts[ai].sequences.indices.contains(seqi) {
                    NodeDetailWithPanels(
                        level: "Sequence",
                        name: $storyboards.storyboards[si].acts[ai].sequences[seqi].name,
                        color: .orange, icon: "ellipsis.rectangle",
                        panels: panelsForSequence(storyboards.storyboards[si].acts[ai].sequences[seqi]),
                        selection: Binding(get: { self.selection }, set: { _ in })
                    )
                } else { emptyState }

            case .scene(let si, let ai, let seqi, let sci):
                if storyboards.storyboards.indices.contains(si),
                   storyboards.storyboards[si].acts.indices.contains(ai),
                   storyboards.storyboards[si].acts[ai].sequences.indices.contains(seqi),
                   storyboards.storyboards[si].acts[ai].sequences[seqi].scenes.indices.contains(sci) {
                    NodeDetailWithPanels(
                        level: "Scene",
                        name: $storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].name,
                        color: .teal, icon: "photo",
                        panels: storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].panels,
                        selection: Binding(get: { self.selection }, set: { _ in })
                    )
                } else { emptyState }

            case .panel(let id):
                if let (si, ai, seqi, sci, pi) = findPanel(id) {
                    PanelDetailView(
                        panel: $storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].panels[pi],
                        generationQueue: $generationQueue,
                        assets: assets,
                        styles: styles,
                        models: models,
                        config: config,
                        storyboardStyleID: storyboardStyleID,
                        storyboardModelID: storyboardModelID
                    )
                } else { emptyState }
            }
        } else {
            emptyState
        }
    }

    // MARK: - Storyboard settings

    @ViewBuilder
    private func storyboardSettingsView(index si: Int) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.indigo.opacity(0.12))
                        .frame(maxWidth: .infinity).frame(height: 100)
                        .overlay {
                            Image(systemName: "film").font(.system(size: 40))
                                .foregroundStyle(Color.indigo.opacity(0.6))
                        }
                    Text("Storyboard").font(.caption.weight(.medium))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())
                        .foregroundStyle(.secondary).padding(10)
                }

                Divider().padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Name")
                    TextField("Storyboard name", text: $storyboards.storyboards[si].name)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.bottom, 16)

                Divider().padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Model")
                    Text("The model used for generating all panels in this storyboard.")
                        .font(.caption).foregroundStyle(.secondary)
                    Picker("Model", selection: $storyboards.storyboards[si].modelID) {
                        ForEach(models.models) { m in
                            Text(m.name).tag(m.modelID)
                        }
                    }
                    .pickerStyle(.menu).labelsHidden().frame(maxWidth: 240)
                }
                .padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Style")
                    Text("The style applied to all panels. Assets must have variants for this style.")
                        .font(.caption).foregroundStyle(.secondary)
                    Picker("Style", selection: $storyboards.storyboards[si].styleID) {
                        ForEach(styles.styles) { s in
                            Text(s.name).tag(s.styleID)
                        }
                    }
                    .pickerStyle(.menu).labelsHidden().frame(maxWidth: 240)
                }
                .padding(.bottom, 16)

                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nothing selected", systemImage: "square.dashed",
            description: Text("Select a storyboard, act, sequence, scene, or panel."))
    }

    // MARK: - Helpers

    private func panelsForAct(_ act: ActEntry) -> [PanelEntry] {
        act.sequences.flatMap { $0.scenes.flatMap { $0.panels } }
    }

    private func panelsForSequence(_ seq: SequenceEntry) -> [PanelEntry] {
        seq.scenes.flatMap { $0.panels }
    }

    /// Find panel by ID across all storyboards.
    private func findPanel(_ id: String) -> (Int, Int, Int, Int, Int)? {
        for si in storyboards.storyboards.indices {
            for ai in storyboards.storyboards[si].acts.indices {
                for seqi in storyboards.storyboards[si].acts[ai].sequences.indices {
                    for sci in storyboards.storyboards[si].acts[ai].sequences[seqi].scenes.indices {
                        for pi in storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].panels.indices {
                            if storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].panels[pi].panelID == id {
                                return (si, ai, seqi, sci, pi)
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
}

// MARK: - Node detail with panel list

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

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        sectionLabel("Panels (\(panels.count))")
                        Spacer()
                        Button {
                            let headerTitle = "\(level) \u{2014} \(name)"
                            let filename = "\(name.replacingOccurrences(of: " ", with: "_")).pdf"
                            PDFExportService.exportWithSavePanel(
                                panels: panels,
                                headerTitle: headerTitle,
                                defaultFilename: filename
                            )
                        } label: {
                            Label("Export PDF", systemImage: "square.and.arrow.up").font(.caption)
                        }
                        .buttonStyle(.bordered).controlSize(.mini)
                        .disabled(panels.isEmpty)
                    }

                    if panels.isEmpty {
                        Text("No panels in this \(level.lowercased()).")
                            .font(.caption).foregroundStyle(.tertiary).padding(.vertical, 8)
                    } else {
                        ForEach(panels) { panel in
                            CompactPanelRow(panel: panel, isSelected: selection == .panel(panel.panelID))
                                .onTapGesture { selection = .panel(panel.panelID) }
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

// MARK: - Compact panel row

private struct CompactPanelRow: View {
    let panel: PanelEntry
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            if panel.hasSmallImage, let img = StorageService.shared.loadImage(id: panel.smallImageID) {
                Image(nsImage: img).resizable().scaledToFill()
                    .frame(width: 48, height: 27).clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.yellow.opacity(0.15)).frame(width: 48, height: 27)
                    .overlay { Image(systemName: "list.and.film").font(.system(size: 12)).foregroundStyle(Color.yellow.opacity(0.5)) }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(panel.name).font(.callout).lineLimit(1)
                if !panel.description.isEmpty {
                    Text(panel.description).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            HStack(spacing: 4) {
                if panel.hasSmallImage { Text("S").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.orange) }
                if panel.hasLargeImage { Text("L").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.green) }
                if !panel.refIDs.isEmpty { Text("\(panel.refIDs.count)R").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.blue) }
            }
        }
        .padding(.vertical, 4).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 7).fill(isSelected ? Color.accentColor.opacity(0.1) : Color.accentColor.opacity(0.03)))
        .contentShape(Rectangle())
    }
}

// MARK: - Panel detail

private struct PanelDetailView: View {
    @Binding var panel: PanelEntry
    @Binding var generationQueue: [GenerationJob]
    let assets: AssetsFile
    let styles: StylesFile
    let models: ModelsFile
    var config: AppConfig = AppConfig()
    var storyboardStyleID: String = ""
    var storyboardModelID: String = ""

    @State private var showLargeImageSheet = false

    private var resolvedStyleName: String {
        styles.styles.first { $0.styleID == storyboardStyleID }?.name ?? ""
    }

    private var styleDescription: String {
        styles.styles.first { $0.styleID == storyboardStyleID }?.style ?? ""
    }

    private var canGenerate: Bool {
        !storyboardStyleID.isEmpty && !storyboardModelID.isEmpty && hasDescription
    }

    private var assignedIDs: [String] {
        [panel.ref1ID, panel.ref2ID, panel.ref3ID, panel.ref4ID].filter { !$0.isEmpty }
    }

    private func asset(for id: String) -> AssetEntry? { assets.assets.first { $0.assetID == id } }
    private func bestImageID(for entry: AssetEntry) -> String { entry.bestImageID(forStyle: storyboardStyleID) }

    private var hasLocation: Bool { assignedIDs.contains { id in asset(for: id)?.isLocation == true } }
    private var locationImageID: String {
        for id in assignedIDs { if let e = asset(for: id), e.isLocation { return bestImageID(for: e) } }
        return ""
    }
    private var characterImageIDs: [String] {
        assignedIDs.compactMap { id in
            guard let e = asset(for: id), e.isCharacter else { return nil }
            let img = bestImageID(for: e); return img.isEmpty ? nil : img
        }
    }
    private var refCount: Int { assignedIDs.count }
    private var canAddMoreRefs: Bool { refCount < 4 }
    private var availableCharacters: [AssetEntry] { assets.assets.filter { $0.isCharacter && !assignedIDs.contains($0.assetID) } }
    private var availableLocations: [AssetEntry] {
        guard !hasLocation else { return [] }
        return assets.assets.filter { $0.isLocation && !assignedIDs.contains($0.assetID) }
    }
    private var hasDescription: Bool { !panel.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var isSmallQueued: Bool { generationQueue.contains { $0.panelID == panel.panelID && $0.jobType == .generatePanel && $0.size == .small } }
    private var isLargeQueued: Bool { generationQueue.contains { $0.panelID == panel.panelID && $0.jobType == .generatePanel && $0.size == .large } }
    private var combinedPrompt: String {
        var p: [String] = []
        if !styleDescription.isEmpty { p.append(styleDescription) }
        p.append(panel.description)
        if !panel.cameraMovement.isEmpty { p.append(panel.cameraMovement) }
        return p.joined(separator: ", ")
    }
    private var largeImage: NSImage? { panel.hasLargeImage ? StorageService.shared.loadImage(id: panel.largeImageID) : nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                let headerImageID = panel.hasLargeImage ? panel.largeImageID : panel.hasSmallImage ? panel.smallImageID : ""
                UnifiedThumbnailView(itemType: .panel, name: "", sizeMode: .header, imageID: headerImageID).padding(.bottom, 16)

                if storyboardStyleID.isEmpty || storyboardModelID.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Text("Assign a Model and Style to this storyboard before generating panels.")
                            .font(.caption).foregroundStyle(.orange)
                    }
                    .padding(.vertical, 8).padding(.horizontal, 8)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color.orange.opacity(0.1)))
                    .padding(.bottom, 12)
                }

                // Status
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Status")
                    smallImageStatusRow
                    largeImageStatusRow
                }.padding(.bottom, 12)

                Divider().padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Name")
                    TextField("Name", text: $panel.name).textFieldStyle(.roundedBorder)
                }.padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Description")
                    TextEditor(text: $panel.description).font(.callout).frame(minHeight: 80)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.25), lineWidth: 0.5))
                    if !hasDescription { Text("Add a description to enable image generation.").font(.caption2).foregroundStyle(.orange) }
                }.padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Camera Movement")
                    TextField("e.g. Pan left, Zoom in", text: $panel.cameraMovement).textFieldStyle(.roundedBorder)
                }.padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Dialogue")
                    TextEditor(text: $panel.dialogue).font(.callout).frame(minHeight: 60)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.25), lineWidth: 0.5))
                }.padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Duration")
                    HStack {
                        TextField("Seconds", value: $panel.duration, format: .number).textFieldStyle(.roundedBorder).frame(width: 80)
                        Text("seconds").font(.callout).foregroundStyle(.secondary)
                    }
                }.padding(.bottom, 12)

                Divider().padding(.vertical, 8)

                if panel.hasLargeImage, let img = largeImage {
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Large Image")
                        Button { showLargeImageSheet = true } label: {
                            Image(nsImage: img).resizable().scaledToFit()
                                .frame(maxWidth: .infinity).frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }.buttonStyle(.plain)
                    }.padding(.bottom, 12)
                    Divider().padding(.vertical, 8)
                }

                // Asset slots
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Referenced Assets (\(refCount)/4)")
                    ForEach(Array(assignedIDs.enumerated()), id: \.element) { index, assetID in
                        if let entry = asset(for: assetID) {
                            AssetSlotRow(asset: entry, slotIndex: index, onRemove: { removeAsset(id: assetID) })
                        }
                    }
                    if hasLocation && !locationImageID.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle.angled").font(.caption).foregroundStyle(.teal)
                            Text("Location \u{2192} canvas").font(.caption2).foregroundStyle(.secondary)
                        }.padding(.vertical, 2).padding(.horizontal, 8)
                    }
                    if !characterImageIDs.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "person.2.fill").font(.caption).foregroundStyle(.blue)
                            Text("\(characterImageIDs.count) character(s) \u{2192} moodboard").font(.caption2).foregroundStyle(.secondary)
                        }.padding(.vertical, 2).padding(.horizontal, 8)
                    }
                    if canAddMoreRefs { assetPickerMenu }
                }.padding(.bottom, 12)

                Spacer(minLength: 20)
            }.padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showLargeImageSheet) {
            PanelLargeImageSheet(image: largeImage, panelName: panel.name, isPresented: $showLargeImageSheet)
        }
    }

    @ViewBuilder private var smallImageStatusRow: some View {
        HStack(spacing: 8) {
            Text("S").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(panel.hasSmallImage ? .green : .gray)
            Text("Small Image:").font(.callout)
            Text(panel.hasSmallImage ? "available" : "not yet").font(.callout).foregroundStyle(panel.hasSmallImage ? .green : .secondary)
            Spacer()
            if !panel.hasSmallImage {
                if isSmallQueued { Text("Queued").font(.caption).foregroundStyle(.purple) }
                else { Button { generateImage(size: .small) } label: { Label("Generate", systemImage: "paintbrush.pointed").font(.caption) }.buttonStyle(.bordered).controlSize(.mini).disabled(!canGenerate) }
            }
        }.padding(.vertical, 5).padding(.horizontal, 8).background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.07)))
    }

    @ViewBuilder private var largeImageStatusRow: some View {
        HStack(spacing: 8) {
            Text("L").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(panel.hasLargeImage ? .green : .gray)
            Text("Large Image:").font(.callout)
            Text(panel.hasLargeImage ? "available" : "not yet").font(.callout).foregroundStyle(panel.hasLargeImage ? .green : .secondary)
            Spacer()
            if !panel.hasLargeImage {
                if isLargeQueued { Text("Queued").font(.caption).foregroundStyle(.purple) }
                else { Button { generateImage(size: .large) } label: { Label("Generate", systemImage: "arrow.up.left.and.arrow.down.right.rectangle").font(.caption) }.buttonStyle(.bordered).controlSize(.mini).disabled(!canGenerate) }
            }
            if panel.hasLargeImage { Button { showLargeImageSheet = true } label: { Image(systemName: "eye").font(.caption) }.buttonStyle(.bordered).controlSize(.mini) }
        }.padding(.vertical, 5).padding(.horizontal, 8).background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.07)))
    }

    @ViewBuilder private var assetPickerMenu: some View {
        Menu {
            if !availableLocations.isEmpty {
                Section("Locations") { ForEach(availableLocations) { loc in Button { assignAsset(id: loc.assetID) } label: { Label(loc.name, systemImage: loc.subType == "exterior" ? "tree" : "sofa") } } }
            }
            if !availableCharacters.isEmpty {
                Section("Characters") { ForEach(availableCharacters) { c in Button { assignAsset(id: c.assetID) } label: { Label(c.name, systemImage: c.subType == "female" ? "figure.stand.dress" : "figure.stand") } } }
            }
            if availableLocations.isEmpty && availableCharacters.isEmpty { Text("No assets available") }
        } label: { Label("Add Asset", systemImage: "plus.circle").font(.callout) }
        .menuStyle(.borderlessButton).frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 4)
    }

    private func assignAsset(id: String) { var c = assignedIDs; guard c.count < 4 else { return }; c.append(id); writeRefIDs(compacted(c)) }
    private func removeAsset(id: String) { var c = assignedIDs; c.removeAll { $0 == id }; writeRefIDs(compacted(c)) }
    private func compacted(_ ids: [String]) -> [String] {
        var loc: String?; var chars: [String] = []
        for id in ids { if let e = asset(for: id), e.isLocation { loc = id } else { chars.append(id) } }
        var r: [String] = []; if let l = loc { r.append(l) }; r.append(contentsOf: chars); return r
    }
    private func writeRefIDs(_ ids: [String]) {
        panel.ref1ID = ids.count > 0 ? ids[0] : ""; panel.ref2ID = ids.count > 1 ? ids[1] : ""
        panel.ref3ID = ids.count > 2 ? ids[2] : ""; panel.ref4ID = ids.count > 3 ? ids[3] : ""
    }
    private func generateImage(size: GenerationSize) {
        guard canGenerate else { return }
        let seed = panel.seed == 0 ? SeedHelper.randomSeed() : panel.seed
        let w = size == .large ? config.largeImageWidth : config.smallImageWidth
        let h = size == .large ? config.largeImageHeight : config.smallImageHeight
        let job = GenerationJob(
            id: UUID().uuidString, itemName: panel.name, jobType: .generatePanel,
            size: size, styleName: resolvedStyleName, queuedAt: Date(),
            estimatedDuration: size == .large ? 180 : 60, itemIcon: "list.and.film",
            seed: seed, width: w, height: h, combinedPrompt: combinedPrompt,
            styleID: storyboardStyleID, panelID: panel.panelID, modelID: storyboardModelID,
            initImageID: locationImageID, moodboardImageIDs: characterImageIDs
        )
        generationQueue.append(job)
    }
}

// MARK: - Asset slot row

private struct AssetSlotRow: View {
    let asset: AssetEntry; let slotIndex: Int; let onRemove: () -> Void
    private var assetIcon: String {
        asset.isCharacter ? (asset.subType == "female" ? "figure.stand.dress" : "figure.stand") : (asset.subType == "exterior" ? "tree" : "sofa")
    }
    var body: some View {
        HStack(spacing: 8) {
            Text("\(slotIndex + 1)").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(.secondary).frame(width: 16)
            Image(systemName: assetIcon).foregroundStyle(asset.isCharacter ? .blue : .teal).frame(width: 16)
            Text(asset.name).font(.callout).lineLimit(1); Spacer()
            Text(asset.subType).font(.caption).foregroundStyle(.secondary)
            if asset.isLocation { Image(systemName: "pin.fill").font(.system(size: 9)).foregroundStyle(.teal.opacity(0.6)) }
            Button(action: onRemove) { Image(systemName: "xmark.circle.fill").font(.system(size: 13)).symbolRenderingMode(.hierarchical).foregroundStyle(.secondary) }.buttonStyle(.plain)
        }.padding(.vertical, 5).padding(.horizontal, 8).background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.05)))
    }
}

// MARK: - Large image sheet

private struct PanelLargeImageSheet: View {
    let image: NSImage?; let panelName: String; @Binding var isPresented: Bool
    var body: some View {
        VStack(spacing: 0) {
            HStack { Text(panelName).font(.headline); Spacer(); Button { isPresented = false } label: { Image(systemName: "xmark.circle.fill").font(.title2).symbolRenderingMode(.hierarchical).foregroundStyle(.secondary) }.buttonStyle(.plain) }.padding()
            if let img = image { Image(nsImage: img).resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: .infinity).padding(.horizontal).padding(.bottom) }
            else { ContentUnavailableView("Image not found", systemImage: "photo", description: Text("The large image file could not be loaded.")) }
        }.frame(minWidth: 800, minHeight: 500)
    }
}
