import SwiftUI

// MARK: - Assets detail
/// #69: Delete with image cleanup, x-button on tile
/// #70: Subtype compact in same row as Type
/// #71: "other" subtype for characters
/// #72: Variant thumbnails use standard size
/// #73: Collapsible variant sections
/// #74: Eye indicator on large-image thumbnails
/// #75: Eye button removed from style section header

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
                assetModelID: assetModelID,
                onDelete: {
                    // #69: Delete all generated images for this asset
                    let asset = assets.assets[idx]
                    for (_, sv) in asset.styleVariants {
                        for v in sv.variants where v.hasImage {
                            StorageService.shared.deleteImage(id: v.smallImageID)
                        }
                        if sv.hasLargeImage {
                            StorageService.shared.deleteImage(id: sv.largeImageID)
                        }
                    }
                    assets.assets.remove(at: idx)
                }
            )
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
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    @State private var showLargeImageSheet = false
    @State private var largeImageSheetStyleID: String = ""

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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header image
                let headerImageID = asset.bestDisplayImageID
                let thumbType: ThumbnailItemType = asset.isCharacter
                    ? .character(subType: asset.subType) : .location(subType: asset.subType)
                UnifiedThumbnailView(itemType: thumbType, name: "", sizeMode: .header, imageID: headerImageID)
                    .padding(.bottom, 16)

                // #70: Type + Subtype in one compact row with picker
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Type")
                    HStack(spacing: 8) {
                        Image(systemName: assetTypeIcon)
                            .foregroundStyle(asset.isCharacter ? .blue : .teal)
                        Text(asset.isCharacter ? "Character" : "Location").font(.callout)
                        Spacer()
                        // #70, #71: Subtype picker inline
                        if asset.isCharacter {
                            Picker("Subtype", selection: $asset.subType) {
                                Text("Male").tag("male")
                                Text("Female").tag("female")
                                Text("Other").tag("other")
                            }
                            .pickerStyle(.segmented).frame(maxWidth: 200)
                        } else {
                            Picker("Subtype", selection: $asset.subType) {
                                Text("Interior").tag("interior")
                                Text("Exterior").tag("exterior")
                            }
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

                // Per-style sections
                ForEach(styles.styles) { style in
                    StyleVariantsSection(
                        asset: $asset, style: style,
                        generationQueue: $generationQueue,
                        config: config, assetModelID: assetModelID,
                        jobItemIcon: jobItemIcon,
                        onViewLargeImage: { styleID in
                            largeImageSheetStyleID = styleID
                            showLargeImageSheet = true
                        }
                    )
                    Divider().padding(.vertical, 6)
                }

                // #69: Delete button with warning about image deletion
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Asset", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .alert("Delete \(asset.name)?", isPresented: $showDeleteConfirmation) {
                    Button("Delete", role: .destructive, action: onDelete)
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will permanently remove the asset and all generated variants and large images for all styles.")
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

// MARK: - Per-style variants section
/// #72: standard-size thumbnails for variants
/// #73: collapsible, auto-collapses when large image exists
/// #74: eye indicator on large-image variant thumbnails (handled in badges)
/// #75: eye button removed

private struct StyleVariantsSection: View {
    @Binding var asset: AssetEntry
    let style: StyleEntry
    @Binding var generationQueue: [GenerationJob]
    let config: AppConfig
    let assetModelID: String
    let jobItemIcon: String
    let onViewLargeImage: (String) -> Void
    @State private var isExpanded: Bool = true

    private var sv: AssetStyleVariants { asset.variantsFor(style: style.styleID) }
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
            // #73: Collapsible header
            HStack(spacing: 8) {
                Button { isExpanded.toggle() } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.medium)).frame(width: 12)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)

                Image(systemName: "paintpalette").foregroundStyle(.orange).font(.caption)
                Text(style.name).font(.callout.weight(.semibold))
                Spacer()

                // Generate variants
                if sv.emptySlotCount > 0 && !sv.hasApprovedVariant {
                    if isVariantsQueued {
                        Text("Queued").font(.caption).foregroundStyle(.purple)
                    } else {
                        Button { generateVariants() } label: {
                            Label("Generate \(sv.emptySlotCount)", systemImage: "square.grid.2x2").font(.caption)
                        }
                        .buttonStyle(.bordered).controlSize(.mini).disabled(!hasDescription)
                    }
                }

                // Generate large
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
                // #75: eye button removed
            }
            .padding(.vertical, 5).padding(.horizontal, 8)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color.orange.opacity(0.07)))

            if isExpanded {
                // #72: standard-size variant tiles (2 columns)
                if !sv.variants.isEmpty {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(0..<4, id: \.self) { idx in
                            variantTile(index: idx)
                        }
                    }
                } else {
                    Text("No variants generated yet.")
                        .font(.caption).foregroundStyle(.tertiary).padding(.vertical, 4)
                }

                // Large image preview
                if sv.hasLargeImage, let img = StorageService.shared.loadImage(id: sv.largeImageID) {
                    Button { onViewLargeImage(style.styleID) } label: {
                        Image(nsImage: img)
                            .resizable().scaledToFit()
                            .frame(maxWidth: .infinity).frame(maxHeight: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain).help("Click to view full size")
                }
            }
        }
        .onAppear {
            // #73: Auto-collapse when large image exists
            if sv.hasLargeImage { isExpanded = false }
        }
    }

    private func variantTile(index idx: Int) -> some View {
        let variant: AssetVariant? = idx < sv.variants.count ? sv.variants[idx] : nil
        let thumbType: ThumbnailItemType = asset.isCharacter
            ? .character(subType: asset.subType) : .location(subType: asset.subType)

        return VStack(spacing: 4) {
            // #72: standard size, #74: eye indicator via showEyeIndicator badge
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

    private func approveVariant(at idx: Int) {
        var current = sv
        for i in current.variants.indices { current.variants[i].isApproved = (i == idx) }
        asset.styleVariants[style.styleID] = current
    }

    private func generateVariants() {
        let count = sv.emptySlotCount; guard count > 0 else { return }
        let prompt = buildPrompt()
        let job = GenerationJob(
            id: UUID().uuidString, itemName: asset.name, jobType: .generateAsset,
            size: .small, styleName: style.name, queuedAt: Date(),
            estimatedDuration: TimeInterval(count * 60), itemIcon: jobItemIcon,
            seed: 0, width: config.smallImageWidth, height: config.smallImageHeight,
            combinedPrompt: prompt, variantCount: count,
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
