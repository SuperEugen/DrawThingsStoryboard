import SwiftUI

// MARK: - Assets detail
/// #40: Generate Large Image button + Large Image preview
/// #48: Uses passed-in style description instead of resolving from storyboard
/// #49: Character turn-around prompt for characters
/// #53: Jobs now carry modelID

struct AssetsDetailView: View {
    @Binding var assets: AssetsFile
    let selectedAssetID: String?
    @Binding var generationQueue: [GenerationJob]
    let config: AppConfig
    let assetStyleDescription: String
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
                assetStyleDescription: assetStyleDescription,
                assetModelID: assetModelID,
                onDelete: {
                    assets.assets.remove(at: idx)
                }
            )
        } else {
            ContentUnavailableView(
                "No asset selected",
                systemImage: "photo.stack",
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
    let assetStyleDescription: String
    let assetModelID: String
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    @State private var showLargeImageSheet = false

    private var isLargeQueued: Bool {
        generationQueue.contains {
            $0.assetID == asset.assetID && $0.jobType == .generateAsset && $0.size == .large
        }
    }

    private var largeImage: NSImage? {
        guard asset.hasLargeImage else { return nil }
        return StorageService.shared.loadImage(id: asset.largeImageID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                let headerImageID: String = {
                    if asset.hasLargeImage { return asset.largeImageID }
                    if let idx = asset.approvedVariantIndex {
                        return asset.variant(at: idx).smallImageID
                    }
                    return asset.smallImageID
                }()
                let thumbType: ThumbnailItemType = asset.isCharacter
                    ? .character(subType: asset.subType)
                    : .location(subType: asset.subType)
                UnifiedThumbnailView(
                    itemType: thumbType, name: "", sizeMode: .header, imageID: headerImageID
                )
                .padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Status")
                    statusRow("V", "Variants", asset.hasApprovedVariant)
                    statusRow("S", "Small Image", asset.hasSmallImage)
                    largeImageStatusRow
                }
                .padding(.bottom, 12)

                Divider().padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Type")
                    HStack(spacing: 6) {
                        Image(systemName: asset.isCharacter ? "person.fill" : "map")
                            .foregroundStyle(asset.isCharacter ? .blue : .teal)
                        Text(asset.isCharacter ? "Character" : "Location").font(.callout)
                        Text("\u{2014} \(asset.subType)").font(.callout).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 5).padding(.horizontal, 8)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.07)))
                }
                .padding(.bottom, 12)

                if asset.isCharacter {
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Gender")
                        Picker("Gender", selection: $asset.subType) {
                            Text("Male").tag("male")
                            Text("Female").tag("female")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.bottom, 12)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Setting")
                        Picker("Setting", selection: $asset.subType) {
                            Text("Interior").tag("interior")
                            Text("Exterior").tag("exterior")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.bottom, 12)
                }

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

                if asset.hasLargeImage {
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

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Variants")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(0..<4, id: \.self) { idx in
                            variantTile(index: idx)
                        }
                    }
                }
                .padding(.bottom, 12)

                Divider().padding(.vertical, 8)

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
                    Text("This will permanently remove the asset. This action cannot be undone.")
                }

                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showLargeImageSheet) {
            LargeImageSheet(image: largeImage, assetName: asset.name, isPresented: $showLargeImageSheet)
        }
    }

    @ViewBuilder
    private var largeImageStatusRow: some View {
        HStack(spacing: 8) {
            Text("L").font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(asset.hasLargeImage ? .green : .gray)
            Text("Large Image:").font(.callout)
            Text(asset.hasLargeImage ? "yes" : "not yet").font(.callout)
                .foregroundStyle(asset.hasLargeImage ? .green : .secondary)
            Spacer()
            if asset.hasApprovedVariant && !asset.hasLargeImage {
                if isLargeQueued {
                    Text("Queued").font(.caption).foregroundStyle(.purple)
                } else {
                    Button { generateLargeImage() } label: {
                        Label("Generate", systemImage: "arrow.up.left.and.arrow.down.right").font(.caption)
                    }
                    .buttonStyle(.bordered).controlSize(.mini)
                }
            }
            if asset.hasLargeImage {
                Button { showLargeImageSheet = true } label: {
                    Image(systemName: "eye").font(.caption)
                }
                .buttonStyle(.bordered).controlSize(.mini).help("View large image")
            }
        }
        .padding(.vertical, 5).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.07)))
    }

    @ViewBuilder
    private func statusRow(_ letter: String, _ label: String, _ active: Bool) -> some View {
        HStack(spacing: 8) {
            Text(letter).font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(active ? .green : .gray)
            Text("\(label):").font(.callout)
            Text(active ? "yes" : "not yet").font(.callout)
                .foregroundStyle(active ? .green : .secondary)
            Spacer()
        }
        .padding(.vertical, 5).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.07)))
    }

    private func variantTile(index idx: Int) -> some View {
        let variant = asset.variant(at: idx)
        return VStack(spacing: 4) {
            let thumbType: ThumbnailItemType = asset.isCharacter
                ? .character(subType: asset.subType)
                : .location(subType: asset.subType)
            UnifiedThumbnailView(
                itemType: thumbType, name: "", sizeMode: .standard,
                badges: ThumbnailBadges(showApprovedBadge: variant.isApproved),
                imageID: variant.smallImageID
            )
            .opacity(variant.hasImage ? 1.0 : 0.4)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(variant.isApproved ? Color.green : Color.clear, lineWidth: 1.5)
            )

            if variant.hasImage {
                HStack(spacing: 8) {
                    Button { approveVariant(at: idx) } label: {
                        Image(systemName: variant.isApproved ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.caption2)
                            .foregroundStyle(variant.isApproved ? .green : .secondary)
                    }
                    .buttonStyle(.plain)

                    Text("Seed: \(variant.seed)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            } else {
                Text("Empty").font(.caption2).foregroundStyle(.quaternary)
            }
        }
    }

    private func approveVariant(at idx: Int) {
        for i in 0..<4 {
            var v = asset.variant(at: i)
            v.isApproved = false
            asset.setVariant(at: i, v)
        }
        var v = asset.variant(at: idx)
        v.isApproved = true
        asset.setVariant(at: idx, v)
    }

    /// #49/#53: Build prompt + carry modelID
    private func generateLargeImage() {
        guard asset.hasApprovedVariant, let approvedIdx = asset.approvedVariantIndex else { return }
        let approvedSeed = asset.variant(at: approvedIdx).seed
        var parts: [String] = []
        if !assetStyleDescription.isEmpty { parts.append(assetStyleDescription) }
        if asset.isCharacter && !config.characterTurnAround.isEmpty {
            parts.append(config.characterTurnAround)
        }
        parts.append(asset.description)
        let prompt = parts.joined(separator: ", ")

        let job = GenerationJob(
            id: UUID().uuidString, itemName: asset.name, jobType: .generateAsset,
            size: .large, styleName: assetStyleDescription, queuedAt: Date(),
            estimatedDuration: 180,
            itemIcon: asset.isCharacter ? "person.fill" : "map",
            seed: approvedSeed, width: config.largeImageWidth, height: config.largeImageHeight,
            combinedPrompt: prompt, variantCount: 1,
            assetType: asset.type, assetSubType: asset.subType, assetID: asset.assetID,
            modelID: assetModelID
        )
        generationQueue.append(job)
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
