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
    /// Synchronous flag to prevent re-entry — set immediately, not after await.
    private var isBusy: Bool = false
    private var onJobCompleted: ((GenerationJob) -> Void)?

    /// Call once from ContentView to wire up the completion handler.
    func configure(onJobCompleted: @escaping (GenerationJob) -> Void) {
        self.onJobCompleted = onJobCompleted
    }

    /// Called whenever the queue changes. Starts processing if idle.
    func queueDidChange(
        queue: [GenerationJob],
        config: AppConfig,
        models: ModelsFile,
        selectedModelID: String?
    ) {
        // Synchronous guard — prevents any re-entry
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

    /// Stop: clear all waiting jobs from the queue (called from UI).
    /// Returns IDs of jobs that should be removed (everything except the running one).
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

        // Fresh VM per job to avoid any accumulated state
        let vm = ImageGenerationViewModel()
        vm.prompt = job.combinedPrompt
        vm.seed = job.seed
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

        // #43: Load init image (e.g. location asset) if specified
        if !job.initImageID.isEmpty {
            vm.initImage = StorageService.shared.loadImage(id: job.initImageID)
            if vm.initImage != nil {
                print("[QueueRunner] Loaded init image '\(job.initImageID)' for job '\(job.itemName)'")
            } else {
                print("[QueueRunner] Warning: init image '\(job.initImageID)' not found on disk")
            }
        }

        // Determine how many images to generate
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

        // Generate images sequentially
        for i in 0..<count {
            currentVariant = i
            vm.seed = job.seed == 0 ? SeedHelper.randomSeed() : job.seed + i

            // Observe stage changes
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
