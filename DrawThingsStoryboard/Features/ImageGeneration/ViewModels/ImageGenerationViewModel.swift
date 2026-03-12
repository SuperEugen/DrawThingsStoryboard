import SwiftUI
import Combine

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

    // MARK: - State
    @Published var isGenerating: Bool = false
    @Published var generatedImage: NSImage? = nil
    @Published var errorMessage: String? = nil

    // MARK: - Dependencies
    private let client: DrawThingsClientProtocol

    init(client: DrawThingsClientProtocol = DrawThingsHTTPClient()) {
        self.client = client
    }

    // MARK: - Actions

    func generate() async {
        guard !prompt.isEmpty else { return }
        isGenerating = true
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
            generatedImage = try await client.generateImage(request: request)
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }
}
