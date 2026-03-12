import Foundation

/// All top-level navigation sections of the app.
/// Add a new case here when adding a new feature.
enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case imageGeneration

    var id: String { rawValue }

    var title: String {
        switch self {
        case .imageGeneration: return "Image Generation"
        }
    }

    var icon: String {
        switch self {
        case .imageGeneration: return "wand.and.sparkles"
        }
    }
}
