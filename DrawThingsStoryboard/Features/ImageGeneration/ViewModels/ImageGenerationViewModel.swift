import SwiftUI
import Combine
import DrawThingsClient

/// ViewModel for the Image Generation feature.
@MainActor
final class ImageGenerationViewModel: ObservableObject {

    // MARK: - Prompt
    @Published var prompt: String = ""
    @Published var negativePrompt: String = ""

    // MARK: - Parameters
    @Published var steps: Int = 20
    @Published var guidanceScale: Double = 7.5
    @Published var seed: Int = 0
    @Published var width: Int = 512
    @Published var height: Int = 512
    @Published var model: String = ""

    // MARK: - Moodboard + canvas
    @Published var moodboardImages: [NSImage] = []
    @Published var initImage: NSImage? = nil

    // MARK: - State
    @Published var isGenerating: Bool = false
    @Published var generationStage: String = ""
    @Published var generatedImage: NSImage? = nil
    @Published var errorMessage: String? = nil

    // MARK: - Dependencies
    private let client: DrawThingsClientProtocol

    init(client: DrawThingsClientProtocol? = nil) {
        if let client {
            self.client = client
        } else if let grpc = try? DrawThingsGRPCClient(address: "localhost:7859", useTLS: true) {
            self.client = grpc
        } else {
            self.client = DrawThingsHTTPClient()
        }
    }

    // MARK: - Actions

    func generate() async {
        guard !prompt.isEmpty else { return }
        isGenerating = true
        generationStage = ""
        errorMessage = nil
        generatedImage = nil

        // If seed is 0 (unassigned), generate a random one for Draw Things
        let effectiveSeed = SeedHelper.isUnassigned(seed) ? SeedHelper.randomSeed() : seed

        let request = GenerationRequest(
            prompt: prompt,
            negativePrompt: negativePrompt,
            steps: steps,
            guidanceScale: guidanceScale,
            seed: effectiveSeed,
            width: width,
            height: height,
            model: model
        )

        do {
            generatedImage = try await client.generateImage(
                request: request,
                moodboardImages: moodboardImages,
                initImage: initImage,
                onProgress: { [weak self] stage in
                    self?.generationStage = stage.description
                }
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
        generationStage = ""
    }
}
