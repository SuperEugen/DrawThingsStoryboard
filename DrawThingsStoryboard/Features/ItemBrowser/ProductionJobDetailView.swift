import SwiftUI

// MARK: - Production job detail (read-only view of a queued job)

struct ProductionJobDetailView: View {
    let queue: [GenerationJob]
    let selectedJobID: String?
    let modelConfigs: [DTModelConfig]
    let selectedModelConfigID: String?
    let episodeName: String

    @StateObject private var vm = ImageGenerationViewModel()

    private var selectedJob: GenerationJob? {
        guard let id = selectedJobID else { return nil }
        return queue.first { $0.id == id }
    }

    var body: some View {
        if let job = selectedJob {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    UnifiedThumbnailView(
                        itemType: jobThumbnailType(job),
                        name: "", sizeMode: .header
                    )
                    .padding(.bottom, 16)

                    JobMetaSection(job: job)
                    JobDimensionsSection(job: job)
                    JobPromptSection(job: job)
                    JobTimingSection(job: job)

                    Divider().padding(.vertical, 8)

                    GenerateTestPanel(job: job, episodeName: episodeName, vm: vm)

                    Spacer(minLength: 20)
                }
                .padding(14)
            }
            .background(Color(NSColor.windowBackgroundColor))
            .onChange(of: job.id) { _, _ in syncJob(job) }
            .onChange(of: selectedModelConfigID) { _, _ in syncJob(job) }
            .onAppear { syncJob(job) }
        } else {
            ContentUnavailableView(
                "No job selected", systemImage: "tray",
                description: Text("Select a job from the queue to see its details.")
            )
        }
    }

    private func syncJob(_ job: GenerationJob) {
        vm.prompt  = job.combinedPrompt
        vm.seed    = Int(job.seed)
        vm.width   = job.width
        vm.height  = job.height
        let config = modelConfigs.first { $0.id == selectedModelConfigID } ?? modelConfigs.first
        if let config {
            vm.steps         = config.steps
            vm.guidanceScale = config.guidanceScale
            vm.model         = config.model
        }
    }

    private func jobThumbnailType(_ job: GenerationJob) -> ThumbnailItemType {
        switch job.jobType {
        case .generatePanel:   return .panel
        case .generateExample: return .look
        case .generateAsset:
            return job.itemType == .character
                ? .character(gender: job.itemGender)
                : .location(setting: job.itemLocationSetting)
        }
    }
}

// MARK: - Job meta section (item, type, size, look, assets)

private struct JobMetaSection: View {
    let job: GenerationJob
    var body: some View {
        Group {
            infoRow(label: "Item") {
                HStack(spacing: 6) {
                    Image(systemName: job.itemIcon).foregroundStyle(job.jobType.color)
                    Text(job.itemName).font(.callout.weight(.medium))
                }
            }
            Divider().padding(.vertical, 8)
            infoRow(label: "Job Type") {
                HStack(spacing: 6) {
                    Image(systemName: job.jobType.icon).foregroundStyle(job.jobType.color)
                    Text(job.jobType.rawValue).font(.callout)
                }
            }
            infoRow(label: "Size")     { Text(job.size.rawValue).font(.callout) }
            infoRow(label: "Look")     { Text(job.lookName).font(.callout) }
            infoRow(label: "Item Type") {
                Text(job.itemType == .character ? "Character" : "Location").font(.callout)
            }
            if !job.attachedAssets.isEmpty {
                Divider().padding(.vertical, 8)
                AttachedAssetsView(assets: job.attachedAssets)
            }
        }
    }
}

// MARK: - Attached assets

private struct AttachedAssetsView: View {
    let assets: [JobAssetInfo]
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Attached Assets")
            VStack(alignment: .leading, spacing: 6) {
                ForEach(assets) { asset in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill((asset.type == .character ? Color.blue : Color.teal).opacity(0.15))
                            .frame(width: 28, height: 28)
                            .overlay {
                                Image(systemName: asset.icon)
                                    .font(.system(size: 12))
                                    .foregroundStyle(asset.type == .character ? .blue : .teal)
                            }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(asset.name).font(.callout.weight(.medium))
                            Text(asset.type == .character ? "Character" : "Location")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.05)))
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Dimensions + seed section

private struct JobDimensionsSection: View {
    let job: GenerationJob
    var body: some View {
        Group {
            Divider().padding(.vertical, 8)
            infoRow(label: "Width")  { Text("\(job.width) px").font(.callout) }
            infoRow(label: "Height") { Text("\(job.height) px").font(.callout) }
            if job.variantCount > 0 {
                infoRow(label: "Variants") { Text("\(job.variantCount)").font(.callout) }
            }
            infoRow(label: "Seed") {
                Text(job.seed == -1 ? "random" : "\(job.seed)").font(.callout.monospaced())
            }
        }
    }
}

// MARK: - Combined prompt section

private struct JobPromptSection: View {
    let job: GenerationJob
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider().padding(.vertical, 8)
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
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 0.5))
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Timing section

private struct JobTimingSection: View {
    let job: GenerationJob
    private var durationString: String {
        let m = Int(job.estimatedDuration) / 60
        let s = Int(job.estimatedDuration) % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }
    var body: some View {
        Group {
            Divider().padding(.vertical, 8)
            infoRow(label: "Queued At") { Text(job.queuedAt, style: .time).font(.callout) }
            infoRow(label: "Est. Duration") { Text(durationString).font(.callout) }
        }
    }
}

// MARK: - Shared infoRow helper

private func infoRow<C: View>(label: String, @ViewBuilder content: () -> C) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        sectionLabel(label)
        content()
    }
    .padding(.bottom, 12)
}

// MARK: - Generate test panel

private struct GenerateTestPanel: View {
    let job: GenerationJob
    let episodeName: String
    @ObservedObject var vm: ImageGenerationViewModel

    @State private var savedURL: URL? = nil
    @State private var saveError: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Generate (Test)")
            generateButtonRow
            resultImageView
            errorView
        }
        .padding(.bottom, 12)
    }

    private var generateButtonRow: some View {
        HStack(spacing: 10) {
            Button {
                savedURL = nil; saveError = nil
                Task { await vm.generate(); await saveGeneratedImage() }
            } label: {
                Label(
                    vm.isGenerating ? "Generating…" : "Generate",
                    systemImage: vm.isGenerating ? "hourglass" : "wand.and.stars"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isGenerating || vm.prompt.isEmpty)

            if vm.isGenerating, !vm.generationStage.isEmpty {
                Text(vm.generationStage)
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var resultImageView: some View {
        if let image = vm.generatedImage {
            Image(nsImage: image)
                .resizable().scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5))
                .frame(maxWidth: .infinity).padding(.top, 4)
            if let url = savedURL {
                Label(url.path, systemImage: "checkmark.circle.fill")
                    .font(.caption2).foregroundStyle(.green)
                    .lineLimit(1).truncationMode(.middle)
            }
        }
        if let err = saveError {
            Label(err, systemImage: "exclamationmark.triangle.fill")
                .font(.caption).foregroundStyle(.orange)
        }
    }

    @ViewBuilder
    private var errorView: some View {
        if let error = vm.errorMessage {
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .font(.caption).foregroundStyle(.red).padding(.top, 2)
        }
    }

    @MainActor
    private func saveGeneratedImage() async {
        guard let image = vm.generatedImage else { return }
        do {
            switch job.jobType {
            case .generatePanel:
                savedURL = try StorageService.shared.savePanelImage(image, panelID: job.id, episodeName: episodeName)
            case .generateExample:
                savedURL = try StorageService.shared.saveLookExample(image, lookName: job.lookName)
            case .generateAsset:
                savedURL = try StorageService.shared.saveVariantImage(image, assetID: job.id, variantIndex: 0)
            }
        } catch {
            saveError = error.localizedDescription
        }
    }
}
