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

    // MARK: - Connection (from AppConfig)
    @Published var grpcAddress: String = "localhost"
    @Published var grpcPort: Int = 7859

    // MARK: - Moodboard + canvas
    @Published var moodboardImages: [NSImage] = []
    @Published var initImage: NSImage? = nil

    // MARK: - State
    @Published var isGenerating: Bool = false
    @Published var generationStage: String = ""
    @Published var generatedImage: NSImage? = nil
    @Published var errorMessage: String? = nil

    // MARK: - Client (lazy, recreated when address/port changes)
    private var client: DrawThingsClientProtocol?
    private var lastAddress: String = ""
    private var lastPort: Int = 0

    /// Returns a gRPC client, creating a new one if address/port changed.
    private func getClient() -> DrawThingsClientProtocol {
        let addr = "\(grpcAddress):\(grpcPort)"
        if client != nil && lastAddress == grpcAddress && lastPort == grpcPort {
            return client!
        }
        lastAddress = grpcAddress
        lastPort = grpcPort
        if let grpc = try? DrawThingsGRPCClient(address: addr, useTLS: true) {
            client = grpc
            return grpc
        }
        let http = DrawThingsHTTPClient()
        client = http
        return http
    }

    // MARK: - Actions

    func generate() async {
        guard !prompt.isEmpty else { return }
        isGenerating = true
        generationStage = ""
        errorMessage = nil
        generatedImage = nil

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

        let activeClient = getClient()

        do {
            generatedImage = try await activeClient.generateImage(
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
