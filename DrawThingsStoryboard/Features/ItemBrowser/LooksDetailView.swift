import SwiftUI

// MARK: - Looks detail (template editor)

struct LooksDetailView: View {
    @Binding var templates: [GenerationTemplate]
    @Binding var selectedTemplateID: String?
    @Binding var generationQueue: [GenerationJob]

    private var selectedIndex: Int? {
        guard let id = selectedTemplateID else { return nil }
        return templates.firstIndex { $0.id == id }
    }

    private func durationString(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 && secs > 0 { return "\(mins)m \(secs)s" }
        if mins > 0 { return "\(mins)m" }
        return "\(secs)s"
    }

    var body: some View {
        if let idx = selectedIndex {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    UnifiedThumbnailView(
                        itemType: .look,
                        name: "",
                        sizeMode: .header
                    )
                    .padding(.bottom, 16)

                    // Status
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Status")
                        HStack(spacing: 8) {
                            Text("E")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(templates[idx].lookStatus == .exampleAvailable ? .green : .gray)
                            Text("Example available:")
                                .font(.callout)
                            Text(templates[idx].lookStatus == .exampleAvailable ? "yes" : "not yet")
                                .font(.callout)
                                .foregroundStyle(templates[idx].lookStatus == .exampleAvailable ? .green : .secondary)
                            Spacer()
                            if templates[idx].lookStatus == .noExample {
                                if generationQueue.contains(where: { $0.itemName == templates[idx].name && $0.jobType == .generateExample }) {
                                    Text("Generate Example queued")
                                        .font(.caption)
                                        .foregroundStyle(.purple)
                                } else {
                                    Button {
                                        generateExample(at: idx)
                                    } label: {
                                        Label("Generate Example", systemImage: "eye")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(Color.accentColor.opacity(0.07))
                        )
                    }
                    .padding(.bottom, 12)

                    // Name
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Name")
                        TextField("Template name", text: $templates[idx].name)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.bottom, 12)

                    // Description
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Description")
                        TextEditor(text: $templates[idx].description)
                            .font(.callout)
                            .frame(minHeight: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
                            )
                    }
                    .padding(.bottom, 12)

                    Divider().padding(.vertical, 8)

                    // Average Duration Variant
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Average Duration Variant")
                        HStack(spacing: 6) {
                            TextField("Seconds", value: $templates[idx].averageDuration, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            Text("seconds")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(durationString(templates[idx].averageDuration))
                                .font(.callout)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.bottom, 12)

                    // Average Duration Large Image
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Average Duration Large Image")
                        HStack(spacing: 6) {
                            TextField("Seconds", value: $templates[idx].averageDurationLargeImage, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            Text("seconds")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(durationString(templates[idx].averageDurationLargeImage))
                                .font(.callout)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.bottom, 12)

                    // Generation Model
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Generation Model")
                        TextField("Model name", text: $templates[idx].generationModel)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.bottom, 12)

                    // Generation Steps
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Generation Steps")
                        HStack(spacing: 6) {
                            TextField("Steps", value: $templates[idx].generationSteps, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            Text("steps")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 12)

                    Spacer(minLength: 20)
                }
                .padding(14)
            }
            .background(Color(NSColor.windowBackgroundColor))
        } else {
            ContentUnavailableView(
                "No template selected",
                systemImage: "doc.text",
                description: Text("Select a template from the list to edit its properties.")
            )
        }
    }

    @AppStorage(SizeConfigKeys.previewVariantWidth)  private var previewVariantWidth  = SizeConfigDefaults.previewVariantWidth
    @AppStorage(SizeConfigKeys.previewVariantHeight) private var previewVariantHeight = SizeConfigDefaults.previewVariantHeight

    private func generateExample(at idx: Int) {
        let template = templates[idx]
        let job = GenerationJob(
            id: UUID().uuidString,
            itemName: template.name,
            itemType: template.itemType,
            jobType: .generateExample,
            size: .small,
            lookName: template.name,
            queuedAt: Date(),
            estimatedDuration: TimeInterval(template.averageDuration),
            itemIcon: template.itemType == .character ? "person.fill" : "map",
            seed: Int64.random(in: 1...999_999),
            width: previewVariantWidth,
            height: previewVariantHeight,
            combinedPrompt: template.description
        )
        generationQueue.append(job)
    }
}
