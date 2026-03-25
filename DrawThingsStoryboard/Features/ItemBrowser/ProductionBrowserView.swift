import SwiftUI

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
            QueueSection(
                queue: $queue,
                selectedJobID: $selectedJobID,
                configs: $configs,
                selectedModelConfigID: $selectedModelConfigID,
                finishTimeString: finishTimeString
            )
            .frame(minHeight: 120)

            DoneSection(doneQueue: $doneQueue)
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

// MARK: - Queue section

private struct QueueSection: View {
    @Binding var queue: [GenerationJob]
    @Binding var selectedJobID: String?
    @Binding var configs: [DTModelConfig]
    @Binding var selectedModelConfigID: String?
    let finishTimeString: String

    var body: some View {
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
                }.listStyle(.plain)
            }
        }
    }
}

// MARK: - Done section

private struct DoneSection: View {
    @Binding var doneQueue: [GenerationJob]

    var body: some View {
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
    }
}

// MARK: - Production job row

struct ProductionJobRow: View {
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
            Text(job.jobType.letter).font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(job.jobType.color).frame(width: 14)
            Text(job.size.letter).font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(job.size == .large ? .green : .orange).frame(width: 14)
            thumbnailWithName(type: .look, name: job.lookName)
            if job.jobType != .generateExample {
                thumbnailWithName(type: itemThumbnailType, name: job.itemName)
            }
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

// MARK: - Done job row

struct DoneJobRow: View {
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
