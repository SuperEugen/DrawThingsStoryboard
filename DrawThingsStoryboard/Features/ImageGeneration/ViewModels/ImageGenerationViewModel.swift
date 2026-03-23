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
    @Published var seed: Int = -1

    // MARK: - Moodboard
    /// Reference images forwarded to Draw Things as shuffle hints.
    @Published var moodboardImages: [NSImage] = []

    // MARK: - State
    @Published var isGenerating: Bool = false
    @Published var generationStage: String = ""
    @Published var generatedImage: NSImage? = nil
    @Published var errorMessage: String? = nil

    // MARK: - Dependencies
    private let client: DrawThingsClientProtocol

    /// Default init: tries gRPC first, falls back to HTTP.
    /// Uses DrawThingsMockClient in SwiftUI Previews.
    init(client: DrawThingsClientProtocol? = nil) {
        if let client {
            self.client = client
        } else if let grpc = try? DrawThingsGRPCClient() {
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

        let request = GenerationRequest(
            prompt: prompt,
            negativePrompt: negativePrompt,
            steps: steps,
            guidanceScale: guidanceScale,
            seed: seed
        )

        do {
            generatedImage = try await client.generateImage(
                request: request,
                moodboardImages: moodboardImages,
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

    func addMoodboardImage(_ image: NSImage) {
        moodboardImages.append(image)
    }

    func removeMoodboardImage(at index: Int) {
        guard moodboardImages.indices.contains(index) else { return }
        moodboardImages.remove(at: index)
    }

    func clearMoodboard() {
        moodboardImages.removeAll()
    }
}
