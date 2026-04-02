import AppKit
import DrawThingsClient

/// Production client that talks to Draw Things via gRPC.
/// Supports prompt-based generation AND moodboard reference images (shuffle hints).
///
/// Draw Things must be running with:
/// Advanced → API Server → Protocol: gRPC, Port: 7859, TLS: on
@MainActor
final class DrawThingsGRPCClient: DrawThingsClientProtocol {

    private let dtClient: DrawThingsClient

    init(address: String = "localhost:7859", useTLS: Bool = true) throws {
        self.dtClient = try DrawThingsClient(address: address, useTLS: useTLS)
    }

    func generateImage(
        request: GenerationRequest,
        moodboardImages: [NSImage] = [],
        initImage: NSImage? = nil,
        onProgress: ((GenerationStage) -> Void)? = nil
    ) async throws -> NSImage {

        await dtClient.connect()
        if let err = dtClient.lastError {
            throw DrawThingsGRPCError.connectionFailed(err.localizedDescription)
        }
        print("[GRPCClient] Connected. isConnected=\(dtClient.isConnected)")

        let progressTask: Task<Void, Never>? = onProgress.map { callback in
            Task { [weak dtClient] in
                while !Task.isCancelled {
                    if let stage = dtClient?.currentProgress?.stage {
                        callback(stage)
                    }
                    try? await Task.sleep(for: .milliseconds(250))
                }
            }
        }
        defer { progressTask?.cancel() }

        let hints = buildHints(from: moodboardImages)

        let seedValue: Int64? = request.seed == -1 ? nil : Int64(request.seed)
        let config = DrawThingsConfiguration(
            width: Int32(request.width),
            height: Int32(request.height),
            steps: Int32(request.steps),
            model: request.model,
            guidanceScale: Float(request.guidanceScale),
            seed: seedValue
        )

        // Convert initImage to NSImage for the gRPC call
        let canvasImage: NSImage? = initImage

        print("[GRPCClient] Sending — prompt: '\(request.prompt.prefix(60))…', \(request.width)×\(request.height), steps: \(request.steps), hints: \(hints.count), initImage: \(canvasImage != nil)")

        let images = try await dtClient.generateImage(
            prompt: request.prompt,
            negativePrompt: request.negativePrompt,
            configuration: config,
            image: canvasImage,
            hints: hints
        )

        print("[GRPCClient] Received \(images.count) image(s)")

        guard let first = images.first else {
            throw DrawThingsGRPCError.noImageReturned
        }
        return first
    }

    // MARK: - Private helpers

    private func buildHints(from nsImages: [NSImage]) -> [HintProto] {
        guard !nsImages.isEmpty else { return [] }
        let builder = HintBuilder()
        for image in nsImages {
            guard let tiff = image.tiffRepresentation,
                  let bmp  = NSBitmapImageRep(data: tiff),
                  let png  = bmp.representation(using: .png, properties: [:]) else { continue }
            builder.addMoodboardImage(png)
        }
        return builder.build()
    }
}

enum DrawThingsGRPCError: LocalizedError {
    case connectionFailed(String)
    case noImageReturned

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let msg):
            return "Draw Things gRPC connection failed: \(msg)"
        case .noImageReturned:
            return "Draw Things returned no image. Is the gRPC API enabled on port 7859?"
        }
    }
}
