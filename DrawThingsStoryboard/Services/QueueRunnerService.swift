import SwiftUI
import Combine
import DrawThingsClient

/// Runs the production queue automatically, processing one job at a time.
/// Lives as a @StateObject in ContentView.
/// #57: Uses job.modelID instead of global selectedModelID for model lookup
/// #58: Publishes per-step progress for fine-grained progress bar
@MainActor
final class QueueRunnerService: ObservableObject {

    // MARK: - Published state
    @Published var isRunning: Bool = false
    @Published var currentJobID: String? = nil
    @Published var currentVariant: Int = 0
    @Published var totalVariants: Int = 1
    @Published var generationStage: String = ""
    @Published var generatedImages: [NSImage] = []
    @Published var errorMessage: String? = nil
    /// #58: Current step within the current variant (parsed from generationStage)
    @Published var currentStep: Int = 0
    /// #58: Steps per variant (from model config)
    @Published var stepsPerVariant: Int = 1

    // MARK: - Internal
    private var isBusy: Bool = false
    private var onJobCompleted: ((GenerationJob) -> Void)?

    func configure(onJobCompleted: @escaping (GenerationJob) -> Void) {
        self.onJobCompleted = onJobCompleted
    }

    func queueDidChange(
        queue: [GenerationJob],
        config: AppConfig,
        models: ModelsFile,
        selectedModelID: String?
    ) {
        guard !isBusy, let nextJob = queue.first else { return }
        isBusy = true
        isRunning = true
        Task {
            await processJob(
                nextJob,
                config: config,
                models: models,
                selectedModelID: selectedModelID
            )
        }
    }

    func stopQueue(queue: inout [GenerationJob]) {
        queue.removeAll { $0.id != currentJobID }
    }

    // MARK: - Process a single job

    private func processJob(
        _ job: GenerationJob,
        config: AppConfig,
        models: ModelsFile,
        selectedModelID: String?
    ) async {
        currentJobID = job.id
        generatedImages = []
        errorMessage = nil
        generationStage = ""
        currentStep = 0

        let count: Int
        if job.jobType == .generateAsset && job.size == .small {
            count = max(1, job.variantCount)
        } else {
            count = 1
        }
        totalVariants = count
        currentVariant = 0

        var savedImageIDs: [String] = []
        let startedAt = Date()

        let isPanelJob = job.jobType == .generatePanel
        var initImage: NSImage? = nil
        var moodboardImages: [NSImage] = []

        if isPanelJob {
            if !job.initImageID.isEmpty {
                initImage = StorageService.shared.loadImage(id: job.initImageID)
                if let img = initImage {
                    print("[QueueRunner] \u{2705} Loaded init image '\(job.initImageID)' (\(Int(img.size.width))x\(Int(img.size.height)))")
                } else {
                    print("[QueueRunner] \u{26a0}\u{fe0f} Init image '\(job.initImageID)' not found on disk!")
                }
            }
            if !job.moodboardImageIDs.isEmpty {
                for imgID in job.moodboardImageIDs {
                    if let img = StorageService.shared.loadImage(id: imgID) {
                        moodboardImages.append(img)
                        print("[QueueRunner] \u{2705} Loaded moodboard image '\(imgID)'")
                    } else {
                        print("[QueueRunner] \u{26a0}\u{fe0f} Moodboard image '\(imgID)' not found!")
                    }
                }
                print("[QueueRunner] Moodboard: \(moodboardImages.count)/\(job.moodboardImageIDs.count) images loaded")
            }
        }

        let model: ModelEntry? = {
            if !job.modelID.isEmpty {
                if let m = models.models.first(where: { $0.modelID == job.modelID }) { return m }
            }
            if let sid = selectedModelID {
                if let m = models.models.first(where: { $0.modelID == sid }) { return m }
            }
            return models.models.first
        }()

        // #58: Publish steps per variant from model config
        stepsPerVariant = model?.steps ?? 20

        print("[QueueRunner] Job '\(job.itemName)' \u{2014} type: \(job.jobType.rawValue), model: \(model?.name ?? "none") (\(job.modelID)), variants: \(count), stepsPerVariant: \(stepsPerVariant), initImage: \(initImage != nil), moodboard: \(moodboardImages.count)")

        for i in 0..<count {
            currentVariant = i
            currentStep = 0

            let vm = ImageGenerationViewModel()
            vm.prompt = job.combinedPrompt
            vm.width = job.width
            vm.height = job.height
            vm.grpcAddress = config.grpcAddress
            vm.grpcPort = config.grpcPort

            if let model {
                vm.steps = model.steps
                vm.guidanceScale = model.guidanceScale
                vm.model = model.model
                vm.sampler = model.sampler
            }

            if count > 1 {
                vm.seed = SeedHelper.randomSeed()
            } else {
                vm.seed = job.seed
            }

            if isPanelJob {
                vm.initImage = initImage
                vm.moodboardImages = moodboardImages
            }

            print("[QueueRunner] Generation #\(i) \u{2014} seed: \(vm.seed), model: \(vm.model), sampler: \(vm.sampler), steps: \(vm.steps), cfg: \(vm.guidanceScale)")

            // #58: Parse step number from generationStage string
            let cancellable = vm.$generationStage.sink { [weak self] stage in
                self?.generationStage = stage
                // Parse "Generating image (step N)..." or "Second pass generation (step N)..."
                if let range = stage.range(of: "step "), let self {
                    let afterStep = stage[range.upperBound...]
                    if let endParen = afterStep.firstIndex(of: ")") {
                        let stepStr = afterStep[..<endParen]
                        if let step = Int(stepStr) {
                            self.currentStep = step
                        }
                    }
                }
            }

            await vm.generate()
            cancellable.cancel()

            if let image = vm.generatedImage {
                generatedImages.append(image)
                do {
                    let imageID = try StorageService.shared.saveImage(image)
                    savedImageIDs.append(imageID)
                } catch {
                    errorMessage = error.localizedDescription
                }
            } else {
                errorMessage = vm.errorMessage ?? "No image returned"
                break
            }
        }

        var done = job
        done.startedAt = startedAt
        done.completedAt = Date()
        done.savedImageIDs = savedImageIDs
        onJobCompleted?(done)

        currentJobID = nil
        currentVariant = 0
        totalVariants = 1
        currentStep = 0
        stepsPerVariant = 1
        generationStage = ""
        generatedImages = []
        isBusy = false
        isRunning = false
    }
}
