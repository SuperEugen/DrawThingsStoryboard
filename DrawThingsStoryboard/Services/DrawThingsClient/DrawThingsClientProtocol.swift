import AppKit
import DrawThingsClient

/// Abstraction over the Draw Things generation backend.
protocol DrawThingsClientProtocol {
    /// Generate an image from a text prompt.
    /// - Parameters:
    ///   - request: Core generation parameters (prompt, steps, size, …)
    ///   - moodboardImages: Up to 3 reference images passed as shuffle hints.
    ///   - initImage: Optional canvas image (img2img / 4th asset).
    ///   - onProgress: Optional closure called on each generation stage update.
    func generateImage(
        request: GenerationRequest,
        moodboardImages: [NSImage],
        initImage: NSImage?,
        onProgress: ((GenerationStage) -> Void)?
    ) async throws -> NSImage
}

/// Convenience overloads.
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
