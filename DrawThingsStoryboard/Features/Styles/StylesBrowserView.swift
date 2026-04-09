import SwiftUI

// MARK: - Styles browser
/// #53: Style jobs carry modelID
/// #56: Model picker in styles header, Generate Example icon → paintbrush.pointed

struct StylesBrowserView: View {
    @Binding var styles: StylesFile
    @Binding var selectedStyleID: String?
    @Binding var generationQueue: [GenerationJob]
    let config: AppConfig
    let models: ModelsFile
    @Binding var stylesModelID: String
    private let columns = [GridItem(.adaptive(minimum: 288, maximum: 320), spacing: 12)]

    private var ungeneratedCount: Int {
        styles.styles.filter { !$0.isGenerated }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "paintpalette").font(.title2).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Styles").font(.title2.bold())
                    Text("Visual style templates applied to generated images.")
                        .font(.caption).foregroundStyle(.tertiary)
                }
                Spacer()
                // #56: Model picker
                Picker("Model", selection: $stylesModelID) {
                    ForEach(models.models) { m in
                        Text(m.name).tag(m.modelID)
                    }
                }
                .pickerStyle(.menu).labelsHidden().frame(maxWidth: 160)
                // #7/#56: Generate all missing examples
                if ungeneratedCount > 0 {
                    Button { generateAllExamples() } label: {
                        Label("Generate \(ungeneratedCount) Example\(ungeneratedCount == 1 ? "" : "s")", systemImage: "paintbrush.pointed")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered).controlSize(.mini)
                    .help("Generate all missing example images for all styles")
                }
                Button(action: addStyle) { Image(systemName: "plus").frame(width: 22, height: 22) }
                .buttonStyle(.bordered).controlSize(.mini)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            Divider()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(styles.styles) { style in
                        StyleTile(
                            style: style,
                            isSelected: selectedStyleID == style.styleID,
                            canDelete: styles.styles.count > 1,
                            onDelete: { removeStyle(id: style.styleID) },
                            onTap: { selectedStyleID = style.styleID }
                        )
                    }
                }
                .padding(16)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { ensureSelection() }
        .onChange(of: styles.styles.count) { _, _ in ensureSelection() }
    }

    private func addStyle() {
        let id = UUID().uuidString
        styles.styles.append(StyleEntry(styleID: id, name: "New Style", style: ""))
        selectedStyleID = id
    }

    private func removeStyle(id: String) {
        guard styles.styles.count > 1, let idx = styles.styles.firstIndex(where: { $0.styleID == id }) else { return }
        styles.styles.remove(at: idx)
        if selectedStyleID == id || !styles.styles.contains(where: { $0.styleID == selectedStyleID }) {
            selectedStyleID = styles.styles[min(idx, styles.styles.count - 1)].styleID
        }
    }

    private func ensureSelection() {
        if selectedStyleID == nil || !styles.styles.contains(where: { $0.styleID == selectedStyleID }) {
            selectedStyleID = styles.styles.first?.styleID
        }
    }

    // #7/#53: Generate all missing examples with modelID
    private func generateAllExamples() {
        for style in styles.styles where !style.isGenerated {
            guard !generationQueue.contains(where: { $0.styleID == style.styleID && $0.jobType == .generateStyle }) else { continue }
            let combined = [style.style, config.stylePrompt]
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .joined(separator: ", ")
            let job = GenerationJob(
                id: UUID().uuidString,
                itemName: style.name,
                jobType: .generateStyle,
                size: .small,
                styleName: style.name,
                queuedAt: Date(),
                estimatedDuration: 60,
                itemIcon: "paintbrush.pointed",
                seed: SeedHelper.randomSeed(),
                width: config.smallImageWidth,
                height: config.smallImageHeight,
                combinedPrompt: combined,
                styleID: style.styleID,
                modelID: stylesModelID
            )
            generationQueue.append(job)
        }
    }
}

// MARK: - Style tile

struct StyleTile: View {
    let style: StyleEntry
    let isSelected: Bool
    let canDelete: Bool
    let onDelete: () -> Void
    let onTap: () -> Void
    @State private var exampleImage: NSImage? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                ZStack {
                    if let img = exampleImage {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .clipped()
                    } else {
                        UnifiedThumbnailView(
                            itemType: .style, name: "", sizeMode: .standard,
                            badges: ThumbnailBadges(
                                showExampleIndicator: true,
                                exampleAvailable: style.isGenerated
                            )
                        )
                    }
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(style.name).font(.callout.weight(.medium)).lineLimit(1)
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(NSColor.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2),
                        lineWidth: isSelected ? 2 : 0.5))

            VStack {
                Spacer()
                HStack {
                    Text("E").font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(style.isGenerated ? .green : .gray)
                        .padding(4)
                        .background(Circle().fill(Color(NSColor.windowBackgroundColor).opacity(0.8)))
                        .padding(6)
                    Spacer()
                }
            }
            .frame(height: 160)

            if canDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary).font(.system(size: 16))
                }.buttonStyle(.plain).padding(6)
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? Color.accentColor.opacity(0.07) : Color.clear))
        .onTapGesture { onTap() }
        .onAppear { loadImage() }
        .onChange(of: style.smallImageID) { _, _ in loadImage() }
        .onChange(of: style.isGenerated) { _, _ in loadImage() }
    }

    private func loadImage() {
        exampleImage = StorageService.shared.loadImage(id: style.smallImageID)
    }
}
