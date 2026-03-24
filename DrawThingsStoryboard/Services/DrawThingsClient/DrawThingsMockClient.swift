import AppKit
import DrawThingsClient

/// Mock client for SwiftUI Previews and unit tests.
/// Returns a coloured placeholder – no real API call.
final class DrawThingsMockClient: DrawThingsClientProtocol {

    func generateImage(
        request: GenerationRequest,
        moodboardImages: [NSImage] = [],
        initImage: NSImage? = nil,
        onProgress: ((GenerationStage) -> Void)? = nil
    ) async throws -> NSImage {
        // Simulate generation stages for UI testing
        let stages: [GenerationStage] = [
            .textEncoding, .sampling(step: 5), .sampling(step: 10),
            .sampling(step: 15), .sampling(step: 20), .imageDecoding
        ]
        for stage in stages {
            onProgress?(stage)
            try await Task.sleep(for: .milliseconds(200))
        }
        // Return a placeholder tinted by moodboard presence
        let color: NSColor = moodboardImages.isEmpty
            ? NSColor.systemIndigo.withAlphaComponent(0.4)
            : NSColor.systemTeal.withAlphaComponent(0.4)
        return NSImage(size: NSSize(width: 512, height: 512), flipped: false) { rect in
            color.setFill()
            rect.fill()
            return true
        }
    }
}
