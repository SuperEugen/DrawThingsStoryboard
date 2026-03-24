import AppKit
import DrawThingsClient

/// Fallback HTTP client for the Draw Things REST API.
/// Does NOT support moodboard/hints – use DrawThingsGRPCClient for full feature set.
///
/// Draw Things must be running with:
/// Advanced → API Server → Protocol: HTTP, Port: 7859
final class DrawThingsHTTPClient: DrawThingsClientProtocol {

    private let baseURL: URL

    init(baseURL: URL = URL(string: "http://localhost:7859")!) {
        self.baseURL = baseURL
    }

    func generateImage(
        request: GenerationRequest,
        moodboardImages: [NSImage] = [],
        initImage: NSImage? = nil,
        onProgress: ((GenerationStage) -> Void)? = nil
    ) async throws -> NSImage {
        // Note: moodboardImages, initImage and onProgress are not supported by the HTTP API.
        // Switch to DrawThingsGRPCClient to use reference images.
        let endpoint = baseURL.appendingPathComponent("/sdapi/v1/txt2img")
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw DrawThingsError.serverError
        }

        let result = try JSONDecoder().decode(GenerationResponse.self, from: data)

        guard let base64 = result.images.first,
              let imageData = Data(base64Encoded: base64),
              let image = NSImage(data: imageData) else {
            throw DrawThingsError.invalidImageData
        }

        return image
    }
}

enum DrawThingsError: LocalizedError {
    case serverError
    case invalidImageData

    var errorDescription: String? {
        switch self {
        case .serverError:
            return "Draw Things returned an error. Is it running with HTTP API enabled?"
        case .invalidImageData:
            return "Could not decode the generated image."
        }
    }
}
