import SwiftUI

// MARK: - Assets browser
/// #57: Per-style variants, header redesign (Filter | Generate | Add)

struct AssetsBrowserView: View {
    @Binding var assets: AssetsFile
    @Binding var selectedAssetID: String?
    @Binding var generationQueue: [GenerationJob]
    let config: AppConfig
    let styles: StylesFile
    @Binding var assetStyleID: String
    let models: ModelsFile
    @Binding var assetModelID: String

    private var characters: [AssetEntry] {
        assets.assets.filter { $0.isCharacter }
    }
    private var locations: [AssetEntry] {
        assets.assets.filter { $0.isLocation }
    }

    private let columns = [GridItem(.adaptive(minimum: 288, maximum: 320), spacing: 12)]

    private var resolvedStyleDescription: String {
        styles.styles.first(where: { $0.styleID == assetStyleID })?.style ?? ""
    }

    private var resolvedStyleName: String {
        styles.styles.first(where: { $0.styleID == assetStyleID })?.name ?? ""
    }

    // MARK: - Generate helpers

    /// Assets that still need variants in the selected style.
    private var assetsNeedingVariants: [AssetEntry] {
        assets.assets.filter { asset in
            let sv = asset.variantsFor(style: assetStyleID)
            return !sv.hasApprovedVariant && sv.emptySlotCount > 0
                && !asset.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    /// Assets that have an approved variant in the selected style but no large image.
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
    }

    // MARK: - Header (3 groups: Filter | Generate | Add)

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
                            ForEach(styles.styles) { s in
                                Text(s.name).tag(s.styleID)
                            }
                        }
                        .pickerStyle(.menu).labelsHidden().frame(minWidth: 120)

                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        Picker("Model", selection: $assetModelID) {
                            ForEach(models.models) { m in
                                Text(m.name).tag(m.modelID)
                            }
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
                        Button {
                            generateAllVariants()
                        } label: {
                            Label("Variants (\(assetsNeedingVariants.count))", systemImage: "square.grid.2x2")
                                .font(.callout)
                        }
                        .buttonStyle(.bordered).controlSize(.regular)
                        .disabled(assetsNeedingVariants.isEmpty)
                        .help("Generate missing variants for all assets in style \u{201c}\(resolvedStyleName)\u{201d}")

                        Button {
                            generateAllLargeImages()
                        } label: {
                            Label("Large (\(assetsNeedingLargeImage.count))", systemImage: "arrow.up.left.and.arrow.down.right.rectangle")
                                .font(.callout)
                        }
                        .buttonStyle(.bordered).controlSize(.regular)
                        .disabled(assetsNeedingLargeImage.isEmpty)
                        .help("Generate missing large images for approved variants in style \u{201c}\(resolvedStyleName)\u{201d}")
                    }
                } label: {
                    Label("Generate", systemImage: "paintbrush.pointed")
                        .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                }

                // GROUP 3: Add
                GroupBox {
                    Menu {
                        Button { addAsset(type: "character", subType: "male") } label: {
                            Label("New Character", systemImage: "figure.stand")
                        }
                        Button { addAsset(type: "location", subType: "interior") } label: {
                            Label("New Location", systemImage: "sofa")
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                            .font(.callout)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 60)
                } label: {
                    Label("Add", systemImage: "plus.circle")
                        .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 14).padding(.bottom, 10)
        }
    }

    // MARK: - Asset grid

    @ViewBuilder
    private var assetGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if !characters.isEmpty {
                    Text("Characters").font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary).padding(.horizontal, 16).padding(.top, 8)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(characters) { asset in
                            assetTile(asset)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                if !locations.isEmpty {
                    Text("Locations").font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary).padding(.horizontal, 16).padding(.top, 8)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(locations) { asset in
                            assetTile(asset)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                if assets.assets.isEmpty {
                    ContentUnavailableView("No assets yet", systemImage: "person.crop.square.on.square.angled",
                        description: Text("Add a character or location using the Add button above."))
                        .padding(.top, 40)
                }
            }
            .padding(.bottom, 16)
        }
    }

    // MARK: - Tile

    private func assetTile(_ asset: AssetEntry) -> some View {
        let isSelected = selectedAssetID == asset.assetID
        let thumbType: ThumbnailItemType = asset.isCharacter
            ? .character(subType: asset.subType)
            : .location(subType: asset.subType)
        // Show best image for selected style, fallback to any style
        let displayImageID: String = {
            let styleImg = asset.bestImageID(forStyle: assetStyleID)
            if !styleImg.isEmpty { return styleImg }
            return asset.bestDisplayImageID
        }()
        return UnifiedThumbnailView(
            itemType: thumbType,
            name: asset.name,
            sizeMode: .standard,
            badges: ThumbnailBadges(showSelectionStroke: isSelected),
            imageID: displayImageID
        )
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? Color.accentColor.opacity(0.07) : Color.clear))
        .onTapGesture { selectedAssetID = asset.assetID }
    }

    // MARK: - Actions

    private func addAsset(type: String, subType: String) {
        let id = UUID().uuidString
        let new = AssetEntry(
            assetID: id,
            name: type == "character" ? "New Character" : "New Location",
            type: type, subType: subType, description: ""
        )
        assets.assets.append(new)
        selectedAssetID = id
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
                estimatedDuration: TimeInterval(count * 60),
                itemIcon: icon,
                seed: 0, width: config.smallImageWidth, height: config.smallImageHeight,
                combinedPrompt: prompt, variantCount: count,
                assetType: asset.type, assetSubType: asset.subType,
                styleID: assetStyleID, assetID: asset.assetID,
                modelID: assetModelID
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
                estimatedDuration: 180,
                itemIcon: icon,
                seed: sv.approvedSeed, width: config.largeImageWidth, height: config.largeImageHeight,
                combinedPrompt: prompt, variantCount: 1,
                assetType: asset.type, assetSubType: asset.subType,
                styleID: assetStyleID, assetID: asset.assetID,
                modelID: assetModelID
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
