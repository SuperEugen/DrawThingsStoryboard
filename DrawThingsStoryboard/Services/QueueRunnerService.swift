import SwiftUI
import Combine
import DrawThingsClient

/// Runs the production queue automatically, processing one job at a time.
/// Lives as a @StateObject in ContentView.
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
    /// #50: Fresh random seeds per variant, canvas/moodboard only for panels

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

        // #50: Only load canvas/moodboard for panel generation
        let isPanelJob = job.jobType == .generatePanel
        var initImage: NSImage? = nil
        var moodboardImages: [NSImage] = []

        if isPanelJob {
            // #43: Load init image (e.g. location asset)
            if !job.initImageID.isEmpty {
                initImage = StorageService.shared.loadImage(id: job.initImageID)
                if let img = initImage {
                    print("[QueueRunner] \u{2705} Loaded init image '\(job.initImageID)' (\(Int(img.size.width))x\(Int(img.size.height)))")
                } else {
                    print("[QueueRunner] \u{26a0}\u{fe0f} Init image '\(job.initImageID)' not found on disk!")
                }
            }
            // #44: Load moodboard images (e.g. character assets)
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

        print("[QueueRunner] Job '\(job.itemName)' \u{2014} type: \(job.jobType.rawValue), variants: \(count), initImage: \(initImage != nil), moodboard: \(moodboardImages.count)")

        // Generate images sequentially
        for i in 0..<count {
            currentVariant = i

            // #50: Fresh VM per variant to avoid any accumulated state
            let vm = ImageGenerationViewModel()
            vm.prompt = job.combinedPrompt
            vm.width = job.width
            vm.height = job.height
            vm.grpcAddress = config.grpcAddress
            vm.grpcPort = config.grpcPort

            let model = models.models.first { $0.modelID == selectedModelID } ?? models.models.first
            if let model {
                vm.steps = model.steps
                vm.guidanceScale = model.guidanceScale
                vm.model = model.model
            }

            // #50: Always use fresh random seeds for multi-variant jobs
            // For single-image jobs (panels, large assets): use job seed or random
            if count > 1 {
                // Multi-variant: always completely random per variant
                vm.seed = SeedHelper.randomSeed()
            } else {
                // Single image: use job seed (0 = random in ViewModel)
                vm.seed = job.seed
            }

            // #50: Only set canvas/moodboard for panel jobs (clean slate for assets)
            if isPanelJob {
                vm.initImage = initImage
                vm.moodboardImages = moodboardImages
            }
            // For asset/style jobs: vm.initImage and vm.moodboardImages stay nil/empty

            print("[QueueRunner] Generation #\(i) \u{2014} seed: \(vm.seed), initImage: \(vm.initImage != nil), moodboard: \(vm.moodboardImages.count)")

            let cancellable = vm.$generationStage.sink { [weak self] stage in
                self?.generationStage = stage
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

        // Report completion
        var done = job
        done.startedAt = startedAt
        done.completedAt = Date()
        done.savedImageIDs = savedImageIDs
        onJobCompleted?(done)

        // Reset state
        currentJobID = nil
        currentVariant = 0
        totalVariants = 1
        generationStage = ""
        generatedImages = []
        isBusy = false
        isRunning = false
    }
}
