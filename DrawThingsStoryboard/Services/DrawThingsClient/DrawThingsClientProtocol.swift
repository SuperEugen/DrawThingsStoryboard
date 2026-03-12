import AppKit

/// Abstraction over the Draw Things HTTP API.
/// Mock this in previews and tests.
protocol DrawThingsClientProtocol {
    func generateImage(request: GenerationRequest) async throws -> NSImage
}
