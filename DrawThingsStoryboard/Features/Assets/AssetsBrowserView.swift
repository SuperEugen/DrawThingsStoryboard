import SwiftUI

// MARK: - Assets browser

struct AssetsBrowserView: View {
    @Binding var assets: AssetsFile
    @Binding var selectedAssetID: String?

    private var characters: [AssetEntry] {
        assets.assets.filter { $0.isCharacter }
    }
    private var locations: [AssetEntry] {
        assets.assets.filter { $0.isLocation }
    }

    private let columns = [GridItem(.adaptive(minimum: 288, maximum: 320), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "photo.stack").font(.title2).foregroundStyle(.secondary)
                Text("Assets").font(.title2.bold())
                Spacer()
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
                            description: Text("Tap + to add a character or location."))
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
        return UnifiedThumbnailView(
            itemType: thumbType,
            name: asset.name,
            sizeMode: .standard,
            badges: ThumbnailBadges(
                showSelectionStroke: isSelected
            )
        )
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? Color.accentColor.opacity(0.07) : Color.clear))
        .onTapGesture { selectedAssetID = asset.assetID }
    }

    private func addAsset(type: String, subType: String) {
        let id = UUID().uuidString
        let new = AssetEntry(
            assetID: id,
            name: type == "character" ? "New Character" : "New Location",
            type: type,
            subType: subType,
            description: ""
        )
        assets.assets.append(new)
        selectedAssetID = id
    }

    private func ensureSelection() {
        if selectedAssetID == nil || !assets.assets.contains(where: { $0.assetID == selectedAssetID }) {
            selectedAssetID = assets.assets.first?.assetID
        }
    }
}
