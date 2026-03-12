import Foundation

/// Response from POST /sdapi/v1/txt2img
struct GenerationResponse: Decodable {
    /// Base64-encoded PNG images
    let images: [String]
}
