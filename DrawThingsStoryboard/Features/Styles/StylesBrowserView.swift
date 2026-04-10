import SwiftUI

// MARK: - Styles browser
/// #60: GroupBox header like Assets (Generate + Add groups)
/// #61: Full-width placeholder background
/// #62, #63: E indicators removed

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
            headerBar
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

    // MARK: - Header with GroupBoxes

    @ViewBuilder
    private var headerBar: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "paintpalette").font(.title2).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Styles").font(.title2.bold())
                    Text("Visual style templates applied to generated images.")
                        .font(.caption).foregroundStyle(.tertiary)
                }
                Spacer()
            }
            .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 8)

            HStack(spacing: 16) {
                // GROUP 1: Generate
                GroupBox {
                    HStack(spacing: 8) {
                        Picker("Model", selection: $stylesModelID) {
                            ForEach(models.models) { m in
                                Text(m.name).tag(m.modelID)
                            }
                        }
                        .pickerStyle(.menu).labelsHidden().frame(minWidth: 120)

                        Button { generateAllExamples() } label: {
                            Label("Examples (\(ungeneratedCount))", systemImage: "paintbrush.pointed")
                                .font(.callout)
                        }
                        .buttonStyle(.bordered).controlSize(.regular)
                        .disabled(ungeneratedCount == 0)
                        .help("Generate all missing example images")
                    }
                } label: {
                    Label("Generate", systemImage: "wand.and.sparkles")
                        .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                }

                // GROUP 2: Add
                GroupBox {
                    Button(action: addStyle) {
                        Label("New Style", systemImage: "plus")
                            .font(.callout)
                    }
                    .buttonStyle(.bordered).controlSize(.regular)
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 14).padding(.bottom, 10)
        }
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

    private func generateAllExamples() {
        for style in styles.styles where !style.isGenerated {
            guard !generationQueue.contains(where: { $0.styleID == style.styleID && $0.jobType == .generateStyle }) else { continue }
            let combined = [style.style, config.stylePrompt]
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .joined(separator: ", ")
            let job = GenerationJob(
                id: UUID().uuidString, itemName: style.name, jobType: .generateStyle,
                size: .small, styleName: style.name, queuedAt: Date(),
                estimatedDuration: 60, itemIcon: "paintbrush.pointed",
                seed: SeedHelper.randomSeed(),
                width: config.smallImageWidth, height: config.smallImageHeight,
                combinedPrompt: combined, styleID: style.styleID, modelID: stylesModelID
            )
            generationQueue.append(job)
        }
    }
}

// MARK: - Style tile
/// #61: Full-width placeholder
/// #62, #63: E indicators removed

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
                            .resizable().scaledToFill()
                            .frame(height: 160).clipped()
                    } else {
                        // #61: full-width placeholder
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color.orange.opacity(0.15))
                            .frame(height: 160)
                            .overlay {
                                Image(systemName: "paintpalette")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Color.orange.opacity(0.4))
                            }
                    }
                }
                .frame(maxWidth: .infinity)
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
