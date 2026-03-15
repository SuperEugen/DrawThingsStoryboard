import SwiftUI

// MARK: - Enums

/// Generation lifecycle of an asset.
enum GenerationStatus: String, CaseIterable, Identifiable {
    case notYetGenerated  = "not-yet-generated"
    case previewGenerated = "preview-generated"
    case finalGenerated   = "final-generated"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .notYetGenerated:  return "Not yet generated"
        case .previewGenerated: return "Preview generated"
        case .finalGenerated:   return "Final generated"
        }
    }

    var color: Color {
        switch self {
        case .notYetGenerated:  return .gray
        case .previewGenerated: return .orange
        case .finalGenerated:   return .green
        }
    }
}

/// Where in the library hierarchy an asset lives.
enum LibraryLevel: String, CaseIterable, Identifiable {
    case studio   = "Studio"
    case customer = "Customer"
    case episode  = "Episode"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .studio:   return "Shared across all customers"
        case .customer: return "Shared within customer"
        case .episode:  return "This episode only"
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

/// Discriminates between the two casting sub-types.
enum CastingItemType {
    case character
    case location
}

// MARK: - Casting item

struct CastingItem: Identifiable {
    let id: String
    var name: String
    var description: String
    var type: CastingItemType
    var status: GenerationStatus
    var libraryLevel: LibraryLevel
    var variantCount: Int
    var approvedVariant: Int?
}

// MARK: - Library tree structs
// Property order must match memberwise init order used in MockData below.

struct MockEpisode: Identifiable {
    let id: String
    let name: String
    var characters: [CastingItem]
    var locations: [CastingItem]
}

struct MockCustomer: Identifiable {
    let id: String
    let name: String
    var episodes: [MockEpisode]
}

/// NOTE: property order here defines the memberwise init order.
/// customers comes before characters/locations so the init reads naturally.
struct MockStudio: Identifiable {
    let id: String
    let name: String
    var customers: [MockCustomer]
    var characters: [CastingItem]   // studio-level shared characters
    var locations: [CastingItem]    // studio-level shared locations
}

// MARK: - Generic browser item (non-casting phases)

struct MockItem: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let status: String
    let variantCount: Int
}

// MARK: - Mock data factory

enum MockData {

    // MARK: Casting phase (flat lists for center pane)

    static let castingCharacters: [CastingItem] = [
        CastingItem(id: "ch-01", name: "Alex",   description: "The hero. Determined, mid-30s, athletic build.", type: .character, status: .finalGenerated,   libraryLevel: .customer, variantCount: 3, approvedVariant: 2),
        CastingItem(id: "ch-02", name: "Sam",    description: "The sidekick. Cheerful, early 20s.",             type: .character, status: .previewGenerated, libraryLevel: .episode,  variantCount: 2, approvedVariant: nil),
        CastingItem(id: "ch-03", name: "Jordan", description: "The antagonist. Cold, late 40s, sharp eyes.",    type: .character, status: .notYetGenerated,  libraryLevel: .episode,  variantCount: 0, approvedVariant: nil),
    ]

    static let castingLocations: [CastingItem] = [
        CastingItem(id: "lo-01", name: "Rooftop",     description: "Urban rooftop, night skyline, neon reflections.", type: .location, status: .finalGenerated,   libraryLevel: .studio,   variantCount: 4, approvedVariant: 1),
        CastingItem(id: "lo-02", name: "Office",      description: "Corporate open-plan office, daytime.",             type: .location, status: .notYetGenerated,  libraryLevel: .episode,  variantCount: 0, approvedVariant: nil),
        CastingItem(id: "lo-03", name: "Underground", description: "Subway station, flickering lights.",               type: .location, status: .previewGenerated, libraryLevel: .customer, variantCount: 2, approvedVariant: nil),
    ]

    // MARK: Library tree (customers first — matches MockStudio memberwise init)

    static let libraryTree = MockStudio(
        id: "studio_main",
        name: "studio_main",
        customers: [
            MockCustomer(
                id: "customer_acme",
                name: "customer_acme",
                episodes: [
                    MockEpisode(
                        id: "episode_acme_01",
                        name: "episode_acme_01",
                        characters: [
                            CastingItem(id: "ac-e1-ch-01", name: "Alex",   description: "Hero for Acme episode 1.", type: .character, status: .finalGenerated,   libraryLevel: .episode, variantCount: 3, approvedVariant: 2),
                            CastingItem(id: "ac-e1-ch-02", name: "Sam",    description: "Sidekick.",                type: .character, status: .previewGenerated, libraryLevel: .episode, variantCount: 2, approvedVariant: nil),
                        ],
                        locations: [
                            CastingItem(id: "ac-e1-lo-01", name: "Office", description: "Acme HQ daytime.",         type: .location,  status: .notYetGenerated,  libraryLevel: .episode, variantCount: 0, approvedVariant: nil),
                        ]
                    ),
                    MockEpisode(
                        id: "episode_acme_02",
                        name: "episode_acme_02",
                        characters: [
                            CastingItem(id: "ac-e2-ch-01", name: "Jordan", description: "Villain returns.",         type: .character, status: .notYetGenerated,  libraryLevel: .episode, variantCount: 0, approvedVariant: nil),
                        ],
                        locations: [
                            CastingItem(id: "ac-e2-lo-01", name: "Rooftop", description: "Acme rooftop finale.",    type: .location,  status: .previewGenerated, libraryLevel: .episode, variantCount: 2, approvedVariant: nil),
                        ]
                    ),
                ]
            ),
            MockCustomer(
                id: "customer_nova",
                name: "customer_nova",
                episodes: [
                    MockEpisode(
                        id: "episode_nova_01",
                        name: "episode_nova_01",
                        characters: [
                            CastingItem(id: "nv-e1-ch-01", name: "Lyra", description: "Nova's protagonist.",        type: .character, status: .previewGenerated, libraryLevel: .episode, variantCount: 1, approvedVariant: nil),
                        ],
                        locations: [
                            CastingItem(id: "nv-e1-lo-01", name: "Lab",  description: "High-tech research lab.",    type: .location,  status: .notYetGenerated,  libraryLevel: .episode, variantCount: 0, approvedVariant: nil),
                        ]
                    ),
                    MockEpisode(
                        id: "episode_nova_02",
                        name: "episode_nova_02",
                        characters: [
                            CastingItem(id: "nv-e2-ch-01", name: "Rex",  description: "Nova security chief.",       type: .character, status: .notYetGenerated,  libraryLevel: .episode, variantCount: 0, approvedVariant: nil),
                        ],
                        locations: [
                            CastingItem(id: "nv-e2-lo-01", name: "Server Room", description: "Dim blue light, racks.", type: .location, status: .notYetGenerated, libraryLevel: .episode, variantCount: 0, approvedVariant: nil),
                        ]
                    ),
                    MockEpisode(
                        id: "episode_nova_03",
                        name: "episode_nova_03",
                        characters: [
                            CastingItem(id: "nv-e3-ch-01", name: "Echo", description: "AI companion character.",    type: .character, status: .notYetGenerated,  libraryLevel: .episode, variantCount: 0, approvedVariant: nil),
                        ],
                        locations: [
                            CastingItem(id: "nv-e3-lo-01", name: "Void Station", description: "Derelict space station.", type: .location, status: .notYetGenerated, libraryLevel: .episode, variantCount: 0, approvedVariant: nil),
                        ]
                    ),
                ]
            ),
        ],
        characters: [
            CastingItem(id: "s-ch-01", name: "Narrator",   description: "Neutral, voice-over character.",  type: .character, status: .finalGenerated, libraryLevel: .studio, variantCount: 1, approvedVariant: 1),
        ],
        locations: [
            CastingItem(id: "s-lo-01", name: "Black Void", description: "Pure black infinite background.", type: .location,  status: .finalGenerated, libraryLevel: .studio, variantCount: 1, approvedVariant: 1),
        ]
    )

    // MARK: Other phases

    static func items(for section: AppSection?) -> [MockItem] {
        switch section {
        case .briefing:
            return [
                MockItem(id: "b-01", name: "Studio Config",     icon: "gearshape",           color: .indigo, status: "Draft", variantCount: 1),
                MockItem(id: "b-02", name: "Episode Config",    icon: "doc.badge.gearshape", color: .indigo, status: "Draft", variantCount: 1),
            ]
        case .writing:
            return [
                MockItem(id: "w-01", name: "Act 1 — Setup",      icon: "doc.text", color: .green, status: "Draft", variantCount: 1),
                MockItem(id: "w-02", name: "Act 2 — Conflict",   icon: "doc.text", color: .green, status: "Draft", variantCount: 1),
                MockItem(id: "w-03", name: "Act 3 — Resolution", icon: "doc.text", color: .green, status: "Draft", variantCount: 1),
            ]
        case .production:
            return [
                MockItem(id: "p-01", name: "Seq 01 — Sc 01", icon: "photo", color: .yellow, status: "Draft",    variantCount: 2),
                MockItem(id: "p-02", name: "Seq 01 — Sc 02", icon: "photo", color: .yellow, status: "Approved", variantCount: 1),
                MockItem(id: "p-03", name: "Seq 01 — Sc 03", icon: "photo", color: .yellow, status: "Draft",    variantCount: 3),
                MockItem(id: "p-04", name: "Seq 02 — Sc 01", icon: "photo", color: .orange, status: "Draft",    variantCount: 1),
            ]
        default:
            return []
        }
    }
}
