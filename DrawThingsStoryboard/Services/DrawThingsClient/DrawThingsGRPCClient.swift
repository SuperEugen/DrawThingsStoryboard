import AppKit
import DrawThingsClient

/// Production client that talks to Draw Things via gRPC.
/// Supports prompt-based generation AND moodboard reference images (shuffle hints).
/// #57: Passes sampler as SamplerType enum to DrawThingsConfiguration
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

        // #57: Resolve sampler string to SamplerType enum
        let resolvedSampler = Self.samplerType(from: request.sampler)

        let config = DrawThingsConfiguration(
            width: Int32(request.width),
            height: Int32(request.height),
            steps: Int32(request.steps),
            model: request.model,
            sampler: resolvedSampler,
            guidanceScale: Float(request.guidanceScale),
            seed: seedValue
        )

        let canvasImage: NSImage? = initImage

        print("[GRPCClient] Sending \u{2014} prompt: '\(request.prompt.prefix(60))\u{2026}', model: '\(request.model)', sampler: \(resolvedSampler) ('\(request.sampler)'), \(request.width)\u{00d7}\(request.height), steps: \(request.steps), cfg: \(request.guidanceScale), hints: \(hints.count), initImage: \(canvasImage != nil)")

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

    // MARK: - Sampler mapping

    /// Maps a human-readable sampler name (e.g. "UniPC Trailing") to a SamplerType enum case.
    /// Falls back to .dpmpp2mkarras if not recognized.
    static func samplerType(from name: String) -> SamplerType {
        let lookup: [String: SamplerType] = [
            "DPM++ 2M Karras":      .dpmpp2mkarras,
            "Euler a":              .eulera,
            "DDIM":                 .ddim,
            "PLMS":                 .plms,
            "DPM++ SDE Karras":     .dpmppsdekarras,
            "UniPC":                .unipc,
            "LCM":                  .lcm,
            "Euler a Substep":      .eulerasubstep,
            "DPM++ SDE Substep":    .dpmppsdesubstep,
            "TCD":                  .tcd,
            "Euler a Trailing":     .euleratrailing,
            "DPM++ SDE Trailing":   .dpmppsdetrailing,
            "DPM++ 2M AYS":        .dpmpp2mays,
            "Euler a AYS":          .euleraays,
            "DPM++ SDE AYS":       .dpmppsdeays,
            "DPM++ 2M Trailing":   .dpmpp2mtrailing,
            "DDIM Trailing":        .ddimtrailing,
            "UniPC Trailing":       .unipctrailing,
            "UniPC AYS":            .unipcays,
            "TCD Trailing":         .tcdtrailing,
        ]
        if let match = lookup[name] {
            return match
        }
        // Case-insensitive fallback
        let lower = name.lowercased()
        for (key, value) in lookup {
            if key.lowercased() == lower { return value }
        }
        print("[GRPCClient] Unknown sampler '\(name)', falling back to dpmpp2mkarras")
        return .dpmpp2mkarras
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
