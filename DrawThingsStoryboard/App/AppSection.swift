import Foundation

/// Which level of the briefing hierarchy the user is currently editing.
enum BriefingLevel: String, Hashable {
    case studio
    case customer
    case episode

    var label: String {
        switch self {
        case .studio:   return "Studio"
        case .customer: return "Customer"
        case .episode:  return "Episode"
        }
    }

    var icon: String {
        switch self {
        case .studio:   return "building.columns"
        case .customer: return "person.text.rectangle"
        case .episode:  return "film"
        }
    }
}

/// Top-level navigation sections shown in the sidebar.
enum AppSection: String, CaseIterable, Identifiable, Hashable {

    case projects
    case assets
    case looks
    case storyboard
    case productionQueue
    case configuration

    var id: String { rawValue }

    var title: String {
        switch self {
        case .projects:        return "Projects"
        case .assets:          return "Assets"
        case .looks:           return "Looks"
        case .storyboard:      return "Storyboard"
        case .productionQueue: return "Production Queue"
        case .configuration:   return "Configuration"
        }
    }

    var icon: String {
        switch self {
        case .projects:        return "folder"
        case .assets:          return "photo.stack"
        case .looks:           return "paintpalette"
        case .storyboard:      return "pencil.and.list.clipboard"
        case .productionQueue: return "film.stack"
        case .configuration:   return "gearshape"
        }
    }
}
