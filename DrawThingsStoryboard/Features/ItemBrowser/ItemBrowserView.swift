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
                    ProductionJobRow(job: job)
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

    private var itemTypeLabel: String {
        job.itemType == .character ? "Character" : "Location"
    }

    private var itemTypeColor: Color {
        job.itemType == .character ? .blue : .teal
    }

    var body: some View {
        HStack(spacing: 12) {
            // Job Type thumbnail (large)
            RoundedRectangle(cornerRadius: 8)
                .fill(job.jobType.color.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay {
                    VStack(spacing: 2) {
                        Image(systemName: job.jobType.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(job.jobType.color)
                        Text(job.jobType.rawValue)
                            .font(.system(size: 7, weight: .medium))
                            .foregroundStyle(job.jobType.color)
                            .lineLimit(1)
                    }
                }

            // Details stack
            VStack(alignment: .leading, spacing: 4) {
                // Item: thumbnail + name
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(itemTypeColor.opacity(0.15))
                        .frame(width: 24, height: 24)
                        .overlay {
                            Image(systemName: job.itemIcon)
                                .font(.system(size: 11))
                                .foregroundStyle(itemTypeColor)
                        }
                    Text(job.itemName)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                }

                // Item type
                Text(itemTypeLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                // Look: thumbnail + name
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 24, height: 24)
                        .overlay {
                            Image(systemName: "paintpalette")
                                .font(.system(size: 11))
                                .foregroundStyle(.purple)
                        }
                    Text(job.lookName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
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
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Looks browser (template list)

struct LooksBrowserView: View {
    @Binding var templates: [GenerationTemplate]
    @Binding var selectedTemplateID: String?

    /// True when at least two looks exist so the selected one can be removed.
    private var canRemove: Bool {
        templates.count > 1 && selectedTemplateID != nil
    }

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
                Button(action: removeSelectedLook) {
                    Image(systemName: "minus")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .disabled(!canRemove)

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

            List(templates, selection: $selectedTemplateID) { template in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(template.jobType.color.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: template.jobType.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(template.jobType.color)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.name)
                            .font(.callout.weight(.medium))
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            Text(template.jobType.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("·")
                                .foregroundStyle(.quaternary)
                            Text(template.itemType == .character ? "Character" : "Location")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Spacer()
                }
                .tag(template.id)
            }
            .listStyle(.plain)
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
            jobType: .generateVariants,
            itemType: .character,
            averageDuration: 120,
            generationModel: "SDXL 1.0",
            generationSteps: 30
        ))
        selectedTemplateID = newID
    }

    private func removeSelectedLook() {
        guard let id = selectedTemplateID,
              templates.count > 1,
              let idx = templates.firstIndex(where: { $0.id == id }) else { return }

        templates.remove(at: idx)

        // Select the previous item, or the first if we removed index 0
        let newIdx = min(idx, templates.count - 1)
        selectedTemplateID = templates[newIdx].id
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
