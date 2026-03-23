import Foundation

/// A Draw Things model configuration.
/// Describes which AI model to use and its core generation parameters.
/// Named DTModelConfig to avoid collision with SwiftData's ModelConfiguration.
struct DTModelConfig: Identifiable {
    let id: String
    var name: String
    var model: String       // filename as it appears in Draw Things, e.g. "flux_1_schnell_q5p.ckpt"
    var steps: Int
    var guidanceScale: Double
}

// MARK: - Mock data

extension DTModelConfig {
    static let defaultConfigs: [DTModelConfig] = [
        DTModelConfig(
            id: "mc-1",
            name: "SDXL Standard",
            model: "sd_xl_base_1.0.safetensors",
            steps: 20,
            guidanceScale: 7.0
        ),
        DTModelConfig(
            id: "mc-2",
            name: "Flux Schnell",
            model: "flux_1_schnell_q5p.ckpt",
            steps: 4,
            guidanceScale: 1.0
        ),
    ]
}
