import SwiftUI

// MARK: - Styles detail

struct StylesDetailView: View {
    @Binding var styles: StylesFile
    @Binding var selectedStyleID: String?
    @Binding var generationQueue: [GenerationJob]
    let config: AppConfig

    private var selectedIndex: Int? {
        guard let id = selectedStyleID else { return nil }
        return styles.styles.firstIndex { $0.styleID == id }
    }

    var body: some View {
        if let idx = selectedIndex {
            StyleEditorView(
                style: $styles.styles[idx],
                generationQueue: $generationQueue,
                config: config
            )
        } else {
            ContentUnavailableView(
                "No style selected",
                systemImage: "paintpalette",
                description: Text("Select a style to edit its prompt.")
            )
        }
    }
}

// MARK: - Style editor

private struct StyleEditorView: View {
    @Binding var style: StyleEntry
    @Binding var generationQueue: [GenerationJob]
    let config: AppConfig

    @State private var exampleImage: NSImage? = nil

    private var isQueued: Bool {
        generationQueue.contains { $0.styleID == style.styleID && $0.jobType == .generateStyle }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Header — show generated image or placeholder
                ZStack {
                    if let img = exampleImage {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        UnifiedThumbnailView(itemType: .style, name: "", sizeMode: .header)
                    }
                }
                .padding(.bottom, 16)

                // Status
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Status")
                    HStack(spacing: 8) {
                        Text("E").font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(style.isGenerated ? .green : .gray)
                        Text("Example:").font(.callout)
                        Text(style.isGenerated ? "available" : "not yet").font(.callout)
                            .foregroundStyle(style.isGenerated ? .green : .secondary)
                        Spacer()
                        if !style.isGenerated {
                            if isQueued {
                                Text("Queued").font(.caption).foregroundStyle(.purple)
                            } else {
                                Button { generateExample() } label: {
                                    Label("Generate Example", systemImage: "eye").font(.caption)
                                }
                                .buttonStyle(.bordered).controlSize(.mini)
                            }
                        }
                    }
                    .padding(.vertical, 5).padding(.horizontal, 8)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.07)))
                }
                .padding(.bottom, 12)

                // Name
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Name")
                    TextField("Style name", text: $style.name)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.bottom, 12)

                Divider().padding(.vertical, 8)

                // Style prompt
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Style Prompt")
                    Text("Describe the visual style \u{2014} this text is appended to every prompt.")
                        .font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $style.style)
                        .font(.callout).frame(minHeight: 100)
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5))
                }
                .padding(.bottom, 12)

                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { loadExampleImage() }
        .onChange(of: style.smallImageID) { _, _ in loadExampleImage() }
    }

    private func loadExampleImage() {
        exampleImage = StorageService.shared.loadImage(id: style.smallImageID)
    }

    private func generateExample() {
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
            itemIcon: "eye",
            seed: SeedHelper.randomSeed(),
            width: config.smallImageWidth,
            height: config.smallImageHeight,
            combinedPrompt: combined,
            styleID: style.styleID
        )
        generationQueue.append(job)
    }
}
