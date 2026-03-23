import SwiftUI

/// Center pane — adapts to the selected phase.
/// Project: Studio → Customer → Episode hierarchy.
/// Other:   generic single-section grid.
struct ItemBrowserView: View {

    let section: AppSection?

    // Project hierarchy
    @Binding var studios: [MockStudio]
    @Binding var selectedStudioID: String?
    @Binding var selectedCustomerID: String?
    @Binding var selectedEpisodeID: String?
    @Binding var selectedBriefingLevel: BriefingLevel

    // Generic phases
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
        .onChange(of: section) { _, _ in
            selectedItemID = nil
        }
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

// MARK: - Production browser (generation queue)

struct ProductionBrowserView: View {

    @Binding var queue: [GenerationJob]
    @Binding var selectedJobID: String?

    /// Estimated finish time based on the last job in the queue.
    private var estimatedFinishTime: Date? {
        guard !queue.isEmpty else { return nil }
        var totalRemaining: TimeInterval = 0
        for job in queue {
            let elapsed = Date().timeIntervalSince(job.queuedAt)
            let remaining = max(0, job.estimatedDuration - elapsed)
            totalRemaining += remaining
        }
        return Date().addingTimeInterval(totalRemaining)
    }

    private var finishTimeString: String {
        guard let time = estimatedFinishTime else { return "—" }
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return fmt.string(from: time)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "film.stack")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Production Queue")
                        .font(.title2.bold())
                    Spacer()
                }
                Text("Queued for Generation with Draw Things")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !queue.isEmpty {
                    Text("Finished around \(finishTimeString)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()

            if queue.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "Queue is empty",
                    systemImage: "tray",
                    description: Text("Jobs appear here when you click Generate Variants or Generate Final on an item.")
                )
                Spacer()
            } else {
                List(queue, selection: $selectedJobID) { job in
                    ProductionJobRow(job: job, onDelete: {
                        queue.removeAll { $0.id == job.id }
                    })
                    .tag(job.id)
                }
                .listStyle(.plain)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            ensureSelection()
        }
        .onChange(of: queue.count) { _, _ in
            ensureSelection()
        }
    }

    /// Ensures the first job is selected when nothing is selected.
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
        let elapsed = Int(Date().timeIntervalSince(job.queuedAt))
        let mins = elapsed / 60
        if mins < 1 { return "just now" }
        return "\(mins)m ago"
    }

    private var durationString: String {
        let mins = Int(job.estimatedDuration) / 60
        return "~\(mins)m"
    }

    /// Thumbnail type for the main item (Asset or Panel).
    private var itemThumbnailType: ThumbnailItemType {
        switch job.jobType {
        case .generatePanel:
            return .panel
        case .generateExample:
            return .look
        case .generateAsset:
            return job.itemType == .character
                ? .character(gender: job.itemGender)
                : .location(setting: job.itemLocationSetting)
        }
    }

    /// Attached assets reordered: location first, then characters.
    private var orderedAttachedAssets: [JobAssetInfo] {
        let locations  = job.attachedAssets.filter { $0.type == .location }
        let characters = job.attachedAssets.filter { $0.type == .character }
        return locations + characters
    }

    var body: some View {
        HStack(spacing: 6) {
            // 1. Type letter (E/A/P)
            Text(job.jobType.letter)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(job.jobType.color)
                .frame(width: 14)

            // 2. Size letter (S/L)
            Text(job.size.letter)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(job.size == .large ? .green : .orange)
                .frame(width: 14)

            // 3. Look thumbnail (always first among thumbnails)
            thumbnailWithName(type: .look, name: job.lookName)

            // 4. Item / Panel thumbnail
            thumbnailWithName(type: itemThumbnailType, name: job.itemName)

            // 5. Attached assets (panel jobs) — location first, then characters
            ForEach(orderedAttachedAssets) { asset in
                thumbnailWithName(
                    type: asset.type == .character
                        ? .character(gender: asset.gender)
                        : .location(setting: asset.locationSetting),
                    name: asset.name
                )
            }

            Spacer()

            // Time entries
            VStack(alignment: .trailing, spacing: 2) {
                Text(elapsedString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(durationString)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func thumbnailWithName(type: ThumbnailItemType, name: String) -> some View {
        VStack(spacing: 1) {
            UnifiedThumbnailView(
                itemType: type,
                name: "",
                sizeMode: .compact
            )
            Text(name)
                .font(.system(size: 7))
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .frame(width: 80)
        }
    }
}

// MARK: - Looks browser (template list)

struct LooksBrowserView: View {
    @Binding var templates: [GenerationTemplate]
    @Binding var selectedTemplateID: String?

    private let columns = [GridItem(.adaptive(minimum: 288, maximum: 320), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "paintpalette")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Looks")
                    .font(.title2.bold())
                Spacer()
                Button(action: addLook) {
                    Image(systemName: "plus")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(templates) { template in
                        let isSelected = selectedTemplateID == template.id
                        let canDelete = templates.count > 1
                        UnifiedThumbnailView(
                            itemType: .look,
                            name: template.name,
                            sizeMode: .standard,
                            badges: ThumbnailBadges(
                                showExampleIndicator: true,
                                exampleAvailable: template.lookStatus == .exampleAvailable,
                                showDeleteButton: canDelete,
                                onDelete: { removeLook(id: template.id) },
                                showSelectionStroke: isSelected
                            )
                        )
                        .padding(3)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? Color.accentColor.opacity(0.07) : Color.clear)
                        )
                        .onTapGesture { selectedTemplateID = template.id }
                    }
                }
                .padding(16)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            ensureSelection()
        }
        .onChange(of: templates.count) { _, _ in
            ensureSelection()
        }
    }

    private func addLook() {
        let newID = UUID().uuidString
        templates.append(GenerationTemplate(
            id: newID,
            name: "New Look",
            description: "",
            itemType: .character,
            averageDuration: 120,
            generationModel: "SDXL 1.0",
            generationSteps: 30
        ))
        selectedTemplateID = newID
    }

    private func removeLook(id: String) {
        guard templates.count > 1,
              let idx = templates.firstIndex(where: { $0.id == id }) else { return }

        templates.remove(at: idx)

        // Select the previous item, or the first if we removed index 0
        if selectedTemplateID == id || !templates.contains(where: { $0.id == selectedTemplateID }) {
            let newIdx = min(idx, templates.count - 1)
            selectedTemplateID = templates[newIdx].id
        }
    }

    /// Ensures there is always one look selected.
    private func ensureSelection() {
        if selectedTemplateID == nil || !templates.contains(where: { $0.id == selectedTemplateID }) {
            selectedTemplateID = templates.first?.id
        }
    }
}

// MARK: - Configuration view (single pane, grouped key-value list)

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
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 260)
                }
            }

            Section("Looks") {
                LabeledContent("Character Example") {
                    TextField("Character Example", text: $characterExample)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 260)
                }
                LabeledContent("Location Example") {
                    TextField("Location Example", text: $locationExample)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 260)
                }
            }

            Section("Image Sizes") {
                LabeledContent("Small Image Width") {
                    TextField("Width", value: $previewVariantWidth, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 120)
                }
                LabeledContent("Small Image Height") {
                    TextField("Height", value: $previewVariantHeight, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 120)
                }
                LabeledContent("Large Image Width") {
                    TextField("Width", value: $finalWidth, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 120)
                }
                LabeledContent("Large Image Height") {
                    TextField("Height", value: $finalHeight, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 120)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Configuration")
    }
}

// MARK: - Generic browser (non-casting phases)

private struct GenericBrowserView: View {

    let section: AppSection?
    @Binding var selectedItemID: String?
    private let columns = [GridItem(.adaptive(minimum: 130, maximum: 170), spacing: 12)]

    var body: some View {
        let items = MockData.items(for: section)
        if items.isEmpty {
            ContentUnavailableView(
                "No items yet",
                systemImage: section?.icon ?? "tray",
                description: Text("Items will appear here once created.")
            )
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items) { item in
                        GenericTileView(item: item, isSelected: selectedItemID == item.id)
                            .onTapGesture { selectedItemID = item.id }
                    }
                }
                .padding(16)
            }
            .onAppear {
                if selectedItemID == nil || !items.contains(where: { $0.id == selectedItemID }) {
                    selectedItemID = items.first?.id
                }
            }
        }
    }
}

private struct GenericTileView: View {
    let item: MockItem
    let isSelected: Bool
    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 10)
                .fill(item.color.opacity(0.15))
                .overlay {
                    Image(systemName: item.icon)
                        .font(.system(size: 32))
                        .foregroundStyle(item.color)
                }
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                )
            Text(item.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.07) : Color.clear)
        )
    }
}

#Preview {
    @Previewable @State var studios = MockData.defaultStudios
    @Previewable @State var studioID: String? = MockData.defaultStudios[0].id
    @Previewable @State var customerID: String? = MockData.defaultStudios[0].customers[0].id
    @Previewable @State var episodeID: String? = MockData.defaultStudios[0].customers[0].episodes[0].id
    @Previewable @State var briefingLevel: BriefingLevel = .episode
    @Previewable @State var selID: String? = nil

    ItemBrowserView(
        section: .projects,
        studios: $studios,
        selectedStudioID: $studioID,
        selectedCustomerID: $customerID,
        selectedEpisodeID: $episodeID,
        selectedBriefingLevel: $briefingLevel,
        selectedItemID: $selID
    )
    .frame(width: 480, height: 600)
}
