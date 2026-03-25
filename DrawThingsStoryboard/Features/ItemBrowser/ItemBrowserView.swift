import SwiftUI

/// Center pane — adapts to the selected phase.
struct ItemBrowserView: View {

    let section: AppSection?

    @Binding var studios: [MockStudio]
    @Binding var selectedStudioID: String?
    @Binding var selectedCustomerID: String?
    @Binding var selectedEpisodeID: String?
    @Binding var selectedProjectsLevel: ProjectsLevel
    @Binding var selectedItemID: String?

    var body: some View {
        VStack(spacing: 0) {
            BrowserHeaderView(section: section)
            Divider()

            switch section {
            case .projects:
                ProjectsBrowserView(
                    studios: $studios,
                    selectedStudioID: $selectedStudioID,
                    selectedCustomerID: $selectedCustomerID,
                    selectedEpisodeID: $selectedEpisodeID,
                    selectedProjectsLevel: $selectedProjectsLevel
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
                Image(systemName: section.icon).font(.title2).foregroundStyle(.secondary)
                Text(section.title).font(.title2.bold())
                Spacer()
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

// MARK: - Production browser

struct ProductionBrowserView: View {
    @Binding var queue: [GenerationJob]
    @Binding var selectedJobID: String?
    @Binding var doneQueue: [GenerationJob]
    @Binding var configs: [DTModelConfig]
    @Binding var selectedModelConfigID: String?

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
        VSplitView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: "film.stack").font(.title2).foregroundStyle(.secondary)
                        Text("Production Queue").font(.title2.bold())
                        Spacer()
                        Picker("Model", selection: Binding(
                            get: { selectedModelConfigID ?? configs.first?.id ?? "" },
                            set: { selectedModelConfigID = $0 }
                        )) {
                            ForEach(configs) { config in Text(config.name).tag(config.id) }
                        }
                        .pickerStyle(.menu).labelsHidden().frame(maxWidth: 160)
                        .help("Select Draw Things model configuration")
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
            .frame(minHeight: 120)

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle").font(.subheadline).foregroundStyle(.secondary)
                    Text("Done").font(.subheadline.bold())
                    Spacer()
                    if !doneQueue.isEmpty {
                        Button { doneQueue.removeAll() } label: { Text("Clear").font(.caption) }
                        .buttonStyle(.borderless).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                Divider()
                if doneQueue.isEmpty {
                    Spacer()
                    Text("No completed jobs yet.").font(.caption).foregroundStyle(.tertiary)
                    Spacer()
                } else {
                    List(doneQueue) { job in DoneJobRow(job: job) }.listStyle(.plain)
                }
            }
            .frame(minHeight: 100)
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
    let job: GenerationJob; let onDelete: () -> Void
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
            Text(job.jobType.letter).font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(job.jobType.color).frame(width: 14)
            Text(job.size.letter).font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(job.size == .large ? .green : .orange).frame(width: 14)
            thumbnailWithName(type: .look, name: job.lookName)
            if job.jobType != .generateExample { thumbnailWithName(type: itemThumbnailType, name: job.itemName) }
            ForEach(orderedAttachedAssets) { asset in
                thumbnailWithName(
                    type: asset.type == .character ? .character(gender: asset.gender) : .location(setting: asset.locationSetting),
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
            }.buttonStyle(.plain)
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

private struct DoneJobRow: View {
    let job: GenerationJob
    private var durationString: String {
        guard let completed = job.completedAt, let started = job.startedAt else { return "" }
        let secs = Int(completed.timeIntervalSince(started))
        let m = secs / 60; let s = secs % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }
    private var completedTimeString: String {
        guard let completed = job.completedAt else { return "" }
        let fmt = DateFormatter(); fmt.timeStyle = .short
        return fmt.string(from: completed)
    }
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.system(size: 12))
            Text(job.jobType.letter).font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(job.jobType.color).frame(width: 14)
            Text(job.size.letter).font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(job.size == .large ? .green : .orange).frame(width: 14)
            VStack(alignment: .leading, spacing: 1) {
                Text(job.itemName).font(.callout.weight(.medium)).lineLimit(1)
                Text(job.lookName).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(completedTimeString).font(.caption2).foregroundStyle(.secondary)
                Text(durationString).font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
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
                Button(action: addLook) { Image(systemName: "plus").frame(width: 22, height: 22) }
                .buttonStyle(.bordered).controlSize(.mini)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            Divider()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(templates) { template in
                        LookTile(
                            template: template, isSelected: selectedTemplateID == template.id,
                            canDelete: templates.count > 1,
                            onDelete: { removeLook(id: template.id) },
                            onTap: { selectedTemplateID = template.id }
                        )
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

// MARK: - Look tile

private struct LookTile: View {
    let template: GenerationTemplate; let isSelected: Bool
    let canDelete: Bool; let onDelete: () -> Void; let onTap: () -> Void
    @State private var exampleImage: NSImage? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                ZStack {
                    if let img = exampleImage {
                        Image(nsImage: img).resizable().scaledToFill().frame(height: 140).clipped()
                    } else {
                        UnifiedThumbnailView(
                            itemType: .look, name: template.name, sizeMode: .standard,
                            badges: ThumbnailBadges(showExampleIndicator: true,
                                exampleAvailable: template.lookStatus == .exampleAvailable,
                                showDeleteButton: false, onDelete: {}, showSelectionStroke: false)
                        )
                    }
                }
                .frame(height: 140).clipShape(RoundedRectangle(cornerRadius: 10))
                Text(template.name).font(.callout.weight(.medium)).lineLimit(1)
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
            VStack { Spacer()
                HStack {
                    Text("E").font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(template.lookStatus == .exampleAvailable ? .green : .gray)
                        .padding(4).background(Circle().fill(Color(NSColor.windowBackgroundColor).opacity(0.8))).padding(6)
                    Spacer()
                }
            }.frame(height: 140)
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 12).fill(isSelected ? Color.accentColor.opacity(0.07) : Color.clear))
        .onTapGesture { onTap() }
        .onAppear { loadExampleImage() }
        .onChange(of: template.lookStatus) { _, _ in loadExampleImage() }
    }
    private func loadExampleImage() {
        exampleImage = StorageService.shared.loadLookExample(lookName: template.name)
    }
}

// MARK: - Configuration view

struct ConfigurationView: View {

    // Loaded from / saved to dtsb-config.json
    @State private var appConfig: AppConfig = AppConfig(
        modelConfigs: []
    )

    var body: some View {
        Form {
            Section("Draw Things") {
                LabeledContent("Shared Secret") {
                    TextField("Shared Secret", text: $appConfig.sharedSecret)
                        .textFieldStyle(.roundedBorder).frame(maxWidth: 260)
                }
            }
            Section("Image Sizes") {
                LabeledContent("Small Width")  { TextField("Width",  value: $appConfig.previewVariantWidth,  format: .number).textFieldStyle(.roundedBorder).frame(maxWidth: 120) }
                LabeledContent("Small Height") { TextField("Height", value: $appConfig.previewVariantHeight, format: .number).textFieldStyle(.roundedBorder).frame(maxWidth: 120) }
                LabeledContent("Large Width")  { TextField("Width",  value: $appConfig.finalWidth,           format: .number).textFieldStyle(.roundedBorder).frame(maxWidth: 120) }
                LabeledContent("Large Height") { TextField("Height", value: $appConfig.finalHeight,          format: .number).textFieldStyle(.roundedBorder).frame(maxWidth: 120) }
            }
            Section("Look Example Prompts") {
                Text("These prompts are appended to the Look description when generating an example image.")
                    .font(.caption).foregroundStyle(.secondary)
                LabeledContent("Character") {
                    TextField("Character prompt", text: $appConfig.lookPromptCharacter)
                        .textFieldStyle(.roundedBorder)
                }
                LabeledContent("Location") {
                    TextField("Location prompt", text: $appConfig.lookPromptLocation)
                        .textFieldStyle(.roundedBorder)
                }
                LabeledContent("Panel") {
                    TextField("Panel prompt", text: $appConfig.lookPromptPanel)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { loadConfig() }
        .onChange(of: appConfig.sharedSecret)          { _, _ in saveConfig() }
        .onChange(of: appConfig.previewVariantWidth)   { _, _ in saveConfig() }
        .onChange(of: appConfig.previewVariantHeight)  { _, _ in saveConfig() }
        .onChange(of: appConfig.finalWidth)            { _, _ in saveConfig() }
        .onChange(of: appConfig.finalHeight)           { _, _ in saveConfig() }
        .onChange(of: appConfig.lookPromptCharacter)   { _, _ in saveConfig() }
        .onChange(of: appConfig.lookPromptLocation)    { _, _ in saveConfig() }
        .onChange(of: appConfig.lookPromptPanel)       { _, _ in saveConfig() }
    }

    private func loadConfig() {
        let root = StorageService.shared.rootURL
        if let loaded = StorageLoadService.shared.loadAppConfig(from: root) {
            appConfig = loaded
        }
    }

    private func saveConfig() {
        StorageLoadService.shared.saveAppConfig(appConfig)
    }
}

// MARK: - Generic browser

private struct GenericBrowserView: View {
    let section: AppSection?
    @Binding var selectedItemID: String?
    var body: some View {
        ContentUnavailableView("No items yet", systemImage: section?.icon ?? "tray",
            description: Text("Items will appear here once created."))
    }
}
