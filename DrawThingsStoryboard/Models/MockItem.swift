import SwiftUI

// MARK: - Enums

/// Generation lifecycle of a Cast / Location / Panel item.
enum GenerationStatus: String, CaseIterable, Identifiable {
    case nothingGenerated   = "nothing-generated"
    case variantsGenerated  = "variants-generated"
    case variantApproved    = "variant-approved"
    case finalGenerated     = "final-generated"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .nothingGenerated:  return "Nothing generated"
        case .variantsGenerated: return "Variants generated"
        case .variantApproved:   return "Variant approved"
        case .finalGenerated:    return "Final generated"
        }
    }

    var color: Color {
        switch self {
        case .nothingGenerated:  return .gray
        case .variantsGenerated: return .orange
        case .variantApproved:   return .blue
        case .finalGenerated:    return .green
        }
    }
}

/// One of 4 variant slots for a CastingItem.
struct Variant: Identifiable {
    let id: String
    var isGenerated: Bool       // true = has image data, false = empty placeholder
    var isApproved: Bool        // at most one variant can be approved per item
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

/// Gender for cast members.
enum CharacterGender: String, CaseIterable {
    case male
    case female
    case other

    var icon: String {
        switch self {
        case .male:   return "figure.stand"
        case .female: return "figure.stand.dress"
        case .other:  return "cat"
        }
    }

    var label: String {
        switch self {
        case .male:   return "Male"
        case .female: return "Female"
        case .other:  return "Other"
        }
    }
}

/// Interior / Exterior for locations.
enum LocationSetting: String, CaseIterable {
    case interior
    case exterior

    var icon: String {
        switch self {
        case .interior: return "door.left.hand.open"
        case .exterior: return "mountain.2"
        }
    }

    var label: String {
        switch self {
        case .interior: return "Interior"
        case .exterior: return "Exterior"
        }
    }
}

// MARK: - Casting item

struct CastingItem: Identifiable {
    let id: String
    var name: String
    var description: String
    var type: CastingItemType
    var gender: CharacterGender? = nil           // only for characters
    var locationSetting: LocationSetting? = nil  // only for locations
    var status: GenerationStatus
    var libraryLevel: LibraryLevel
    /// Always exactly 4 variant slots.
    var variants: [Variant]

    /// Convenience: number of generated (non-empty) variants.
    var generatedCount: Int { variants.filter(\.isGenerated).count }
    /// Index of the approved variant, if any.
    var approvedIndex: Int? { variants.firstIndex(where: { $0.isApproved }) }

    /// Creates 4 default empty variant slots.
    static func emptyVariants(prefix: String) -> [Variant] {
        (0..<4).map { Variant(id: "\(prefix)-v\($0)", isGenerated: false, isApproved: false) }
    }

    /// Creates 4 variant slots with the given number generated and optional approved index.
    static func mockVariants(prefix: String, generated: Int, approved: Int?) -> [Variant] {
        (0..<4).map { i in
            Variant(
                id: "\(prefix)-v\(i)",
                isGenerated: i < generated,
                isApproved: approved == i
            )
        }
    }
}

// MARK: - Library tree structs
// Property order must match memberwise init order used in MockData below.

struct MockEpisode: Identifiable, Hashable {
    let id: String
    var name: String
    var rules: String = ""
    var characters: [CastingItem]
    var locations: [CastingItem]

    static func == (lhs: MockEpisode, rhs: MockEpisode) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct MockCustomer: Identifiable, Hashable {
    let id: String
    var name: String
    var rules: String = ""
    var episodes: [MockEpisode]

    static func == (lhs: MockCustomer, rhs: MockCustomer) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// NOTE: property order here defines the memberwise init order.
/// customers comes before characters/locations so the init reads naturally.
struct MockStudio: Identifiable, Hashable {
    let id: String
    var name: String
    var rules: String = ""
    var customers: [MockCustomer]
    var characters: [CastingItem]   // studio-level shared characters
    var locations: [CastingItem]    // studio-level shared locations

    static func == (lhs: MockStudio, rhs: MockStudio) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
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
        CastingItem(id: "ch-01", name: "Alex",   description: "The hero. Determined, mid-30s, athletic build.", type: .character, gender: .male,   status: .finalGenerated,    libraryLevel: .customer, variants: CastingItem.mockVariants(prefix: "ch-01", generated: 4, approved: 2)),
        CastingItem(id: "ch-02", name: "Sam",    description: "The sidekick. Cheerful, early 20s.",             type: .character, gender: .female, status: .variantsGenerated, libraryLevel: .episode,  variants: CastingItem.mockVariants(prefix: "ch-02", generated: 4, approved: nil)),
        CastingItem(id: "ch-03", name: "Jordan", description: "The antagonist. Cold, late 40s, sharp eyes.",    type: .character, gender: .other,  status: .nothingGenerated,  libraryLevel: .episode,  variants: CastingItem.emptyVariants(prefix: "ch-03")),
    ]

    static let castingLocations: [CastingItem] = [
        CastingItem(id: "lo-01", name: "Rooftop",     description: "Urban rooftop, night skyline, neon reflections.", type: .location, locationSetting: .exterior, status: .finalGenerated,    libraryLevel: .studio,   variants: CastingItem.mockVariants(prefix: "lo-01", generated: 4, approved: 1)),
        CastingItem(id: "lo-02", name: "Office",      description: "Corporate open-plan office, daytime.",             type: .location, locationSetting: .interior, status: .nothingGenerated,  libraryLevel: .episode,  variants: CastingItem.emptyVariants(prefix: "lo-02")),
        CastingItem(id: "lo-03", name: "Underground", description: "Subway station, flickering lights.",               type: .location, locationSetting: .interior, status: .variantsGenerated, libraryLevel: .customer, variants: CastingItem.mockVariants(prefix: "lo-03", generated: 4, approved: nil)),
    ]

    // MARK: Library tree — initial studios list

    static let defaultStudios: [MockStudio] = [
        MockStudio(
            id: "studio_pixelforge",
            name: "PixelForge Studios",
            rules: "cinematic lighting, photorealistic, 8k resolution, dramatic shadows",
            customers: [
                MockCustomer(
                    id: "cust_globalmedia",
                    name: "Global Media Corp",
                    rules: "corporate thriller aesthetic, muted color palette, urban environments",
                    episodes: [
                        MockEpisode(
                            id: "ep_gm_pilot",
                            name: "The Pilot",
                            rules: "night scenes, noir atmosphere, rain-soaked streets",
                            characters: [
                                CastingItem(id: "gm-p-ch-01", name: "Alex",   description: "The hero. Determined, mid-30s.", type: .character, gender: .male,   status: .finalGenerated,    libraryLevel: .episode, variants: CastingItem.mockVariants(prefix: "gm-p-ch-01", generated: 4, approved: 2)),
                                CastingItem(id: "gm-p-ch-02", name: "Sam",    description: "Cheerful sidekick, early 20s.", type: .character, gender: .female, status: .variantsGenerated, libraryLevel: .episode, variants: CastingItem.mockVariants(prefix: "gm-p-ch-02", generated: 4, approved: nil)),
                            ],
                            locations: [
                                CastingItem(id: "gm-p-lo-01", name: "Office", description: "Corporate open-plan office.", type: .location, locationSetting: .interior, status: .nothingGenerated, libraryLevel: .episode, variants: CastingItem.emptyVariants(prefix: "gm-p-lo-01")),
                            ]
                        ),
                        MockEpisode(
                            id: "ep_gm_chase",
                            name: "The Chase",
                            characters: [
                                CastingItem(id: "gm-c-ch-01", name: "Jordan", description: "The antagonist, late 40s.", type: .character, gender: .other, status: .nothingGenerated, libraryLevel: .episode, variants: CastingItem.emptyVariants(prefix: "gm-c-ch-01")),
                            ],
                            locations: [
                                CastingItem(id: "gm-c-lo-01", name: "Rooftop", description: "Urban rooftop, neon night.", type: .location, locationSetting: .exterior, status: .variantsGenerated, libraryLevel: .episode, variants: CastingItem.mockVariants(prefix: "gm-c-lo-01", generated: 4, approved: nil)),
                            ]
                        ),
                        MockEpisode(
                            id: "ep_gm_finale",
                            name: "The Finale",
                            characters: [],
                            locations: []
                        ),
                    ]
                ),
                MockCustomer(
                    id: "cust_novaent",
                    name: "Nova Entertainment",
                    episodes: [
                        MockEpisode(
                            id: "ep_nv_origins",
                            name: "Origins",
                            characters: [
                                CastingItem(id: "nv-o-ch-01", name: "Lyra", description: "Nova's protagonist.", type: .character, gender: .female, status: .variantApproved, libraryLevel: .episode, variants: CastingItem.mockVariants(prefix: "nv-o-ch-01", generated: 4, approved: 0)),
                            ],
                            locations: [
                                CastingItem(id: "nv-o-lo-01", name: "Lab", description: "High-tech research lab.", type: .location, locationSetting: .interior, status: .nothingGenerated, libraryLevel: .episode, variants: CastingItem.emptyVariants(prefix: "nv-o-lo-01")),
                            ]
                        ),
                        MockEpisode(
                            id: "ep_nv_breach",
                            name: "The Breach",
                            characters: [
                                CastingItem(id: "nv-b-ch-01", name: "Rex", description: "Security chief.", type: .character, gender: .male, status: .nothingGenerated, libraryLevel: .episode, variants: CastingItem.emptyVariants(prefix: "nv-b-ch-01")),
                            ],
                            locations: [
                                CastingItem(id: "nv-b-lo-01", name: "Server Room", description: "Dim blue light, racks.", type: .location, locationSetting: .interior, status: .nothingGenerated, libraryLevel: .episode, variants: CastingItem.emptyVariants(prefix: "nv-b-lo-01")),
                            ]
                        ),
                    ]
                ),
            ],
            characters: [
                CastingItem(id: "pf-ch-01", name: "Narrator", description: "Neutral voice-over character.", type: .character, gender: .other, status: .finalGenerated, libraryLevel: .studio, variants: CastingItem.mockVariants(prefix: "pf-ch-01", generated: 4, approved: 0)),
            ],
            locations: [
                CastingItem(id: "pf-lo-01", name: "Black Void", description: "Pure black infinite background.", type: .location, locationSetting: .interior, status: .finalGenerated, libraryLevel: .studio, variants: CastingItem.mockVariants(prefix: "pf-lo-01", generated: 4, approved: 1)),
            ]
        ),
        MockStudio(
            id: "studio_dreamworks",
            name: "Dreamline Animation",
            customers: [
                MockCustomer(
                    id: "cust_sunrisemedia",
                    name: "Sunrise Media",
                    episodes: [
                        MockEpisode(
                            id: "ep_sm_dawn",
                            name: "Dawn",
                            characters: [
                                CastingItem(id: "sm-d-ch-01", name: "Kai", description: "Young explorer.", type: .character, gender: .male, status: .nothingGenerated, libraryLevel: .episode, variants: CastingItem.emptyVariants(prefix: "sm-d-ch-01")),
                            ],
                            locations: [
                                CastingItem(id: "sm-d-lo-01", name: "Mountain Pass", description: "Snowy alpine trail.", type: .location, locationSetting: .exterior, status: .nothingGenerated, libraryLevel: .episode, variants: CastingItem.emptyVariants(prefix: "sm-d-lo-01")),
                            ]
                        ),
                    ]
                ),
            ],
            characters: [],
            locations: []
        ),
    ]

    /// Legacy accessor for library tree — returns first studio for backward compat.
    static let libraryTree: MockStudio = defaultStudios[0]

    // MARK: Other phases

    static func items(for section: AppSection?) -> [MockItem] {
        switch section {
        case .briefing:
            return []   // Briefing has its own dedicated browser
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
