import Foundation

/// Top-level navigation sections shown in the sidebar.
/// #56: Reordered: Models, Styles, Assets, Storyboards, Production Queue, Settings
enum AppSection: String, CaseIterable, Identifiable, Hashable {

    case models
    case styles
    case assets
    case storyboard
    case productionQueue
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .models:          return "Models"
        case .styles:          return "Styles"
        case .assets:          return "Assets"
        case .storyboard:      return "Storyboards"
        case .productionQueue: return "Production Queue"
        case .settings:        return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .models:          return "gearshape"
        case .styles:          return "paintpalette"
        case .assets:          return "photo.stack"
        case .storyboard:      return "pencil.and.list.clipboard"
        case .productionQueue: return "film.stack"
        case .settings:        return "slider.horizontal.3"
        }
    }
}
