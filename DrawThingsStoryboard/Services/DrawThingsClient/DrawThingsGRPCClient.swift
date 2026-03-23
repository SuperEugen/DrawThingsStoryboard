import AppKit
import Combine
import DrawThingsClient

/// Production client that talks to Draw Things via gRPC.
/// Supports prompt-based generation AND moodboard reference images (shuffle hints).
///
/// Draw Things must be running with the gRPC API enabled:
/// Advanced → API Server → Protocol: gRPC, Port: 7860
final class DrawThingsGRPCClient: DrawThingsClientProtocol {

    private let client: DrawThingsClient
    private var cancellables = Set<AnyCancellable>()

    /// - Parameter address: host:port of the Draw Things gRPC server, e.g. "localhost:7860"
    init(address: String = "localhost:7860") throws {
        self.client = try DrawThingsClient(address: address, useTLS: false)
    }

    func generateImage(
        request: GenerationRequest,
        moodboardImages: [NSImage] = [],
        onProgress: ((GenerationStage) -> Void)? = nil
    ) async throws -> NSImage {

        // Build hints from moodboard images (shuffle = reference image ControlNet)
        let hints: [HintProto] = moodboardImages.isEmpty ? [] : {
            let builder = HintBuilder()
            for image in moodboardImages {
                guard let tiff = image.tiffRepresentation,
                      let bmp  = NSBitmapImageRep(data: tiff),
                      let png  = bmp.representation(using: .png, properties: [:]) else { continue }
                builder.addMoodboardImage(png)
            }
            return builder.build()
        }()

        // Wire up progress forwarding via Combine
        if let callback = onProgress {
            client.$currentProgress
                .compactMap { $0?.stage }
                .sink { callback($0) }
                .store(in: &cancellables)
        }

        let images = try await client.generateImage(
            prompt: request.prompt,
            negativePrompt: request.negativePrompt,
            hints: hints
        )

        cancellables.removeAll()

        guard let first = images.first else {
            throw DrawThingsGRPCError.noImageReturned
        }
        return first
    }
}

enum DrawThingsGRPCError: LocalizedError {
    case noImageReturned

    var errorDescription: String? {
        switch self {
        case .noImageReturned:
            return "Draw Things returned no image. Is the gRPC API enabled on port 7860?"
        }
    }
}
