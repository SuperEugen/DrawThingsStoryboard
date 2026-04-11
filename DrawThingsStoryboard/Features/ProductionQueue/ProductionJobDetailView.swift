import SwiftUI

// MARK: - Production job detail
/// #53: Shows modelID in job info
/// #58: Step-level progress bar
/// #92: Done jobs show production log entry

struct ProductionJobDetailView: View {
    let queue: [GenerationJob]
    let doneQueue: [GenerationJob]
    let productionLog: ProductionLogFile
    let selectedJobID: String?
    let models: ModelsFile
    let selectedModelID: String?
    let config: AppConfig
    let assets: AssetsFile
    @ObservedObject var queueRunner: QueueRunnerService

    private var selectedJob: GenerationJob? {
        guard let id = selectedJobID else { return nil }
        return queue.first { $0.id == id } ?? doneQueue.first { $0.id == id }
    }

    private var isDoneJob: Bool {
        guard let id = selectedJobID else { return false }
        return doneQueue.contains { $0.id == id }
    }

    private var isCurrentlyRunning: Bool {
        guard let job = selectedJob else { return false }
        return queueRunner.currentJobID == job.id
    }

    /// Production log entries matching the selected done job's saved image IDs.
    private var logEntries: [GeneratedImageEntry] {
        guard let job = selectedJob, isDoneJob else { return [] }
        let ids = Set(job.savedImageIDs)
        return productionLog.generatedImages.filter { ids.contains($0.imageID) }
    }

    private func modelName(for id: String) -> String {
        models.models.first(where: { $0.modelID == id })?.name ?? "?"
    }

    var body: some View {
        if let job = selectedJob {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Job")
                        infoRow("Type", job.jobType.rawValue)
                        infoRow("Size", job.size.rawValue)
                        infoRow("Model", modelName(for: job.modelID))
                        infoRow("Style", job.styleName)
                        infoRow("Item", job.itemName)
                        infoRow("Seed", job.seed == 0 ? "random" : "\(job.seed)")
                        infoRow("Dimensions", "\(job.width) x \(job.height)")
                    }
                    .padding(.bottom, 12)

                    Divider().padding(.vertical, 8)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            sectionLabel("Combined Prompt")
                            Spacer()
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(job.combinedPrompt, forType: .string)
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc").font(.caption)
                            }
                            .buttonStyle(.bordered).controlSize(.mini)
                        }
                        Text(job.combinedPrompt)
                            .font(.callout).foregroundStyle(.secondary).textSelection(.enabled)
                            .padding(8).frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.accentColor.opacity(0.05)))
                    }
                    .padding(.bottom, 12)

                    Divider().padding(.vertical, 8)

                    if isDoneJob {
                        ProductionLogPanel(logEntries: logEntries, models: models)
                    } else {
                        GenerationProgressPanel(
                            isCurrentJob: isCurrentlyRunning,
                            queueRunner: queueRunner,
                            queuePosition: queuePosition(for: job)
                        )
                    }

                    Spacer(minLength: 20)
                }
                .padding(14)
            }
            .background(Color(NSColor.windowBackgroundColor))
        } else {
            ContentUnavailableView(
                "No job selected", systemImage: "tray",
                description: Text("Select a job from the queue to see its details."))
        }
    }

    private func queuePosition(for job: GenerationJob) -> Int {
        guard let idx = queue.firstIndex(where: { $0.id == job.id }) else { return 0 }
        return idx + 1
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.callout).foregroundStyle(.secondary).frame(width: 80, alignment: .leading)
            Text(value).font(.callout)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Generation progress panel
/// #58: Step-level progress bar instead of variant-level

private struct GenerationProgressPanel: View {
    let isCurrentJob: Bool
    @ObservedObject var queueRunner: QueueRunnerService
    let queuePosition: Int

    /// Total steps across all variants
    private var totalSteps: Int {
        queueRunner.totalVariants * queueRunner.stepsPerVariant
    }

    /// Global step position (completed variant steps + current step)
    private var globalStep: Int {
        queueRunner.currentVariant * queueRunner.stepsPerVariant + queueRunner.currentStep
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Progress")

            if isCurrentJob {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Generating \(queueRunner.currentVariant + 1)/\(queueRunner.totalVariants)\u{2026}")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.blue)
                }

                // #58: Step-level progress bar
                ProgressView(value: Double(globalStep), total: Double(max(1, totalSteps)))
                    .progressViewStyle(.linear)

                // Step counter + stage text
                HStack(spacing: 4) {
                    Text("Step \(globalStep)/\(totalSteps)")
                        .font(.caption).foregroundStyle(.tertiary)
                    if !queueRunner.generationStage.isEmpty {
                        Text("\u{2014}").font(.caption).foregroundStyle(.quaternary)
                        Text(queueRunner.generationStage)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                if !queueRunner.generatedImages.isEmpty {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(Array(queueRunner.generatedImages.enumerated()), id: \.offset) { _, img in
                            Image(nsImage: img).resizable().scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }

                if let err = queueRunner.errorMessage {
                    Label(err, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption).foregroundStyle(.red)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text("Waiting \u{2014} position \(queuePosition) in queue")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Production log panel
/// #92: Shows production log entries for a completed job

private struct ProductionLogPanel: View {
    let logEntries: [GeneratedImageEntry]
    let models: ModelsFile

    private func modelName(for id: String) -> String {
        models.models.first(where: { $0.modelID == id })?.name ?? id
    }

    private func durationString(for entry: GeneratedImageEntry) -> String {
        let fmt = ISO8601DateFormatter()
        guard let start = fmt.date(from: entry.startTime),
              let end = fmt.date(from: entry.endTime) else { return "" }
        let secs = Int(end.timeIntervalSince(start))
        let m = secs / 60; let s = secs % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Production Log")

            if logEntries.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text").foregroundStyle(.secondary)
                    Text("No log entry available for this job.")
                        .font(.callout).foregroundStyle(.secondary)
                }
            } else {
                ForEach(logEntries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
                            Text(entry.type.isEmpty ? "Generated" : entry.type)
                                .font(.callout.weight(.medium))
                            Spacer()
                            Text(durationString(for: entry))
                                .font(.caption).foregroundStyle(.tertiary)
                        }
                        HStack(spacing: 4) {
                            Text(modelName(for: entry.modelID)).font(.caption2).foregroundStyle(.blue.opacity(0.8))
                            Text("\u{00b7}").font(.caption2).foregroundStyle(.quaternary)
                            Text(entry.size).font(.caption2).foregroundStyle(.secondary)
                            Text("\u{00b7}").font(.caption2).foregroundStyle(.quaternary)
                            Text("Seed: \(entry.seed)").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.accentColor.opacity(0.05)))
                }
            }
        }
        .padding(.bottom, 12)
    }
}
