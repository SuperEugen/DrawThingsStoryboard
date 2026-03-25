import SwiftUI

// MARK: - Looks detail (style prompt editor)

struct LooksDetailView: View {
    @Binding var templates: [GenerationTemplate]
    @Binding var selectedTemplateID: String?
    @Binding var generationQueue: [GenerationJob]

    @AppStorage(SizeConfigKeys.previewVariantWidth) private var previewVariantWidth = SizeConfigDefaults.previewVariantWidth
    @AppStorage(SizeConfigKeys.previewVariantHeight) private var previewVariantHeight = SizeConfigDefaults.previewVariantHeight

    private var selectedIndex: Int? {
        guard let id = selectedTemplateID else { return nil }
        return templates.firstIndex { $0.id == id }
    }

    var body: some View {
        if let idx = selectedIndex {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    UnifiedThumbnailView(itemType: .look, name: "", sizeMode: .header)
                        .padding(.bottom, 16)

                    // Status + Generate Example
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Status")
                        HStack(spacing: 8) {
                            Text("E")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(templates[idx].lookStatus == .exampleAvailable ? .green : .gray)
                            Text("Example:")
                                .font(.callout)
                            Text(templates[idx].lookStatus == .exampleAvailable ? "available" : "not yet")
                                .font(.callout)
                                .foregroundStyle(templates[idx].lookStatus == .exampleAvailable ? .green : .secondary)
                            Spacer()
                            if templates[idx].lookStatus == .noExample {
                                if generationQueue.contains(where: {
                                    $0.itemName == templates[idx].name && $0.jobType == .generateExample
                                }) {
                                    Text("Queued")
                                        .font(.caption)
                                        .foregroundStyle(.purple)
                                } else {
                                    Button { generateExample(at: idx) } label: {
                                        Label("Generate Example", systemImage: "eye")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
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
                        TextField("Look name", text: $templates[idx].name)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.bottom, 12)

                    Divider().padding(.vertical, 8)

                    // Description = style prompt
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Description")
                        Text("Describe the visual style — this text is appended to every prompt.")
                            .font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $templates[idx].description)
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
            // When a queued example job moves to done, mark the look as exampleAvailable
            .onChange(of: generationQueue) { _, newQueue in
                updateLookStatusFromQueue(currentQueue: newQueue, idx: idx)
            }
        } else {
            ContentUnavailableView(
                "No look selected",
                systemImage: "paintpalette",
                description: Text("Select a look to edit its style prompt.")
            )
        }
    }

    // MARK: - Generate example job

    private func generateExample(at idx: Int) {
        let template = templates[idx]
        // Load example prompt from config
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

    // MARK: - Status update

    /// If the generation queue no longer contains a job for this look,
    /// but it did before, the job completed — mark the look as exampleAvailable.
    private func updateLookStatusFromQueue(currentQueue: [GenerationJob], idx: Int) {
        guard templates.indices.contains(idx) else { return }
        let lookName = templates[idx].name
        let stillQueued = currentQueue.contains {
            $0.itemName == lookName && $0.jobType == .generateExample
        }
        // Job was in queue and is now gone — it completed
        if !stillQueued && templates[idx].lookStatus == .noExample {
            templates[idx].lookStatus = .exampleAvailable
            // Persist the new status to disk
            StorageLoadService.shared.saveTemplates(templates)
        }
    }
}
