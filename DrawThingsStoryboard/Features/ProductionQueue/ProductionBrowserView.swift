import SwiftUI
import Combine

// MARK: - Production browser
/// #82: Job type icons instead of letters
/// #83: Pushover hint when not configured
/// #84: Clear Done also empties production-log.json

struct ProductionBrowserView: View {
    @Binding var queue: [GenerationJob]
    @Binding var selectedJobID: String?
    @Binding var doneQueue: [GenerationJob]
    let models: ModelsFile
    @ObservedObject var queueRunner: QueueRunnerService
    let productionLog: ProductionLogFile
    @Binding var notificationsEnabled: Bool
    let pushoverConfigured: Bool
    /// #84: Callback to clear production log in ContentView
    var onClearProductionLog: (() -> Void)? = nil

    var body: some View {
        VSplitView {
            QueueSection(
                queue: $queue,
                selectedJobID: $selectedJobID,
                doneQueue: $doneQueue,
                models: models,
                queueRunner: queueRunner,
                productionLog: productionLog,
                notificationsEnabled: $notificationsEnabled,
                pushoverConfigured: pushoverConfigured
            )
            .frame(minHeight: 120)

            DoneSection(doneQueue: $doneQueue, selectedJobID: $selectedJobID, models: models, onClearProductionLog: onClearProductionLog)
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
    @Binding var doneQueue: [GenerationJob]
    let models: ModelsFile
    @ObservedObject var queueRunner: QueueRunnerService
    let productionLog: ProductionLogFile
    @Binding var notificationsEnabled: Bool
    let pushoverConfigured: Bool
    @State private var timerTick: Int = 0
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private func estimatedPerImage(size: GenerationSize, modelID: String) -> TimeInterval {
        let sizeStr = size.rawValue
        let isoFormatter = ISO8601DateFormatter()
        let matching = productionLog.generatedImages.filter { entry in
            entry.size == sizeStr && entry.modelID == modelID
                && !entry.startTime.isEmpty && !entry.endTime.isEmpty
        }
        let recent = matching.suffix(3)
        if !recent.isEmpty {
            let totalDuration = recent.reduce(0.0) { acc, entry in
                guard let start = isoFormatter.date(from: entry.startTime),
                      let end = isoFormatter.date(from: entry.endTime) else { return acc }
                return acc + end.timeIntervalSince(start)
            }
            return totalDuration / Double(recent.count)
        }
        if let model = models.models.first(where: { $0.modelID == modelID }) {
            return TimeInterval(size == .large ? model.defaultGenTimeLarge : model.defaultGenTimeSmall)
        }
        return size == .large ? 180 : 60
    }

    private var estimatedFinishString: String {
        guard !queue.isEmpty else { return "\u{2014}" }
        _ = timerTick
        var total: TimeInterval = 0
        for job in queue {
            let perImage = estimatedPerImage(size: job.size, modelID: job.modelID)
            let images = max(1, job.variantCount > 0 ? job.variantCount : 1)
            total += perImage * Double(images)
        }
        let finish = Date().addingTimeInterval(total)
        let fmt = DateFormatter(); fmt.timeStyle = .short
        return fmt.string(from: finish)
    }

    private var waitingCount: Int {
        queue.filter { $0.id != queueRunner.currentJobID }.count
    }

    private func modelName(for id: String) -> String {
        models.models.first(where: { $0.modelID == id })?.name ?? "?"
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "square.and.arrow.down.on.square").font(.title2).foregroundStyle(.secondary)
                    Text("Production Queue").font(.title2.bold())
                    Spacer()

                    // #83: Show toggle only when configured, otherwise show hint
                    if pushoverConfigured {
                        Toggle(isOn: $notificationsEnabled) {
                            Image(systemName: notificationsEnabled ? "bell.fill" : "bell.slash")
                                .font(.caption)
                                .foregroundStyle(notificationsEnabled ? .blue : .secondary)
                        }
                        .toggleStyle(.switch).controlSize(.mini)
                        .help("Send Pushover notifications when jobs complete")
                    } else {
                        Label("Set up Pushover in Settings", systemImage: "bell.badge")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    if queueRunner.isRunning && waitingCount > 0 {
                        Button {
                            queueRunner.stopQueue(queue: &queue)
                        } label: {
                            Label("Stop", systemImage: "stop.fill").font(.caption)
                        }
                        .buttonStyle(.bordered).controlSize(.small)
                        .tint(.red)
                        .help("Remove all waiting jobs from the queue. The running job will finish.")
                    }
                    if queueRunner.isRunning {
                        ProgressView().controlSize(.small)
                    }
                }
                if !queue.isEmpty {
                    Text("Estimated finish: \(estimatedFinishString)")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            Divider()

            if queue.isEmpty {
                Spacer()
                ContentUnavailableView("Queue is empty", systemImage: "tray",
                    description: Text("Queue generation jobs from the Styles, Assets, or Storyboard sections."))
                Spacer()
            } else {
                List(queue, selection: $selectedJobID) { job in
                    JobRow(
                        job: job,
                        isRunning: queueRunner.currentJobID == job.id,
                        estimatedDuration: estimatedPerImage(size: job.size, modelID: job.modelID) * Double(max(1, job.variantCount)),
                        modelName: modelName(for: job.modelID),
                        onDelete: {
                            guard queueRunner.currentJobID != job.id else { return }
                            queue.removeAll { $0.id == job.id }
                        }
                    )
                    .tag(job.id)
                }.listStyle(.plain)
            }
        }
        .onReceive(timer) { _ in
            timerTick += 1
        }
    }
}

// MARK: - Done section

private struct DoneSection: View {
    @Binding var doneQueue: [GenerationJob]
    @Binding var selectedJobID: String?
    let models: ModelsFile
    var onClearProductionLog: (() -> Void)? = nil

    private func modelName(for id: String) -> String {
        models.models.first(where: { $0.modelID == id })?.name ?? "?"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle").font(.subheadline).foregroundStyle(.secondary)
                Text("Done").font(.subheadline.bold())
                Spacer()
                if !doneQueue.isEmpty {
                    Button {
                        doneQueue.removeAll()
                        // #84: Also clear production log
                        onClearProductionLog?()
                    } label: { Text("Clear").font(.caption) }
                    .buttonStyle(.borderless).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            Divider()
            if doneQueue.isEmpty {
                Spacer()
                Text("Completed jobs will appear here.").font(.caption).foregroundStyle(.tertiary)
                Spacer()
            } else {
                List(doneQueue, selection: $selectedJobID) { job in
                    DoneJobRow(job: job, modelName: modelName(for: job.modelID))
                        .tag(job.id)
                }.listStyle(.plain)
            }
        }
    }
}

// MARK: - Job row
/// #82: Icons instead of letters for job type

private struct JobRow: View {
    let job: GenerationJob
    let isRunning: Bool
    let estimatedDuration: TimeInterval
    let modelName: String
    let onDelete: () -> Void

    /// #82: Icon for job type
    private var jobTypeIcon: String {
        switch job.jobType {
        case .generateStyle: return "paintbrush"
        case .generateAsset:
            return job.variantCount > 1 ? "square.grid.2x2" : "photo"
        case .generatePanel: return "list.and.film"
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            if isRunning {
                ProgressView().controlSize(.mini)
                    .frame(width: 14)
            } else {
                Image(systemName: jobTypeIcon)
                    .font(.system(size: 11))
                    .foregroundStyle(job.jobType.color).frame(width: 14)
            }
            // Size icon: small or large
            Image(systemName: job.size == .large
                  ? "arrow.up.left.and.arrow.down.right.rectangle"
                  : "arrow.down.right.and.arrow.up.left.square")
                .font(.system(size: 10))
                .foregroundStyle(job.size == .large ? .green : .orange).frame(width: 14)
            VStack(alignment: .leading, spacing: 1) {
                Text(job.itemName).font(.callout.weight(.medium)).lineLimit(1)
                HStack(spacing: 4) {
                    Text(modelName).font(.caption2).foregroundStyle(.blue.opacity(0.8)).lineLimit(1)
                    Text("\u{00b7}").font(.caption2).foregroundStyle(.quaternary)
                    Text(job.styleName).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            if isRunning {
                Text("Running").font(.caption2).foregroundStyle(.blue)
            } else {
                Text("~\(Int(estimatedDuration) / 60)m").font(.caption2).foregroundStyle(.tertiary)
            }
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)
            if !isRunning {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 14))
                        .symbolRenderingMode(.palette).foregroundStyle(.white, .secondary)
                }.buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Done job row
/// #82: Icons instead of letters in done rows

private struct DoneJobRow: View {
    let job: GenerationJob
    let modelName: String

    private var jobTypeIcon: String {
        switch job.jobType {
        case .generateStyle: return "paintbrush"
        case .generateAsset:
            return job.variantCount > 1 ? "square.grid.2x2" : "photo"
        case .generatePanel: return "list.and.film"
        }
    }

    private var durationString: String {
        guard let completed = job.completedAt, let started = job.startedAt else { return "" }
        let secs = Int(completed.timeIntervalSince(started))
        let m = secs / 60; let s = secs % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.system(size: 12))
            Image(systemName: jobTypeIcon)
                .font(.system(size: 11))
                .foregroundStyle(job.jobType.color).frame(width: 14)
            VStack(alignment: .leading, spacing: 1) {
                Text(job.itemName).font(.callout.weight(.medium)).lineLimit(1)
                HStack(spacing: 4) {
                    Text(modelName).font(.caption2).foregroundStyle(.blue.opacity(0.8)).lineLimit(1)
                    Text("\u{00b7}").font(.caption2).foregroundStyle(.quaternary)
                    Text(job.styleName).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            Text(durationString).font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
