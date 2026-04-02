import SwiftUI

// MARK: - Production browser

struct ProductionBrowserView: View {
    @Binding var queue: [GenerationJob]
    @Binding var selectedJobID: String?
    @Binding var doneQueue: [GenerationJob]
    @Binding var models: ModelsFile
    @Binding var selectedModelID: String?

    var body: some View {
        VSplitView {
            QueueSection(
                queue: $queue,
                selectedJobID: $selectedJobID,
                models: $models,
                selectedModelID: $selectedModelID
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
    @Binding var models: ModelsFile
    @Binding var selectedModelID: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "film.stack").font(.title2).foregroundStyle(.secondary)
                Text("Production Queue").font(.title2.bold())
                Spacer()
                Picker("Model", selection: Binding(
                    get: { selectedModelID ?? models.models.first?.modelID ?? "" },
                    set: { selectedModelID = $0 }
                )) {
                    ForEach(models.models) { m in Text(m.name).tag(m.modelID) }
                }
                .pickerStyle(.menu).labelsHidden().frame(maxWidth: 160)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            Divider()

            if queue.isEmpty {
                Spacer()
                ContentUnavailableView("Queue is empty", systemImage: "tray",
                    description: Text("Jobs appear here when you click Generate."))
                Spacer()
            } else {
                List(queue, selection: $selectedJobID) { job in
                    JobRow(job: job, onDelete: { queue.removeAll { $0.id == job.id } })
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
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(job.jobType.letter).font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(job.jobType.color).frame(width: 14)
            Text(job.size.letter).font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(job.size == .large ? .green : .orange).frame(width: 14)
            VStack(alignment: .leading, spacing: 1) {
                Text(job.itemName).font(.callout.weight(.medium)).lineLimit(1)
                Text(job.styleName).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Text("~\(Int(job.estimatedDuration) / 60)m").font(.caption2).foregroundStyle(.tertiary)
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill").font(.system(size: 14))
                    .symbolRenderingMode(.palette).foregroundStyle(.white, .secondary)
            }.buttonStyle(.plain)
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
