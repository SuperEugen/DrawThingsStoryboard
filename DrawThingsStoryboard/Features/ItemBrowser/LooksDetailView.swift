import SwiftUI

// MARK: - Looks detail (style prompt editor)

struct LooksDetailView: View {
    @Binding var templates: [GenerationTemplate]
    @Binding var selectedTemplateID: String?
    @Binding var generationQueue: [GenerationJob]

    @AppStorage(SizeConfigKeys.previewVariantWidth)  private var previewVariantWidth  = SizeConfigDefaults.previewVariantWidth
    @AppStorage(SizeConfigKeys.previewVariantHeight) private var previewVariantHeight = SizeConfigDefaults.previewVariantHeight

    private var selectedIndex: Int? {
        guard let id = selectedTemplateID else { return nil }
        return templates.firstIndex { $0.id == id }
    }

    var body: some View {
        if let idx = selectedIndex {
            LookEditorView(
                template: $templates[idx],
                generationQueue: $generationQueue,
                previewVariantWidth: previewVariantWidth,
                previewVariantHeight: previewVariantHeight,
                onStatusUpdate: { updatedTemplates in
                    StorageLoadService.shared.saveTemplates(updatedTemplates)
                },
                allTemplates: $templates
            )
        } else {
            ContentUnavailableView(
                "No look selected",
                systemImage: "paintpalette",
                description: Text("Select a look to edit its style prompt.")
            )
        }
    }
}

// MARK: - Look editor (extracted to avoid type-checker timeout)

private struct LookEditorView: View {
    @Binding var template: GenerationTemplate
    @Binding var generationQueue: [GenerationJob]
    let previewVariantWidth: Int
    let previewVariantHeight: Int
    let onStatusUpdate: ([GenerationTemplate]) -> Void
    @Binding var allTemplates: [GenerationTemplate]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                UnifiedThumbnailView(itemType: .look, name: "", sizeMode: .header)
                    .padding(.bottom, 16)

                LookStatusRow(
                    template: $template,
                    generationQueue: $generationQueue,
                    allTemplates: $allTemplates,
                    previewVariantWidth: previewVariantWidth,
                    previewVariantHeight: previewVariantHeight,
                    onStatusUpdate: onStatusUpdate
                )
                .padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Name")
                    TextField("Look name", text: $template.name)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.bottom, 12)

                Divider().padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Description")
                    Text("Describe the visual style — this text is appended to every prompt.")
                        .font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $template.description)
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
    }
}

// MARK: - Status row (extracted to avoid type-checker timeout)

private struct LookStatusRow: View {
    @Binding var template: GenerationTemplate
    @Binding var generationQueue: [GenerationJob]
    @Binding var allTemplates: [GenerationTemplate]
    let previewVariantWidth: Int
    let previewVariantHeight: Int
    let onStatusUpdate: ([GenerationTemplate]) -> Void

    private var isQueued: Bool {
        generationQueue.contains {
            $0.itemName == template.name && $0.jobType == .generateExample
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Status")
            HStack(spacing: 8) {
                Text("E")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(template.lookStatus == .exampleAvailable ? .green : .gray)
                Text("Example:").font(.callout)
                Text(template.lookStatus == .exampleAvailable ? "available" : "not yet")
                    .font(.callout)
                    .foregroundStyle(template.lookStatus == .exampleAvailable ? Color.green : Color.secondary)
                Spacer()
                if template.lookStatus == .noExample {
                    if isQueued {
                        Text("Queued").font(.caption).foregroundStyle(Color.purple)
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
        .onChange(of: generationQueue) { _, newQueue in
            updateStatus(currentQueue: newQueue)
        }
    }

    private func generateExample() {
        let root = StorageService.shared.rootURL
        let examplePrompt = StorageLoadService.shared.loadAppConfig(from: root)?.lookExamplePrompt
            ?? SizeConfigDefaults.lookExamplePrompt
        let combined = [template.description, examplePrompt]
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: ", ")
        let job = GenerationJob(
            id: UUID().uuidString,
            itemName: template.name,
            itemType: .character,
            jobType: .generateExample,
            size: .small,
            lookName: template.name,
            queuedAt: Date(),
            estimatedDuration: 60,
            itemIcon: "eye",
            seed: Int64.random(in: 1...999_999),
            width: previewVariantWidth,
            height: previewVariantHeight,
            combinedPrompt: combined
        )
        generationQueue.append(job)
    }

    private func updateStatus(currentQueue: [GenerationJob]) {
        let stillQueued = currentQueue.contains {
            $0.itemName == template.name && $0.jobType == .generateExample
        }
        if !stillQueued && template.lookStatus == .noExample {
            template.lookStatus = .exampleAvailable
            onStatusUpdate(allTemplates)
        }
    }
}
