import SwiftUI

// MARK: - Production job detail (read-only view of a queued job)

struct ProductionJobDetailView: View {
    let queue: [GenerationJob]
    let selectedJobID: String?
    let modelConfigs: [DTModelConfig]
    let selectedModelConfigID: String?
    let episodeName: String
    var onJobCompleted: ((GenerationJob) -> Void)? = nil

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

                    GenerateTestPanel(job: job, episodeName: episodeName, vm: vm, onJobCompleted: onJobCompleted)

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
        // For panel jobs: load attached asset images into moodboard (max 3) + initImage (4th)
        if job.jobType == .generatePanel {
            let assetImages: [NSImage] = job.attachedAssets.compactMap { asset in
                StorageService.shared.loadFirstAvailableVariant(assetID: asset.id)
            }
            vm.moodboardImages = Array(assetImages.prefix(3))
            vm.initImage       = assetImages.count >= 4 ? assetImages[3] : nil
            print("[syncJob] Panel assets: \(assetImages.count) loaded, moodboard: \(vm.moodboardImages.count), initImage: \(vm.initImage != nil)")
        } else {
            vm.moodboardImages = []
            vm.initImage       = nil
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

// MARK: - Job meta section

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
            infoRow(label: "Size")      { Text(job.size.rawValue).font(.callout) }
            infoRow(label: "Look")      { Text(job.lookName).font(.callout) }
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
    private var estString: String {
        let m = Int(job.estimatedDuration) / 60
        let s = Int(job.estimatedDuration) % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }
    var body: some View {
        Group {
            Divider().padding(.vertical, 8)
            infoRow(label: "Queued At")     { Text(job.queuedAt, style: .time).font(.callout) }
            infoRow(label: "Est. Duration") { Text(estString).font(.callout) }
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
    var onJobCompleted: ((GenerationJob) -> Void)? = nil

    @State private var savedURLs: [URL] = []
    @State private var generatedImages: [NSImage] = []
    @State private var saveError: String? = nil
    @State private var startedAt: Date? = nil
    @State private var currentVariant: Int = 0

    private var totalVariants: Int {
        job.jobType == .generateAsset ? max(1, job.variantCount) : 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Generate (Test)")
            generateButtonRow
            variantImagesView
            savedPathsView
            errorView
        }
        .padding(.bottom, 12)
    }

    private var generateButtonRow: some View {
        HStack(spacing: 10) {
            Button { startGeneration() } label: {
                Label(
                    vm.isGenerating
                        ? "Generating \(currentVariant + 1)/\(totalVariants)…"
                        : "Generate",
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
    private var variantImagesView: some View {
        if !generatedImages.isEmpty {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Array(generatedImages.enumerated()), id: \.offset) { idx, img in
                    Image(nsImage: img)
                        .resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5))
                        .overlay(alignment: .bottomTrailing) {
                            Text("V\(idx + 1)")
                                .font(.system(size: 9, weight: .bold))
                                .padding(3)
                                .background(Color.black.opacity(0.5))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                                .padding(4)
                        }
                }
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var savedPathsView: some View {
        if !savedURLs.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(savedURLs.enumerated()), id: \.offset) { _, url in
                    Label(url.lastPathComponent, systemImage: "checkmark.circle.fill")
                        .font(.caption2).foregroundStyle(.green).lineLimit(1)
                }
            }
        }
    }

    @ViewBuilder
    private var errorView: some View {
        if let err = saveError {
            Label(err, systemImage: "exclamationmark.triangle.fill")
                .font(.caption).foregroundStyle(.orange)
        }
        if let error = vm.errorMessage {
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .font(.caption).foregroundStyle(.red).padding(.top, 2)
        }
    }

    // MARK: - Generation logic

    private func startGeneration() {
        savedURLs = []
        generatedImages = []
        saveError = nil
        currentVariant = 0
        startedAt = Date()
        Task { await generateNextVariant() }
    }

    @MainActor
    private func generateNextVariant() async {
        guard currentVariant < totalVariants else {
            var done = job
            done.startedAt = startedAt
            done.completedAt = Date()
            onJobCompleted?(done)
            return
        }
        // Vary seed per variant when using random seed
        if job.seed == -1 {
            vm.seed = -1
        } else {
            vm.seed = Int(job.seed) + currentVariant
        }
        await vm.generate()
        guard let image = vm.generatedImage else {
            saveError = vm.errorMessage ?? "No image for variant \(currentVariant + 1)"
            return
        }
        generatedImages.append(image)
        await saveVariant(image: image, index: currentVariant)
        currentVariant += 1
        await generateNextVariant()
    }

    @MainActor
    private func saveVariant(image: NSImage, index: Int) async {
        do {
            let url: URL
            switch job.jobType {
            case .generateAsset:
                url = try StorageService.shared.saveVariantImage(image, assetID: job.id, variantIndex: index)
            case .generateExample:
                url = try StorageService.shared.saveLookExample(image, lookName: job.lookName)
            case .generatePanel:
                url = try StorageService.shared.savePanelImage(image, panelID: job.id, episodeName: episodeName)
            }
            savedURLs.append(url)
        } catch {
            saveError = error.localizedDescription
        }
    }
}
