import SwiftUI

// MARK: - Assets browser
/// Delete via x-button on thumbnail, Location Add button fixed

struct AssetsBrowserView: View {
    @Binding var assets: AssetsFile
    @Binding var selectedAssetID: String?
    @Binding var generationQueue: [GenerationJob]
    let config: AppConfig
    let styles: StylesFile
    @Binding var assetStyleID: String
    let models: ModelsFile
    @Binding var assetModelID: String

    @State private var assetToDelete: AssetEntry? = nil
    @State private var showDeleteConfirmation = false

    private var characters: [AssetEntry] { assets.assets.filter { $0.isCharacter } }
    private var locations: [AssetEntry] { assets.assets.filter { $0.isLocation } }
    private let columns = [GridItem(.adaptive(minimum: 288, maximum: 320), spacing: 12)]

    private var resolvedStyleDescription: String {
        styles.styles.first(where: { $0.styleID == assetStyleID })?.style ?? ""
    }
    private var resolvedStyleName: String {
        styles.styles.first(where: { $0.styleID == assetStyleID })?.name ?? ""
    }

    private var assetsNeedingVariants: [AssetEntry] {
        assets.assets.filter { asset in
            let sv = asset.variantsFor(style: assetStyleID)
            return !sv.hasApprovedVariant && sv.emptySlotCount > 0
                && !asset.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    private var assetsNeedingLargeImage: [AssetEntry] {
        assets.assets.filter { asset in
            let sv = asset.variantsFor(style: assetStyleID)
            return sv.hasApprovedVariant && !sv.hasLargeImage
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            assetGrid
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { ensureSelection() }
        .alert("Delete \(assetToDelete?.name ?? "")?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let asset = assetToDelete { deleteAsset(asset) }
            }
            Button("Cancel", role: .cancel) { assetToDelete = nil }
        } message: {
            Text("This will permanently remove the asset and all generated variants and large images for all styles.")
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerBar: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "person.crop.square.on.square.angled").font(.title2).foregroundStyle(.secondary)
                Text("Assets").font(.title2.bold())
                Spacer()
            }
            .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 8)

            HStack(spacing: 16) {
                // GROUP 1: Filter
                GroupBox {
                    HStack(spacing: 8) {
                        Text("Style").font(.caption).foregroundStyle(.secondary)
                        Picker("Style", selection: $assetStyleID) {
                            ForEach(styles.styles) { s in Text(s.name).tag(s.styleID) }
                        }
                        .pickerStyle(.menu).labelsHidden().frame(minWidth: 120)
                    }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease")
                        .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                }

                // GROUP 2: Generate
                GroupBox {
                    HStack(spacing: 8) {
                        Picker("Model", selection: $assetModelID) {
                            ForEach(models.models) { m in Text(m.name).tag(m.modelID) }
                        }
                        .pickerStyle(.menu).labelsHidden().frame(minWidth: 120)

                        Button { generateAllVariants() } label: {
                            Label("Variants (\(assetsNeedingVariants.count))", systemImage: "square.grid.2x2").font(.callout)
                        }
                        .buttonStyle(.bordered).controlSize(.regular)
                        .disabled(assetsNeedingVariants.isEmpty)

                        Button { generateAllLargeImages() } label: {
                            Label("Large (\(assetsNeedingLargeImage.count))", systemImage: "arrow.up.left.and.arrow.down.right.rectangle").font(.callout)
                        }
                        .buttonStyle(.bordered).controlSize(.regular)
                        .disabled(assetsNeedingLargeImage.isEmpty)
                    }
                } label: {
                    Label("Generate", systemImage: "wand.and.sparkles")
                        .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                }

                // GROUP 3: Add — fixed Location icon to mappin.and.ellipse
                GroupBox {
                    HStack(spacing: 8) {
                        Button { addAsset(type: "character", subType: "male") } label: {
                            Image(systemName: "figure.stand.dress.line.vertical.figure").font(.callout)
                        }
                        .buttonStyle(.bordered).controlSize(.regular)
                        .help("Add new character")

                        Button { addAsset(type: "location", subType: "interior") } label: {
                            Image(systemName: "mappin.and.ellipse").font(.callout)
                        }
                        .buttonStyle(.bordered).controlSize(.regular)
                        .help("Add new location")
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 14).padding(.bottom, 10)
        }
    }

    // MARK: - Grid

    @ViewBuilder
    private var assetGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if !characters.isEmpty {
                    Text("Characters").font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary).padding(.horizontal, 16).padding(.top, 8)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(characters) { asset in assetTile(asset) }
                    }.padding(.horizontal, 16)
                }
                if !locations.isEmpty {
                    Text("Locations").font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary).padding(.horizontal, 16).padding(.top, 8)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(locations) { asset in assetTile(asset) }
                    }.padding(.horizontal, 16)
                }
                if assets.assets.isEmpty {
                    ContentUnavailableView("No assets yet", systemImage: "person.crop.square.on.square.angled",
                        description: Text("Add a character or location using the Add buttons above."))
                        .padding(.top, 40)
                }
            }
            .padding(.bottom, 16)
        }
    }

    /// Tile with x-button for deletion
    private func assetTile(_ asset: AssetEntry) -> some View {
        let isSelected = selectedAssetID == asset.assetID
        let thumbType: ThumbnailItemType = asset.isCharacter
            ? .character(subType: asset.subType) : .location(subType: asset.subType)
        let sv = asset.variantsFor(style: assetStyleID)
        let displayImageID = sv.bestImageID
        let showApproved = sv.hasApprovedVariant
        let showLargeIndicator = sv.hasLargeImage

        return ZStack(alignment: .topTrailing) {
            UnifiedThumbnailView(
                itemType: thumbType, name: asset.name, sizeMode: .standard,
                badges: ThumbnailBadges(
                    showApprovedBadge: showApproved,
                    showSelectionStroke: isSelected,
                    showLargeImageIndicator: showLargeIndicator
                ),
                imageID: displayImageID
            )

            // x-button for deletion
            Button {
                assetToDelete = asset
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(6)
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? Color.accentColor.opacity(0.07) : Color.clear))
        .onTapGesture { selectedAssetID = asset.assetID }
    }

    // MARK: - Actions

    private func addAsset(type: String, subType: String) {
        let id = UUID().uuidString
        let new = AssetEntry(assetID: id, name: type == "character" ? "New Character" : "New Location",
                             type: type, subType: subType, description: "")
        assets.assets.append(new)
        selectedAssetID = id
    }

    private func deleteAsset(_ asset: AssetEntry) {
        // Delete all generated images
        for (_, sv) in asset.styleVariants {
            for v in sv.variants where v.hasImage {
                StorageService.shared.deleteImage(id: v.smallImageID)
            }
            if sv.hasLargeImage {
                StorageService.shared.deleteImage(id: sv.largeImageID)
            }
        }
        assets.assets.removeAll { $0.assetID == asset.assetID }
        if selectedAssetID == asset.assetID {
            selectedAssetID = assets.assets.first?.assetID
        }
        assetToDelete = nil
    }

    private func generateAllVariants() {
        for asset in assetsNeedingVariants {
            let sv = asset.variantsFor(style: assetStyleID)
            let count = sv.emptySlotCount
            let prompt = buildAssetPrompt(asset)
            let icon = asset.isCharacter ? "figure.stand" : "tree"
            let job = GenerationJob(
                id: UUID().uuidString, itemName: asset.name, jobType: .generateAsset,
                size: .small, styleName: resolvedStyleName, queuedAt: Date(),
                estimatedDuration: TimeInterval(count * 60), itemIcon: icon,
                seed: 0, width: config.smallImageWidth, height: config.smallImageHeight,
                combinedPrompt: prompt, variantCount: count,
                assetType: asset.type, assetSubType: asset.subType,
                styleID: assetStyleID, assetID: asset.assetID, modelID: assetModelID
            )
            generationQueue.append(job)
        }
    }

    private func generateAllLargeImages() {
        for asset in assetsNeedingLargeImage {
            let sv = asset.variantsFor(style: assetStyleID)
            let prompt = buildAssetPrompt(asset)
            let icon = asset.isCharacter ? "figure.stand" : "tree"
            let job = GenerationJob(
                id: UUID().uuidString, itemName: asset.name, jobType: .generateAsset,
                size: .large, styleName: resolvedStyleName, queuedAt: Date(),
                estimatedDuration: 180, itemIcon: icon,
                seed: sv.approvedSeed, width: config.largeImageWidth, height: config.largeImageHeight,
                combinedPrompt: prompt, variantCount: 1,
                assetType: asset.type, assetSubType: asset.subType,
                styleID: assetStyleID, assetID: asset.assetID, modelID: assetModelID
            )
            generationQueue.append(job)
        }
    }

    private func buildAssetPrompt(_ asset: AssetEntry) -> String {
        var parts: [String] = []
        if !resolvedStyleDescription.isEmpty { parts.append(resolvedStyleDescription) }
        if asset.isCharacter && !config.characterTurnAround.isEmpty {
            parts.append(config.characterTurnAround)
        }
        parts.append(asset.description)
        return parts.joined(separator: ", ")
    }

    private func ensureSelection() {
        if selectedAssetID == nil || !assets.assets.contains(where: { $0.assetID == selectedAssetID }) {
            selectedAssetID = assets.assets.first?.assetID
        }
    }
}
