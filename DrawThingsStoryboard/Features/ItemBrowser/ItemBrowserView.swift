import SwiftUI

/// Center pane — adapts to the selected phase.
struct ItemBrowserView: View {

    let section: AppSection?

    @Binding var studios: [MockStudio]
    @Binding var selectedStudioID: String?
    @Binding var selectedCustomerID: String?
    @Binding var selectedEpisodeID: String?
    @Binding var selectedBriefingLevel: BriefingLevel
    @Binding var selectedItemID: String?

    var body: some View {
        VStack(spacing: 0) {
            BrowserHeaderView(section: section)
            Divider()

            switch section {
            case .projects:
                BriefingBrowserView(
                    studios: $studios,
                    selectedStudioID: $selectedStudioID,
                    selectedCustomerID: $selectedCustomerID,
                    selectedEpisodeID: $selectedEpisodeID,
                    selectedBriefingLevel: $selectedBriefingLevel
                )
            default:
                GenericBrowserView(section: section, selectedItemID: $selectedItemID)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onChange(of: section) { _, _ in selectedItemID = nil }
    }
}

// MARK: - Header

private struct BrowserHeaderView: View {
    let section: AppSection?
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if let section {
                Image(systemName: section.icon)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(section.title)
                    .font(.title2.bold())
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Production browser

struct ProductionBrowserView: View {
    @Binding var queue: [GenerationJob]
    @Binding var selectedJobID: String?

    private var estimatedFinishTime: Date? {
        guard !queue.isEmpty else { return nil }
        var total: TimeInterval = 0
        for job in queue { total += max(0, job.estimatedDuration - Date().timeIntervalSince(job.queuedAt)) }
        return Date().addingTimeInterval(total)
    }

    private var finishTimeString: String {
        guard let t = estimatedFinishTime else { return "\u{2014}" }
        let fmt = DateFormatter(); fmt.timeStyle = .short
        return fmt.string(from: t)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "film.stack").font(.title2).foregroundStyle(.secondary)
                    Text("Production Queue").font(.title2.bold())
                    Spacer()
                }
                Text("Queued for Generation with Draw Things").font(.caption).foregroundStyle(.secondary)
                if !queue.isEmpty {
                    Text("Finished around \(finishTimeString)").font(.caption).foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            Divider()
            if queue.isEmpty {
                Spacer()
                ContentUnavailableView("Queue is empty", systemImage: "tray",
                    description: Text("Jobs appear here when you click Generate on an item."))
                Spacer()
            } else {
                List(queue, selection: $selectedJobID) { job in
                    ProductionJobRow(job: job, onDelete: { queue.removeAll { $0.id == job.id } })
                        .tag(job.id)
                }
                .listStyle(.plain)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { ensureSelection() }
        .onChange(of: queue.count) { _, _ in ensureSelection() }
    }

    private func ensureSelection() {
        guard !queue.isEmpty else { return }
        if selectedJobID == nil || !queue.contains(where: { $0.id == selectedJobID }) {
            selectedJobID = queue.first?.id
        }
    }
}

private struct ProductionJobRow: View {
    let job: GenerationJob
    let onDelete: () -> Void

    private var elapsedString: String {
        let mins = Int(Date().timeIntervalSince(job.queuedAt)) / 60
        return mins < 1 ? "just now" : "\(mins)m ago"
    }

    private var itemThumbnailType: ThumbnailItemType {
        switch job.jobType {
        case .generatePanel:   return .panel
        case .generateExample: return .look
        case .generateAsset:
            return job.itemType == .character
                ? .character(gender: job.itemGender)
                : .location(setting: job.itemLocationSetting)
        }
    }

    private var orderedAttachedAssets: [JobAssetInfo] {
        job.attachedAssets.filter { $0.type == .location } + job.attachedAssets.filter { $0.type == .character }
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(job.jobType.letter)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(job.jobType.color).frame(width: 14)
            Text(job.size.letter)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(job.size == .large ? .green : .orange).frame(width: 14)
            thumbnailWithName(type: .look, name: job.lookName)
            thumbnailWithName(type: itemThumbnailType, name: job.itemName)
            ForEach(orderedAttachedAssets) { asset in
                thumbnailWithName(
                    type: asset.type == .character
                        ? .character(gender: asset.gender)
                        : .location(setting: asset.locationSetting),
                    name: asset.name
                )
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(elapsedString).font(.caption2).foregroundStyle(.secondary)
                Text("~\(Int(job.estimatedDuration) / 60)m").font(.caption2).foregroundStyle(.tertiary)
            }
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill").font(.system(size: 14))
                    .symbolRenderingMode(.palette).foregroundStyle(.white, .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func thumbnailWithName(type: ThumbnailItemType, name: String) -> some View {
        VStack(spacing: 1) {
            UnifiedThumbnailView(itemType: type, name: "", sizeMode: .compact)
            Text(name).font(.system(size: 7)).lineLimit(1).foregroundStyle(.secondary).frame(width: 80)
        }
    }
}

// MARK: - Looks browser

struct LooksBrowserView: View {
    @Binding var templates: [GenerationTemplate]
    @Binding var selectedTemplateID: String?
    private let columns = [GridItem(.adaptive(minimum: 288, maximum: 320), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "paintpalette").font(.title2).foregroundStyle(.secondary)
                Text("Looks").font(.title2.bold())
                Spacer()
                Button(action: addLook) {
                    Image(systemName: "plus").frame(width: 22, height: 22)
                }
                .buttonStyle(.bordered).controlSize(.mini)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            Divider()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(templates) { template in
                        let isSelected = selectedTemplateID == template.id
                        UnifiedThumbnailView(
                            itemType: .look, name: template.name, sizeMode: .standard,
                            badges: ThumbnailBadges(
                                showExampleIndicator: true,
                                exampleAvailable: template.lookStatus == .exampleAvailable,
                                showDeleteButton: templates.count > 1,
                                onDelete: { removeLook(id: template.id) },
                                showSelectionStroke: isSelected
                            )
                        )
                        .padding(3)
                        .background(RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.accentColor.opacity(0.07) : Color.clear))
                        .onTapGesture { selectedTemplateID = template.id }
                    }
                }
                .padding(16)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { ensureSelection() }
        .onChange(of: templates.count) { _, _ in ensureSelection() }
    }

    private func addLook() {
        let id = UUID().uuidString
        templates.append(GenerationTemplate(id: id, name: "New Look", description: "", itemType: .character))
        selectedTemplateID = id
    }

    private func removeLook(id: String) {
        guard templates.count > 1, let idx = templates.firstIndex(where: { $0.id == id }) else { return }
        templates.remove(at: idx)
        if selectedTemplateID == id || !templates.contains(where: { $0.id == selectedTemplateID }) {
            selectedTemplateID = templates[min(idx, templates.count - 1)].id
        }
    }

    private func ensureSelection() {
        if selectedTemplateID == nil || !templates.contains(where: { $0.id == selectedTemplateID }) {
            selectedTemplateID = templates.first?.id
        }
    }
}

// MARK: - Configuration view

struct ConfigurationView: View {
    @State private var sharedSecret: String = "ABCD 1234 EFGH"
    @State private var characterExample: String = "An astronaut riding a horse"
    @State private var locationExample: String = "big city by day"

    @AppStorage(SizeConfigKeys.previewVariantWidth)  private var previewVariantWidth  = SizeConfigDefaults.previewVariantWidth
    @AppStorage(SizeConfigKeys.previewVariantHeight) private var previewVariantHeight = SizeConfigDefaults.previewVariantHeight
    @AppStorage(SizeConfigKeys.finalWidth)           private var finalWidth           = SizeConfigDefaults.finalWidth
    @AppStorage(SizeConfigKeys.finalHeight)          private var finalHeight          = SizeConfigDefaults.finalHeight

    var body: some View {
        Form {
            Section("Draw Things") {
                LabeledContent("Shared Secret") {
                    TextField("Shared Secret", text: $sharedSecret)
                        .textFieldStyle(.roundedBorder).frame(maxWidth: 260)
                }
            }
            Section("Image Sizes") {
                LabeledContent("Small Width")  { TextField("Width",  value: $previewVariantWidth,  format: .number).textFieldStyle(.roundedBorder).frame(maxWidth: 120) }
                LabeledContent("Small Height") { TextField("Height", value: $previewVariantHeight, format: .number).textFieldStyle(.roundedBorder).frame(maxWidth: 120) }
                LabeledContent("Large Width")  { TextField("Width",  value: $finalWidth,           format: .number).textFieldStyle(.roundedBorder).frame(maxWidth: 120) }
                LabeledContent("Large Height") { TextField("Height", value: $finalHeight,          format: .number).textFieldStyle(.roundedBorder).frame(maxWidth: 120) }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Generic browser

private struct GenericBrowserView: View {
    let section: AppSection?
    @Binding var selectedItemID: String?

    var body: some View {
        ContentUnavailableView(
            "No items yet",
            systemImage: section?.icon ?? "tray",
            description: Text("Items will appear here once created.")
        )
    }
}
