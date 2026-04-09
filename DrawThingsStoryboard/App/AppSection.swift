import Foundation

/// Top-level navigation sections shown in the sidebar.
/// #56: SF Symbols 7 icons
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
        case .models:          return "camera"
        case .styles:          return "paintpalette"
        case .assets:          return "person.crop.square.on.square.angled"
        case .storyboard:      return "film.stack"
        case .productionQueue: return "square.and.arrow.down.on.square"
        case .settings:        return "slider.horizontal.3"
        }
    }
}
