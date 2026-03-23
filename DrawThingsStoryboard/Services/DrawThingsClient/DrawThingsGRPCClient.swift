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

    /// - Parameters:
    ///   - address: host:port of the Draw Things gRPC server
    ///   - useTLS: must match the TLS setting in Draw Things (default: true)
    init(address: String = "localhost:7859", useTLS: Bool = true) throws {
        self.dtClient = try DrawThingsClient(address: address, useTLS: useTLS)
    }

    func generateImage(
        request: GenerationRequest,
        moodboardImages: [NSImage] = [],
        onProgress: ((GenerationStage) -> Void)? = nil
    ) async throws -> NSImage {

        // 1. Connect (echo handshake) — fetches model metadata from Draw Things
        await dtClient.connect()
        if let err = dtClient.lastError {
            throw DrawThingsGRPCError.connectionFailed(err.localizedDescription)
        }
        print("[GRPCClient] Connected. isConnected=\(dtClient.isConnected)")

        // 2. Progress polling task
        let progressTask: Task<Void, Never>? = onProgress.map { callback in
            Task { [weak dtClient] in
                while !Task.isCancelled {
                    if let stage = await dtClient?.currentProgress?.stage {
                        callback(stage)
                    }
                    try? await Task.sleep(for: .milliseconds(250))
                }
            }
        }
        defer { progressTask?.cancel() }

        // 3. Build moodboard hints
        let hints = buildHints(from: moodboardImages)

        // 4. Build configuration — tells Draw Things width/height/steps/guidance.
        //    We intentionally leave `model` empty so Draw Things uses whatever
        //    model is currently selected in its UI.
        let config = DrawThingsConfiguration(
            width: request.width,
            height: request.height,
            steps: request.steps,
            guidanceScale: Float(request.guidanceScale),
            seed: request.seed == -1 ? UInt32.random(in: 0 ..< UInt32.max) : UInt32(request.seed)
        )

        print("[GRPCClient] Sending — prompt: '\(request.prompt.prefix(60))…', \(request.width)×\(request.height), steps: \(request.steps), hints: \(hints.count)")

        // 5. Call gRPC
        let images = try await dtClient.generateImage(
            prompt: request.prompt,
            negativePrompt: request.negativePrompt,
            configuration: config,
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
