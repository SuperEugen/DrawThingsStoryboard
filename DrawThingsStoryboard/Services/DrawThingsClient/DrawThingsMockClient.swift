import AppKit

/// Mock client for SwiftUI Previews and unit tests.
/// Returns a coloured placeholder instead of calling the real API.
final class DrawThingsMockClient: DrawThingsClientProtocol {

    func generateImage(request: GenerationRequest) async throws -> NSImage {
        try await Task.sleep(for: .seconds(1))
        return NSImage(size: NSSize(width: 512, height: 512), flipped: false) { rect in
            NSColor.systemIndigo.withAlphaComponent(0.4).setFill()
            rect.fill()
            return true
        }
    }
}
