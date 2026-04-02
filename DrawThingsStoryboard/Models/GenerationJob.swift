import SwiftUI

// MARK: - Generation job types

enum GenerationJobType: String, CaseIterable, Identifiable {
    case generateAsset   = "Generate Asset"
    case generateStyle   = "Generate Style"
    case generatePanel   = "Generate Panel"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .generateAsset: return "photo"
        case .generateStyle: return "eye"
        case .generatePanel: return "rectangle.and.pencil.and.ellipsis"
        }
    }
    var color: Color {
        switch self {
        case .generateAsset: return .blue
        case .generateStyle: return .purple
        case .generatePanel: return .orange
        }
    }
    var letter: String {
        switch self {
        case .generateAsset: return "A"
        case .generateStyle: return "S"
        case .generatePanel: return "P"
        }
    }
}

enum GenerationSize: String, CaseIterable, Identifiable {
    case small = "Small"
    case large = "Large"
    var id: String { rawValue }
    var letter: String {
        switch self {
        case .small: return "S"
        case .large: return "L"
        }
    }
}

// MARK: - Generation job

struct GenerationJob: Identifiable, Equatable {
    let id: String
    let itemName: String
    let jobType: GenerationJobType
    let size: GenerationSize
    let styleName: String
    let queuedAt: Date
    let estimatedDuration: TimeInterval
    let itemIcon: String
    let seed: Int
    let width: Int
    let height: Int
    let combinedPrompt: String
    var variantCount: Int = 0
    var assetType: String = ""
    var assetSubType: String = ""
    /// The styleID this job belongs to (for style example generation).
    var styleID: String = ""
    /// The assetID this job belongs to (for asset generation).
    var assetID: String = ""
    /// The panelID this job belongs to (for panel generation).
    var panelID: String = ""
    /// Filled after generation: the saved image UUID(s).
    var savedImageIDs: [String] = []
    var startedAt: Date? = nil
    var completedAt: Date? = nil
}
