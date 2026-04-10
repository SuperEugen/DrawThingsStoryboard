import SwiftUI

// MARK: - Assets detail
/// #80: Variant regeneration (Generate 4 / Regenerate 4 + confirmation dialog)
/// #81: Large image carousel at top, variants collapsible per style

struct AssetsDetailView: View {
    @Binding var assets: AssetsFile
    let selectedAssetID: String?
    @Binding var generationQueue: [GenerationJob]
    let config: AppConfig
    let styles: StylesFile
    var assetModelID: String = ""

    private var selectedIndex: Int? {
        guard let id = selectedAssetID else { return nil }
        return assets.assets.firstIndex { $0.assetID == id }
    }

    var body: some View {
        if let idx = selectedIndex {
            AssetEditorView(
                asset: $assets.assets[idx],
                generationQueue: $generationQueue,
                config: config,
                styles: styles,
                assetModelID: assetModelID
            )
            .id(assets.assets[idx].assetID) // #81: Reset state when switching assets
        } else {
            ContentUnavailableView(
                "No asset selected",
                systemImage: "person.crop.square.on.square.angled",
                description: Text("Select an asset to edit.")
            )
        }
    }
}

// MARK: - Asset editor

private struct AssetEditorView: View {
    @Binding var asset: AssetEntry
    @Binding var generationQueue: [GenerationJob]
    let config: AppConfig
    let styles: StylesFile
    let assetModelID: String
    @State private var showLargeImageSheet = false
    @State private var largeImageSheetStyleID: String = ""
    /// #81: Current carousel index for large images
    @State private var carouselStyleIndex: Int = 0

    private var assetTypeIcon: String {
        if asset.isCharacter {
            switch asset.subType {
            case "female": return "figure.stand.dress"
            case "male":   return "figure.stand"
            default:        return "dog"
            }
        } else {
            return asset.subType == "exterior" ? "tree" : "sofa"
        }
    }

    private var jobItemIcon: String {
        asset.isCharacter ? "figure.stand" : "tree"
    }

    /// #81: Styles that could have large images (all styles for carousel)
    private var carouselStyles: [StyleEntry] { styles.styles }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // #81: Large image carousel at top
                LargeImageCarousel(
                    asset: asset,
                    styles: carouselStyles,
                    carouselStyleIndex: $carouselStyleIndex,
                    onViewFullSize: { styleID in
                        largeImageSheetStyleID = styleID
                        showLargeImageSheet = true
                    }
                )
                .padding(.bottom, 16)

                // Type + Subtype
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Type")
                    HStack(spacing: 8) {
                        Image(systemName: assetTypeIcon)
                            .foregroundStyle(asset.isCharacter ? .blue : .teal)
                        Text(asset.isCharacter ? "Character" : "Location").font(.callout)
                        Spacer()
                        if asset.isCharacter {
                            Picker(selection: $asset.subType) {
                                Text("Male").tag("male")
                                Text("Female").tag("female")
                                Text("Other").tag("other")
                            } label: { EmptyView() }
                            .pickerStyle(.segmented).frame(maxWidth: 200)
                        } else {
                            Picker(selection: $asset.subType) {
                                Text("Interior").tag("interior")
                                Text("Exterior").tag("exterior")
                            } label: { EmptyView() }
                            .pickerStyle(.segmented).frame(maxWidth: 160)
                        }
                    }
                    .padding(.vertical, 5).padding(.horizontal, 8)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.07)))
                }
                .padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Name")
                    TextField("Name", text: $asset.name).textFieldStyle(.roundedBorder)
                }
                .padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Description")
                    TextEditor(text: $asset.description).font(.callout).frame(minHeight: 72)
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5))
                }
                .padding(.bottom, 12)

                Divider().padding(.vertical, 8)

                // Per-style variant sections
                ForEach(styles.styles) { style in
                    StyleVariantsSection(
                        asset: $asset, style: style,
                        generationQueue: $generationQueue,
                        config: config, assetModelID: assetModelID,
                        jobItemIcon: jobItemIcon
                    )
                    Divider().padding(.vertical, 6)
                }

                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showLargeImageSheet) {
            let sv = asset.variantsFor(style: largeImageSheetStyleID)
            let img = sv.hasLargeImage ? StorageService.shared.loadImage(id: sv.largeImageID) : nil
            LargeImageSheet(image: img, assetName: asset.name, isPresented: $showLargeImageSheet)
        }
    }
}

// MARK: - #81: Large image carousel

private struct LargeImageCarousel: View {
    let asset: AssetEntry
    let styles: [StyleEntry]
    @Binding var carouselStyleIndex: Int
    let onViewFullSize: (String) -> Void

    private var currentStyle: StyleEntry? {
        guard carouselStyleIndex >= 0 && carouselStyleIndex < styles.count else { return nil }
        return styles[carouselStyleIndex]
    }

    private var thumbType: ThumbnailItemType {
        asset.isCharacter ? .character(subType: asset.subType) : .location(subType: asset.subType)
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if let style = currentStyle {
                    let sv = asset.variantsFor(style: style.styleID)
                    if sv.hasLargeImage, let img = StorageService.shared.loadImage(id: sv.largeImageID) {
                        Button { onViewFullSize(style.styleID) } label: {
                            Image(nsImage: img)
                                .resizable().scaledToFill()
                                .frame(maxWidth: .infinity).frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain).help("Click to view full size")
                    } else {
                        UnifiedThumbnailView(itemType: thumbType, name: "", sizeMode: .header)
                    }
                } else {
                    UnifiedThumbnailView(itemType: thumbType, name: "", sizeMode: .header)
                }

                // Navigation arrows
                if styles.count > 1 {
                    HStack {
                        Button {
                            carouselStyleIndex = (carouselStyleIndex - 1 + styles.count) % styles.count
                        } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title2).symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Button {
                            carouselStyleIndex = (carouselStyleIndex + 1) % styles.count
                        } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title2).symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                }
            }

            // Style name + dots
            if let style = currentStyle {
                Text(style.name).font(.caption).foregroundStyle(.secondary)
            }
            if styles.count > 1 {
                HStack(spacing: 4) {
                    ForEach(0..<styles.count, id: \.self) { i in
                        Circle()
                            .fill(i == carouselStyleIndex ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
    }
}

// MARK: - Per-style variants section
/// #80: Generate 4 / Regenerate 4 with confirmation dialog
/// #81: Collapsed by default when approved variant exists, open when no variants

private struct StyleVariantsSection: View {
    @Binding var asset: AssetEntry
    let style: StyleEntry
    @Binding var generationQueue: [GenerationJob]
    let config: AppConfig
    let assetModelID: String
    let jobItemIcon: String
    @State private var isExpanded: Bool = true
    /// #80: Confirmation dialog for regeneration when large image exists
    @State private var showRegenConfirmation: Bool = false

    private var sv: AssetStyleVariants { asset.variantsFor(style: style.styleID) }
    private var hasVariants: Bool { !sv.variants.isEmpty }
    private var isVariantsQueued: Bool {
        generationQueue.contains { $0.assetID == asset.assetID && $0.styleID == style.styleID && $0.jobType == .generateAsset && $0.size == .small }
    }
    private var isLargeQueued: Bool {
        generationQueue.contains { $0.assetID == asset.assetID && $0.styleID == style.styleID && $0.jobType == .generateAsset && $0.size == .large }
    }
    private var hasDescription: Bool {
        !asset.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header row
            HStack(spacing: 8) {
                Button { isExpanded.toggle() } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.medium)).frame(width: 12)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)

                Image(systemName: "paintpalette").foregroundStyle(.orange).font(.caption)
                Text(style.name).font(.callout.weight(.semibold))
                Spacer()

                // #80: Generate 4 / Queued / Regenerate 4 button
                if isVariantsQueued {
                    Text("Queued").font(.caption).foregroundStyle(.purple)
                } else if !hasVariants {
                    Button { generateVariants() } label: {
                        Label("Generate 4", systemImage: "square.grid.2x2").font(.caption)
                    }
                    .buttonStyle(.bordered).controlSize(.mini).disabled(!hasDescription)
                } else {
                    Button { handleRegenerate() } label: {
                        Label("Regenerate 4", systemImage: "arrow.triangle.2.circlepath").font(.caption)
                    }
                    .buttonStyle(.bordered).controlSize(.mini).disabled(!hasDescription)
                }

                // Large image button
                if sv.hasApprovedVariant && !sv.hasLargeImage {
                    if isLargeQueued {
                        Text("Queued").font(.caption).foregroundStyle(.purple)
                    } else {
                        Button { generateLargeImage() } label: {
                            Label("Large", systemImage: "arrow.up.left.and.arrow.down.right.rectangle").font(.caption)
                        }
                        .buttonStyle(.bordered).controlSize(.mini)
                    }
                }
            }
            .padding(.vertical, 5).padding(.horizontal, 8)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color.orange.opacity(0.07)))

            if isExpanded {
                if hasVariants {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(0..<4, id: \.self) { idx in
                            variantTile(index: idx)
                        }
                    }
                } else {
                    Text("No variants generated yet.")
                        .font(.caption).foregroundStyle(.tertiary).padding(.vertical, 4)
                }
            }
        }
        .onAppear {
            // #81: Collapsed when approved variant exists, open when no variants or no approval
            isExpanded = !sv.hasApprovedVariant
        }
        // #80: Confirmation dialog for regeneration
        .alert("Regenerate variants for \(style.name)?", isPresented: $showRegenConfirmation) {
            Button("Regenerate", role: .destructive) { performRegeneration() }
            Button("Cancel", role: .cancel) {}
        } message: {
            if sv.hasLargeImage {
                Text("This will delete all 4 existing variants AND the generated large image. New variants will be queued.")
            } else {
                Text("This will delete all 4 existing variants. New variants will be queued.")
            }
        }
    }

    // MARK: - Variant tile

    private func variantTile(index idx: Int) -> some View {
        let variant: AssetVariant? = idx < sv.variants.count ? sv.variants[idx] : nil
        let thumbType: ThumbnailItemType = asset.isCharacter
            ? .character(subType: asset.subType) : .location(subType: asset.subType)

        return VStack(spacing: 4) {
            UnifiedThumbnailView(
                itemType: thumbType, name: "", sizeMode: .standard,
                badges: ThumbnailBadges(
                    showApprovedBadge: variant?.isApproved ?? false,
                    showEyeIndicator: sv.hasLargeImage && variant?.isApproved == true
                ),
                imageID: variant?.smallImageID ?? ""
            )
            .opacity(variant?.hasImage ?? false ? 1.0 : 0.3)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(variant?.isApproved ?? false ? Color.green : Color.clear, lineWidth: 1.5)
            )

            if let v = variant, v.hasImage {
                Button { approveVariant(at: idx) } label: {
                    Image(systemName: v.isApproved ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.caption2).foregroundStyle(v.isApproved ? .green : .secondary)
                }
                .buttonStyle(.plain)
            } else {
                Text("Empty").font(.caption2).foregroundStyle(.quaternary)
            }
        }
    }

    // MARK: - Actions

    private func approveVariant(at idx: Int) {
        var current = sv
        for i in current.variants.indices { current.variants[i].isApproved = (i == idx) }
        asset.styleVariants[style.styleID] = current
    }

    /// #80: Handle regeneration — show dialog if there's an approved variant/large image
    private func handleRegenerate() {
        showRegenConfirmation = true
    }

    /// #80: Actually delete old variants + large image, then queue new generation
    private func performRegeneration() {
        var current = sv
        // Delete variant image files
        for v in current.variants where v.hasImage {
            StorageService.shared.deleteImage(id: v.smallImageID)
        }
        // Delete large image file if it exists
        if current.hasLargeImage {
            StorageService.shared.deleteImage(id: current.largeImageID)
            current.largeImageID = ""
        }
        // Clear all variants
        current.variants = []
        asset.styleVariants[style.styleID] = current
        StorageLoadService.shared.saveAssets(AssetsFile(assets: [asset])) // Will be overwritten by parent
        // Queue new generation
        generateVariants()
    }

    private func generateVariants() {
        let prompt = buildPrompt()
        let job = GenerationJob(
            id: UUID().uuidString, itemName: asset.name, jobType: .generateAsset,
            size: .small, styleName: style.name, queuedAt: Date(),
            estimatedDuration: TimeInterval(4 * 60), itemIcon: jobItemIcon,
            seed: 0, width: config.smallImageWidth, height: config.smallImageHeight,
            combinedPrompt: prompt, variantCount: 4,
            assetType: asset.type, assetSubType: asset.subType,
            styleID: style.styleID, assetID: asset.assetID, modelID: assetModelID
        )
        generationQueue.append(job)
    }

    private func generateLargeImage() {
        let prompt = buildPrompt()
        let job = GenerationJob(
            id: UUID().uuidString, itemName: asset.name, jobType: .generateAsset,
            size: .large, styleName: style.name, queuedAt: Date(),
            estimatedDuration: 180, itemIcon: jobItemIcon,
            seed: sv.approvedSeed, width: config.largeImageWidth, height: config.largeImageHeight,
            combinedPrompt: prompt, variantCount: 1,
            assetType: asset.type, assetSubType: asset.subType,
            styleID: style.styleID, assetID: asset.assetID, modelID: assetModelID
        )
        generationQueue.append(job)
    }

    private func buildPrompt() -> String {
        var parts: [String] = []
        if !style.style.isEmpty { parts.append(style.style) }
        if asset.isCharacter && !config.characterTurnAround.isEmpty { parts.append(config.characterTurnAround) }
        parts.append(asset.description)
        return parts.joined(separator: ", ")
    }
}

// MARK: - Large image sheet

private struct LargeImageSheet: View {
    let image: NSImage?
    let assetName: String
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(assetName).font(.headline)
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2).symbolRenderingMode(.hierarchical).foregroundStyle(.secondary)
                }.buttonStyle(.plain)
            }.padding()
            if let img = image {
                Image(nsImage: img).resizable().scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal).padding(.bottom)
            } else {
                ContentUnavailableView("Image not found", systemImage: "photo",
                    description: Text("The large image file could not be loaded."))
            }
        }.frame(minWidth: 800, minHeight: 500)
    }
}
