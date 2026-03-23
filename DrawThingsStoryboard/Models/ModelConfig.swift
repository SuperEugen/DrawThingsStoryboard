import Foundation

/// A Draw Things model configuration.
/// Describes which AI model to use and its core generation parameters.
struct ModelConfig: Identifiable {
    let id: String
    var name: String
    var model: String       // filename as it appears in Draw Things, e.g. "sd_xl_base_1.0.safetensors"
    var steps: Int
    var guidanceScale: Double
}

// MARK: - Mock data

extension ModelConfig {
    static let defaultConfigs: [ModelConfig] = [
        ModelConfig(
            id: "mc-1",
            name: "SDXL Standard",
            model: "sd_xl_base_1.0.safetensors",
            steps: 20,
            guidanceScale: 7.0
        ),
        ModelConfig(
            id: "mc-2",
            name: "Flux Schnell",
            model: "flux_1_schnell_q5p.ckpt",
            steps: 4,
            guidanceScale: 1.0
        ),
    ]
}
