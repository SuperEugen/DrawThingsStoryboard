import SwiftUI

// MARK: - Production job detail

struct ProductionJobDetailView: View {
    let queue: [GenerationJob]
    let selectedJobID: String?
    let models: ModelsFile
    let selectedModelID: String?
    let config: AppConfig
    let assets: AssetsFile
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

                    GeneratePanel(
                        job: job,
                        vm: vm,
                        onJobCompleted: onJobCompleted
                    )

                    Spacer(minLength: 20)
                }
                .padding(14)
            }
            .background(Color(NSColor.windowBackgroundColor))
            .onChange(of: job.id) { _, _ in syncJob(job) }
            .onAppear { syncJob(job) }
        } else {
            ContentUnavailableView(
                "No job selected", systemImage: "tray",
                description: Text("Select a job from the queue to see its details and generate."))
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.callout).foregroundStyle(.secondary).frame(width: 80, alignment: .leading)
            Text(value).font(.callout)
        }
        .padding(.vertical, 2)
    }

    private func syncJob(_ job: GenerationJob) {
        vm.prompt  = job.combinedPrompt
        vm.seed    = job.seed
        vm.width   = job.width
        vm.height  = job.height
        // #19: Pass gRPC connection settings from config
        vm.grpcAddress = config.grpcAddress
        vm.grpcPort    = config.grpcPort
        let model = models.models.first { $0.modelID == selectedModelID } ?? models.models.first
        if let model {
            vm.steps         = model.steps
            vm.guidanceScale = model.guidanceScale
            vm.model         = model.model
        }
    }
}

// MARK: - Generate panel

private struct GeneratePanel: View {
    let job: GenerationJob
    @ObservedObject var vm: ImageGenerationViewModel
    var onJobCompleted: ((GenerationJob) -> Void)? = nil

    @State private var generatedImages: [NSImage] = []
    @State private var startedAt: Date? = nil
    @State private var currentVariant: Int = 0
    @State private var saveError: String? = nil
    @State private var savedImageIDs: [String] = []

    private var totalVariants: Int {
        job.jobType == .generateAsset ? max(1, job.variantCount) : 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Generate")
            HStack(spacing: 10) {
                Button { startGeneration() } label: {
                    Label(
                        vm.isGenerating
                            ? "Generating \(currentVariant + 1)/\(totalVariants)\u{2026}"
                            : "Generate",
                        systemImage: vm.isGenerating ? "hourglass" : "wand.and.stars"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isGenerating || vm.prompt.isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }

            if vm.isGenerating {
                ProgressView(value: Double(currentVariant), total: Double(totalVariants))
                    .progressViewStyle(.linear)
                if !vm.generationStage.isEmpty {
                    Text(vm.generationStage).font(.caption).foregroundStyle(.secondary)
                }
            }

            if !generatedImages.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Array(generatedImages.enumerated()), id: \.offset) { _, img in
                        Image(nsImage: img).resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }

            if let err = saveError {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(.orange)
            }
            if let error = vm.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(.red)
            }
        }
        .padding(.bottom, 12)
    }

    private func startGeneration() {
        generatedImages = []
        savedImageIDs = []
        saveError = nil
        currentVariant = 0
        startedAt = Date()
        Task { await generateNext() }
    }

    @MainActor
    private func generateNext() async {
        guard currentVariant < totalVariants else {
            var done = job
            done.startedAt = startedAt
            done.completedAt = Date()
            done.savedImageIDs = savedImageIDs
            onJobCompleted?(done)
            return
        }

        vm.seed = job.seed == 0 ? SeedHelper.randomSeed() : job.seed + currentVariant
        await vm.generate()

        if let image = vm.generatedImage {
            generatedImages.append(image)
            do {
                let imageID = try StorageService.shared.saveImage(image)
                savedImageIDs.append(imageID)
            } catch {
                saveError = error.localizedDescription
            }
            currentVariant += 1
            await generateNext()
        } else {
            saveError = vm.errorMessage ?? "No image returned"
            var done = job
            done.startedAt = startedAt
            done.completedAt = Date()
            done.savedImageIDs = savedImageIDs
            onJobCompleted?(done)
        }
    }
}
