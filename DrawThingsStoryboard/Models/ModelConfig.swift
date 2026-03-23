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
            name: "FLUX 2 klein KV",
            model: "flux_2_klein_9b_kv_q8p.ckpt",
            steps: 6,
            guidanceScale: 1.0
        )
    ]
}
