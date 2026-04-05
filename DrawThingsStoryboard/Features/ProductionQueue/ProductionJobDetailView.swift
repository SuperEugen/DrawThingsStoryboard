import SwiftUI

// MARK: - Production job detail
/// Now shows live progress from QueueRunnerService instead of a manual Generate button.

struct ProductionJobDetailView: View {
    let queue: [GenerationJob]
    let selectedJobID: String?
    let models: ModelsFile
    let selectedModelID: String?
    let config: AppConfig
    let assets: AssetsFile
    @ObservedObject var queueRunner: QueueRunnerService

    private var selectedJob: GenerationJob? {
        guard let id = selectedJobID else { return nil }
        return queue.first { $0.id == id }
    }

    private var isCurrentlyRunning: Bool {
        guard let job = selectedJob else { return false }
        return queueRunner.currentJobID == job.id
    }

    var body: some View {
        if let job = selectedJob {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Job")
                        infoRow("Type", job.jobType.rawValue)
                        infoRow("Size", job.size.rawValue)
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

                    // Live progress from QueueRunner
                    GenerationProgressPanel(
                        isCurrentJob: isCurrentlyRunning,
                        queueRunner: queueRunner,
                        queuePosition: queuePosition(for: job)
                    )

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

private struct GenerationProgressPanel: View {
    let isCurrentJob: Bool
    @ObservedObject var queueRunner: QueueRunnerService
    let queuePosition: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Progress")

            if isCurrentJob {
                // This job is currently being generated
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Generating \(queueRunner.currentVariant + 1)/\(queueRunner.totalVariants)\u{2026}")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.blue)
                }

                ProgressView(value: Double(queueRunner.currentVariant), total: Double(queueRunner.totalVariants))
                    .progressViewStyle(.linear)

                if !queueRunner.generationStage.isEmpty {
                    Text(queueRunner.generationStage)
                        .font(.caption).foregroundStyle(.secondary)
                }

                // Show generated images so far
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
                // Waiting in queue
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
