import Foundation

/// Top-level navigation sections shown in the sidebar.
enum AppSection: String, CaseIterable, Identifiable, Hashable {

    case assets
    case styles
    case models
    case storyboard
    case productionQueue
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .assets:          return "Assets"
        case .styles:          return "Styles"
        case .models:          return "Models"
        case .storyboard:      return "Storyboards"
        case .productionQueue: return "Production Queue"
        case .settings:        return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .assets:          return "photo.stack"
        case .styles:          return "paintpalette"
        case .models:          return "gearshape"
        case .storyboard:      return "pencil.and.list.clipboard"
        case .productionQueue: return "film.stack"
        case .settings:        return "slider.horizontal.3"
        }
    }
}
