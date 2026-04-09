import SwiftUI

/// #55: Compact queue status shown in the app toolbar.
/// Shows spinner + job count + estimated finish time when queue is running.

struct QueueStatusToolbarView: View {
    let queue: [GenerationJob]
    @ObservedObject var queueRunner: QueueRunnerService
    let productionLog: ProductionLogFile
    let models: ModelsFile

    @State private var timerTick: Int = 0
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    /// #54-style model-aware estimation (same logic as ProductionBrowserView).
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

    var body: some View {
        if queueRunner.isRunning {
            HStack(spacing: 6) {
                ProgressView().controlSize(.mini)
                Text("Queue (\(queue.count)) \u{2014} ~\(estimatedFinishString)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .onReceive(timer) { _ in timerTick += 1 }
        } else if !queue.isEmpty {
            HStack(spacing: 4) {
                Image(systemName: "tray.full").font(.caption).foregroundStyle(.secondary)
                Text("\(queue.count) queued").font(.caption).foregroundStyle(.tertiary)
            }
        }
        // When idle and queue empty: show nothing
    }
}
