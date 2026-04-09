import SwiftUI

// MARK: - Assets browser
/// #4: "Generate all Variants" button
/// #5: "Generate all Large Images" button
/// #48: Style picker for asset generation
/// #49: Character turn-around prompt for characters
/// #52: Model picker for asset generation
/// #53: Jobs now carry modelID

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

    private func emptyVariantCount(for asset: AssetEntry) -> Int {
        (0..<4).filter { !asset.variant(at: $0).hasImage }.count
    }

    private var assetsNeedingVariants: [AssetEntry] {
        assets.assets.filter { !$0.hasApprovedVariant && emptyVariantCount(for: $0) > 0 }
    }

    private var assetsNeedingLargeImage: [AssetEntry] {
        assets.assets.filter { $0.hasApprovedVariant && !$0.hasLargeImage }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "photo.stack").font(.title2).foregroundStyle(.secondary)
                Text("Assets").font(.title2.bold())
                Spacer()

                // #52: Model picker
                Picker("Model", selection: $assetModelID) {
                    ForEach(models.models) { m in
                        Text(m.name).tag(m.modelID)
                    }
                }
                .pickerStyle(.menu).labelsHidden().frame(maxWidth: 160)

                Picker("Style", selection: $assetStyleID) {
                    ForEach(styles.styles) { s in
                        Text(s.name).tag(s.styleID)
                    }
                }
                .pickerStyle(.menu).labelsHidden().frame(maxWidth: 160)

                Button {
                    generateAllVariants()
                } label: {
                    Image(systemName: "square.grid.2x2")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .help("Generate all missing variants for all assets")
                .disabled(assetsNeedingVariants.isEmpty)

                Button {
                    generateAllLargeImages()
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .help("Generate all missing large images of approved variants")
                .disabled(assetsNeedingLargeImage.isEmpty)

                Menu {
                    Button { addAsset(type: "character", subType: "male") } label: {
                        Label("New Character", systemImage: "person.fill.badge.plus")
                    }
                    Button { addAsset(type: "location", subType: "interior") } label: {
                        Label("New Location", systemImage: "mappin.circle")
                    }
                } label: {
                    Image(systemName: "plus").frame(width: 22, height: 22)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 30)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            Divider()

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
                        ContentUnavailableView("No assets yet", systemImage: "photo.stack",
                            description: Text("Add a character or location using the + button above."))
                            .padding(.top, 40)
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { ensureSelection() }
    }

    private func assetTile(_ asset: AssetEntry) -> some View {
        let isSelected = selectedAssetID == asset.assetID
        let thumbType: ThumbnailItemType = asset.isCharacter
            ? .character(subType: asset.subType)
            : .location(subType: asset.subType)
        let displayImageID: String = {
            if let approvedIdx = asset.approvedVariantIndex {
                return asset.variant(at: approvedIdx).smallImageID
            }
            for i in 0..<4 {
                if asset.variant(at: i).hasImage {
                    return asset.variant(at: i).smallImageID
                }
            }
            return ""
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

    /// #53: Asset batch jobs carry modelID
    private func generateAllVariants() {
        for asset in assetsNeedingVariants {
            let count = emptyVariantCount(for: asset)
            let prompt = buildAssetPrompt(asset)
            let job = GenerationJob(
                id: UUID().uuidString, itemName: asset.name, jobType: .generateAsset,
                size: .small, styleName: resolvedStyleDescription, queuedAt: Date(),
                estimatedDuration: TimeInterval(count * 60),
                itemIcon: asset.isCharacter ? "person.fill" : "map",
                seed: 0, width: config.smallImageWidth, height: config.smallImageHeight,
                combinedPrompt: prompt, variantCount: count,
                assetType: asset.type, assetSubType: asset.subType, assetID: asset.assetID,
                modelID: assetModelID
            )
            generationQueue.append(job)
        }
    }

    /// #53: Asset batch jobs carry modelID
    private func generateAllLargeImages() {
        for asset in assetsNeedingLargeImage {
            let approvedSeed: Int = {
                if let idx = asset.approvedVariantIndex { return asset.variant(at: idx).seed }
                return 0
            }()
            let prompt = buildAssetPrompt(asset)
            let job = GenerationJob(
                id: UUID().uuidString, itemName: asset.name, jobType: .generateAsset,
                size: .large, styleName: resolvedStyleDescription, queuedAt: Date(),
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

    /// #49: Build prompt with character turn-around for characters.
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
