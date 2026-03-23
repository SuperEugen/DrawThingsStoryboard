import Foundation

/// Request payload for image generation.
/// model is used by the gRPC client; HTTP fields use CodingKeys.
struct GenerationRequest: Encodable {
    let prompt: String
    let negativePrompt: String
    let steps: Int
    let guidanceScale: Double
    let seed: Int
    let width: Int
    let height: Int
    let batchSize: Int
    /// Draw Things model filename, e.g. "flux_1_schnell_q5p.ckpt".
    /// Empty string = use whatever is currently loaded in Draw Things UI.
    let model: String

    enum CodingKeys: String, CodingKey {
        case prompt
        case negativePrompt  = "negative_prompt"
        case steps
        case guidanceScale   = "cfg_scale"
        case seed
        case width
        case height
        case batchSize       = "batch_size"
        // model is intentionally excluded from HTTP encoding
    }

    init(
        prompt: String,
        negativePrompt: String = "",
        steps: Int = 20,
        guidanceScale: Double = 7.5,
        seed: Int = -1,
        width: Int = 512,
        height: Int = 512,
        batchSize: Int = 1,
        model: String = ""
    ) {
        self.prompt = prompt
        self.negativePrompt = negativePrompt
        self.steps = steps
        self.guidanceScale = guidanceScale
        self.seed = seed
        self.width = width
        self.height = height
        self.batchSize = batchSize
        self.model = model
    }
}
