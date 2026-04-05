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

private struct PanelDetailView: View {
    @Binding var panel: PanelEntry
    @Binding var generationQueue: [GenerationJob]
    let assets: AssetsFile
    var resolvedStyleName: String? = nil
    var styleDescription: String = ""
    var config: AppConfig = AppConfig()

    @State private var showLargeImageSheet = false

    private var attachedAssets: [AssetEntry] {
        panel.refIDs.compactMap { refID in
            assets.assets.first { $0.assetID == refID }
        }
    }

    private var refCount: Int { panel.refIDs.count }
    private var canAddMoreRefs: Bool { refCount < 4 }

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
                // Header: show generated image if available
                let headerImageID = panel.hasLargeImage ? panel.largeImageID
                    : panel.hasSmallImage ? panel.smallImageID : ""
                UnifiedThumbnailView(itemType: .panel, name: "", sizeMode: .header, imageID: headerImageID)
                    .padding(.bottom, 16)

                // Status with Generate buttons
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Status")
                    smallImageStatusRow
                    largeImageStatusRow
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
                    if !hasDescription {
                        Text("Add a description to enable image generation.")
                            .font(.caption2).foregroundStyle(.orange)
                    }
                }
                .padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Camera Movement")
                    TextField("e.g. Pan left, Zoom in", text: $panel.cameraMovement)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Dialogue")
                    TextEditor(text: $panel.dialogue).font(.callout).frame(minHeight: 60)
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5))
                }
                .padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Duration")
                    HStack {
                        TextField("Seconds", value: $panel.duration, format: .number)
                            .textFieldStyle(.roundedBorder).frame(width: 80)
                        Text("seconds").font(.callout).foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 12)

                Divider().padding(.vertical, 8)

                // Large image preview
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

                // Referenced Assets
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Referenced Assets (\(refCount)/4)")
                    if !canAddMoreRefs {
                        Text("Maximum 4 asset references reached (Draw Things limit).")
                            .font(.caption2).foregroundStyle(.orange)
                    }
                    if attachedAssets.isEmpty {
                        Text("No assets referenced. Edit ref1ID\u{2013}ref4ID in the JSON to assign assets.")
                            .font(.caption).foregroundStyle(.tertiary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(attachedAssets) { asset in
                            HStack(spacing: 8) {
                                Image(systemName: asset.isCharacter ? "person.fill" : "map")
                                    .foregroundStyle(asset.isCharacter ? .blue : .teal)
                                Text(asset.name).font(.callout)
                                Spacer()
                                Text(asset.subType).font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4).padding(.horizontal, 8)
                            .background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.05)))
                        }
                    }
                }
                .padding(.bottom, 12)
                .help("Maximum 4 asset references per panel (Draw Things limitation)")

                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showLargeImageSheet) {
            PanelLargeImageSheet(image: largeImage, panelName: panel.name, isPresented: $showLargeImageSheet)
        }
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
            panelID: panel.panelID
        )
        generationQueue.append(job)
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
