import AppKit
import DrawThingsClient

/// Abstraction over the Draw Things generation backend.
/// Conform to this protocol to swap between gRPC, HTTP and Mock clients.
protocol DrawThingsClientProtocol {
    /// Generate an image from a text prompt.
    /// - Parameters:
    ///   - request: Core generation parameters (prompt, steps, size, …)
    ///   - moodboardImages: Optional reference images passed as hints (shuffle ControlNet).
    ///   - onProgress: Optional closure called on each generation stage update.
    func generateImage(
        request: GenerationRequest,
        moodboardImages: [NSImage],
        onProgress: ((GenerationStage) -> Void)?
    ) async throws -> NSImage
}

/// Convenience overload – no moodboard, no progress callback.
extension DrawThingsClientProtocol {
    func generateImage(request: GenerationRequest) async throws -> NSImage {
        try await generateImage(request: request, moodboardImages: [], onProgress: nil)
    }
}
