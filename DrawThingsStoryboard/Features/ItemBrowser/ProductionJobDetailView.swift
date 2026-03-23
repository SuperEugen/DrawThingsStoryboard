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
                    // Header thumbnail
                    UnifiedThumbnailView(
                        itemType: jobThumbnailType(job),
                        name: "",
                        sizeMode: .header
                    )
                    .padding(.bottom, 16)

                    // Item name
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Item")
                        HStack(spacing: 6) {
                            Image(systemName: job.itemIcon)
                                .foregroundStyle(job.jobType.color)
                            Text(job.itemName)
                                .font(.callout.weight(.medium))
                        }
                    }
                    .padding(.bottom, 12)

                    Divider().padding(.vertical, 8)

                    // Job type
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Job Type")
                        HStack(spacing: 6) {
                            Image(systemName: job.jobType.icon)
                                .foregroundStyle(job.jobType.color)
                            Text(job.jobType.rawValue)
                                .font(.callout)
                        }
                    }
                    .padding(.bottom, 12)

                    // Size
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Size")
                        Text(job.size.rawValue)
                            .font(.callout)
                    }
                    .padding(.bottom, 12)

                    // Look
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Look")
                        Text(job.lookName)
                            .font(.callout)
                    }
                    .padding(.bottom, 12)

                    // Item type
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Item Type")
                        Text(job.itemType == .character ? "Character" : "Location")
                            .font(.callout)
                    }
                    .padding(.bottom, 12)

                    // Attached assets (panel jobs only)
                    if !job.attachedAssets.isEmpty {
                        Divider().padding(.vertical, 8)
                        VStack(alignment: .leading, spacing: 6) {
                            sectionLabel("Attached Assets")
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(job.attachedAssets) { asset in
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
                                            Text(asset.name)
                                                .font(.callout.weight(.medium))
                                            Text(asset.type == .character ? "Character" : "Location")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(Color.accentColor.opacity(0.05))
                            )
                        }
                        .padding(.bottom, 12)
                    }

                    Divider().padding(.vertical, 8)

                    // Dimensions
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Width")
                        Text("\(job.width) px")
                            .font(.callout)
                    }
                    .padding(.bottom, 12)

                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Height")
                        Text("\(job.height) px")
                            .font(.callout)
                    }
                    .padding(.bottom, 12)

                    // Variant count (if applicable)
                    if job.variantCount > 0 {
                        VStack(alignment: .leading, spacing: 6) {
                            sectionLabel("Variants")
                            Text("\(job.variantCount)")
                                .font(.callout)
                        }
                        .padding(.bottom, 12)
                    }

                    // Seed
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Seed")
                        Text(job.seed == -1 ? "random" : "\(job.seed)")
                            .font(.callout.monospaced())
                    }
                    .padding(.bottom, 12)

                    Divider().padding(.vertical, 8)

                    // Combined Prompt
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            sectionLabel("Combined Prompt")
                            Spacer()
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(job.combinedPrompt, forType: .string)
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                        Text(job.combinedPrompt)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.accentColor.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                            )
                    }
                    .padding(.bottom, 12)

                    Divider().padding(.vertical, 8)

                    // Timing
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Queued At")
                        Text(job.queuedAt, style: .time)
                            .font(.callout)
                    }
                    .padding(.bottom, 12)

                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Estimated Duration")
                        let mins = Int(job.estimatedDuration) / 60
                        let secs = Int(job.estimatedDuration) % 60
                        Text(mins > 0 ? "\(mins)m \(secs)s" : "\(secs)s")
                            .font(.callout)
                    }
                    .padding(.bottom, 12)

                    Divider().padding(.vertical, 8)

                    // ── Test: Generate via Draw Things ──────────────────────────
                    GenerateTestPanel(job: job, vm: vm, episodeName: episodeName)

                    Spacer(minLength: 20)
                }
                .padding(14)
            }
            .background(Color(NSColor.windowBackgroundColor))
            // Sync job into vm whenever selection changes
            .onChange(of: job.id) { _, _ in syncJob(job) }
            .onChange(of: selectedModelConfigID) { _, _ in syncJob(job) }
            .onAppear { syncJob(job) }
        } else {
            ContentUnavailableView(
                "No job selected",
                systemImage: "tray",
                description: Text("Select a job from the queue to see its details.")
            )
        }
    }

    // MARK: - Helpers

    private func syncJob(_ job: GenerationJob) {
        // Prompt + seed from the job
        vm.prompt = job.combinedPrompt
        vm.seed   = Int(job.seed)
        // Width + height from the job (Small vs Large)
        vm.width  = job.width
        vm.height = job.height
        // Model, steps, guidance from the selected DTModelConfig
        let config = modelConfigs.first { $0.id == selectedModelConfigID }
                  ?? modelConfigs.first
        if let config {
            vm.steps         = config.steps
            vm.guidanceScale = config.guidanceScale
            vm.model         = config.model
        }
    }

    private func jobThumbnailType(_ job: GenerationJob) -> ThumbnailItemType {
        switch job.jobType {
        case .generatePanel:
            return .panel
        case .generateExample:
            return .look
        case .generateAsset:
            return job.itemType == .character
                ? .character(gender: job.itemGender)
                : .location(setting: job.itemLocationSetting)
        }
    }
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

            // Generate button + progress label
            HStack(spacing: 10) {
                Button {
                    savedURL = nil
                    saveError = nil
                    Task {
                        await vm.generate()
                        await saveGeneratedImage()
                    }
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
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            // Result image
            if let image = vm.generatedImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)

                // Saved path indicator
                if let url = savedURL {
                    Label(url.path, systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            // Save error
            if let err = saveError {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            // Error
            if let error = vm.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 2)
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Save

    @MainActor
    private func saveGeneratedImage() async {
        guard let image = vm.generatedImage else { return }
        let storage = StorageService.shared
        do {
            switch job.jobType {
            case .generatePanel:
                savedURL = try storage.savePanelImage(
                    image,
                    panelID: job.id,
                    episodeName: episodeName
                )
            case .generateExample:
                savedURL = try storage.saveLookExample(
                    image,
                    lookName: job.lookName
                )
            case .generateAsset:
                // Use job ID as assetID, index 0 for now
                savedURL = try storage.saveVariantImage(
                    image,
                    assetID: job.id,
                    variantIndex: 0
                )
            }
        } catch {
            saveError = error.localizedDescription
        }
    }
}
