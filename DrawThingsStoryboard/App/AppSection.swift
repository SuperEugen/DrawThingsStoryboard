import Foundation

/// Top-level navigation sections shown in the sidebar.
enum AppSection: String, CaseIterable, Identifiable, Hashable {

    case storyboard
    case assets
    case styles
    case models
    case productionQueue
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .storyboard:      return "Storyboards"
        case .assets:          return "Assets"
        case .styles:          return "Styles"
        case .models:          return "Models"
        case .productionQueue: return "Production Queue"
        case .settings:        return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .storyboard:      return "pencil.and.list.clipboard"
        case .assets:          return "photo.stack"
        case .styles:          return "paintpalette"
        case .models:          return "gearshape"
        case .productionQueue: return "film.stack"
        case .settings:        return "slider.horizontal.3"
        }
    }
}
