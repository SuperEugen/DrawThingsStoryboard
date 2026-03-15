import Foundation

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
        case .casting:    return "Casting"
        case .writing:    return "Writing"
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
