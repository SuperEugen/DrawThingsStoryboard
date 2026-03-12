import Foundation

/// Request payload for POST /sdapi/v1/txt2img
struct GenerationRequest: Encodable {
    let prompt: String
    let negativePrompt: String
    let steps: Int
    let guidanceScale: Double
    let seed: Int
    let width: Int
    let height: Int
    let batchSize: Int

    enum CodingKeys: String, CodingKey {
        case prompt
        case negativePrompt  = "negative_prompt"
        case steps
        case guidanceScale   = "cfg_scale"
        case seed
        case width
        case height
        case batchSize       = "batch_size"
    }

    init(
        prompt: String,
        negativePrompt: String = "",
        steps: Int = 20,
        guidanceScale: Double = 7.5,
        seed: Int = -1,
        width: Int = 512,
        height: Int = 512,
        batchSize: Int = 1
    ) {
        self.prompt = prompt
        self.negativePrompt = negativePrompt
        self.steps = steps
        self.guidanceScale = guidanceScale
        self.seed = seed
        self.width = width
        self.height = height
        self.batchSize = batchSize
    }
}
