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

        // 1. Connect first (echo) – ensures model metadata is available
        await dtClient.connect()
        if let err = dtClient.lastError {
            throw DrawThingsGRPCError.connectionFailed(err.localizedDescription)
        }
        print("[GRPCClient] Connected. isConnected=\(dtClient.isConnected)")

        // 2. Forward progress updates from the @Published property
        var progressTask: Task<Void, Never>? = nil
        if let callback = onProgress {
            progressTask = Task { [weak dtClient] in
                guard let dtClient else { return }
                // Poll currentProgress while generating
                while !Task.isCancelled {
                    if let stage = dtClient.currentProgress?.stage {
                        callback(stage)
                    }
                    try? await Task.sleep(for: .milliseconds(250))
                }
            }
        }
        defer { progressTask?.cancel() }

        // 3. Build moodboard hints
        let hints: [HintProto] = buildHints(from: moodboardImages)
        print("[GRPCClient] Sending request — prompt: '\(request.prompt.prefix(60))…', hints: \(hints.count)")

        // 4. Call gRPC
        let images = try await dtClient.generateImage(
            prompt: request.prompt,
            negativePrompt: request.negativePrompt,
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
