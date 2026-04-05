import SwiftUI
import Combine

// MARK: - Production browser

struct ProductionBrowserView: View {
    @Binding var queue: [GenerationJob]
    @Binding var selectedJobID: String?
    @Binding var doneQueue: [GenerationJob]
    @Binding var models: ModelsFile
    @Binding var selectedModelID: String?
    @ObservedObject var queueRunner: QueueRunnerService
    let productionLog: ProductionLogFile

    var body: some View {
        VSplitView {
            QueueSection(
                queue: $queue,
                selectedJobID: $selectedJobID,
                doneQueue: $doneQueue,
                models: $models,
                selectedModelID: $selectedModelID,
                queueRunner: queueRunner,
                productionLog: productionLog
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
    @Binding var doneQueue: [GenerationJob]
    @Binding var models: ModelsFile
    @Binding var selectedModelID: String?
    @ObservedObject var queueRunner: QueueRunnerService
    let productionLog: ProductionLogFile
    // #27: Timer for live finish time updates
    @State private var timerTick: Int = 0
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    /// Estimate seconds per image from production log (last 3 entries of matching size).
    /// Falls back to 60s for small, 180s for large if no log data.
    private func estimatedPerImage(size: GenerationSize) -> TimeInterval {
        let sizeStr = size.rawValue
        let isoFormatter = ISO8601DateFormatter()
        let matching = productionLog.generatedImages.filter { entry in
            entry.size == sizeStr && !entry.startTime.isEmpty && !entry.endTime.isEmpty
        }
        let recent = matching.suffix(3)
        guard !recent.isEmpty else {
            return size == .large ? 180 : 60
        }
        let totalDuration = recent.reduce(0.0) { acc, entry in
            guard let start = isoFormatter.date(from: entry.startTime),
                  let end = isoFormatter.date(from: entry.endTime) else { return acc }
            return acc + end.timeIntervalSince(start)
        }
        return totalDuration / Double(recent.count)
    }

    private var estimatedFinishString: String {
        guard !queue.isEmpty else { return "\u{2014}" }
        _ = timerTick
        var total: TimeInterval = 0
        for job in queue {
            let perImage = estimatedPerImage(size: job.size)
            let images = max(1, job.variantCount > 0 ? job.variantCount : 1)
            total += perImage * Double(images)
        }
        let finish = Date().addingTimeInterval(total)
        let fmt = DateFormatter(); fmt.timeStyle = .short
        return fmt.string(from: finish)
    }

    /// Number of waiting (non-running) jobs in the queue.
    private var waitingCount: Int {
        queue.filter { $0.id != queueRunner.currentJobID }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "film.stack").font(.title2).foregroundStyle(.secondary)
                    Text("Production Queue").font(.title2.bold())
                    Spacer()
                    // Stop button: removes all waiting jobs
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
                    Picker("Model", selection: Binding(
                        get: { selectedModelID ?? models.models.first?.modelID ?? "" },
                        set: { selectedModelID = $0 }
                    )) {
                        ForEach(models.models) { m in Text(m.name).tag(m.modelID) }
                    }
                    .pickerStyle(.menu).labelsHidden().frame(maxWidth: 160)
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
                        estimatedDuration: estimatedPerImage(size: job.size) * Double(max(1, job.variantCount)),
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
                Text("Completed jobs will appear here.").font(.caption).foregroundStyle(.tertiary)
                Spacer()
            } else {
                List(doneQueue) { job in
                    DoneJobRow(job: job)
                }.listStyle(.plain)
            }
        }
    }
}

// MARK: - Job row

private struct JobRow: View {
    let job: GenerationJob
    let isRunning: Bool
    let estimatedDuration: TimeInterval
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            if isRunning {
                ProgressView().controlSize(.mini)
                    .frame(width: 14)
            } else {
                Text(job.jobType.letter).font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(job.jobType.color).frame(width: 14)
            }
            Text(job.size.letter).font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(job.size == .large ? .green : .orange).frame(width: 14)
            VStack(alignment: .leading, spacing: 1) {
                Text(job.itemName).font(.callout.weight(.medium)).lineLimit(1)
                Text(job.styleName).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
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

private struct DoneJobRow: View {
    let job: GenerationJob

    private var durationString: String {
        guard let completed = job.completedAt, let started = job.startedAt else { return "" }
        let secs = Int(completed.timeIntervalSince(started))
        let m = secs / 60; let s = secs % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.system(size: 12))
            Text(job.jobType.letter).font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(job.jobType.color).frame(width: 14)
            VStack(alignment: .leading, spacing: 1) {
                Text(job.itemName).font(.callout.weight(.medium)).lineLimit(1)
                Text(job.styleName).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Text(durationString).font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
