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

/// Top-level navigation sections — one per production phase plus library access.
enum AppSection: String, CaseIterable, Identifiable, Hashable {

    // Production phases
    case briefing
    case casting
    case writing
    case production

    // Library management
    case library

    var id: String { rawValue }

    var title: String {
        switch self {
        case .briefing:   return "Briefing"
        case .casting:    return "Cast & Locations"
        case .writing:    return "Storyboard"
        case .production: return "Production"
        case .library:    return "Library"
        }
    }

    var icon: String {
        switch self {
        case .briefing:   return "doc.text"
        case .casting:    return "person.2"
        case .writing:    return "pencil.and.list.clipboard"
        case .production: return "film.stack"
        case .library:    return "photo.stack"
        }
    }
}
