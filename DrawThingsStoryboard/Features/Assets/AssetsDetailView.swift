import SwiftUI

// MARK: - Assets detail

struct AssetsDetailView: View {
    @Binding var assets: AssetsFile
    let selectedAssetID: String?
    @Binding var generationQueue: [GenerationJob]
    let config: AppConfig

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
    let onDelete: () -> Void
    // #31: Delete confirmation
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                let thumbType: ThumbnailItemType = asset.isCharacter
                    ? .character(subType: asset.subType)
                    : .location(subType: asset.subType)
                UnifiedThumbnailView(itemType: thumbType, name: "", sizeMode: .header)
                    .padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Status")
                    statusRow("V", "Variants", asset.hasApprovedVariant)
                    statusRow("S", "Small Image", asset.hasSmallImage)
                    statusRow("L", "Large Image", asset.hasLargeImage)
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

                // #31: Delete with confirmation
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
                badges: ThumbnailBadges(showApprovedBadge: variant.isApproved)
            )
            .opacity(variant.hasImage ? 1.0 : 0.4)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(variant.isApproved ? Color.green : Color.clear, lineWidth: 1.5)
            )

            if variant.hasImage {
                HStack(spacing: 8) {
                    Button {
                        approveVariant(at: idx)
                    } label: {
                        Image(systemName: variant.isApproved ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.caption2)
                            .foregroundStyle(variant.isApproved ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
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
}
