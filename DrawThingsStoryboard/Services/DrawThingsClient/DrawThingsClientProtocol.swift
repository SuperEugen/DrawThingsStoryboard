import AppKit
import DrawThingsClient

/// Abstraction over the Draw Things generation backend.
protocol DrawThingsClientProtocol {
    func generateImage(
        request: GenerationRequest,
        moodboardImages: [NSImage],
        initImage: NSImage?,
        onProgress: ((GenerationStage) -> Void)?
    ) async throws -> NSImage
}

extension DrawThingsClientProtocol {
    func generateImage(request: GenerationRequest) async throws -> NSImage {
        try await generateImage(request: request, moodboardImages: [], initImage: nil, onProgress: nil)
    }
    func generateImage(
        request: GenerationRequest,
        moodboardImages: [NSImage],
        onProgress: ((GenerationStage) -> Void)?
    ) async throws -> NSImage {
        try await generateImage(request: request, moodboardImages: moodboardImages, initImage: nil, onProgress: onProgress)
    }
}
