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

struct CastingItem: Identifiable, Equatable {
    static func == (lhs: CastingItem, rhs: CastingItem) -> Bool {
        lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.description == rhs.description
        && lhs.gender == rhs.gender
        && lhs.locationSetting == rhs.locationSetting
        && lhs.status == rhs.status
        && lhs.libraryLevel == rhs.libraryLevel
    }

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
    /// Default items cannot be deleted from the library.
    var isDefault: Bool = false

    /// Deep equality check comparing all editable fields (not just ID).
    /// Used for dirty-tracking in the asset editor.
    func contentEquals(_ other: CastingItem) -> Bool {
        name == other.name
        && description == other.description
        && type == other.type
        && gender == other.gender
        && locationSetting == other.locationSetting
        && status == other.status
        && libraryLevel == other.libraryLevel
    }

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
    var preferredLookID: String? = nil
    var characters: [CastingItem]
    var locations: [CastingItem]
    var acts: [MockAct] = []

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

// MARK: - Generation queue models

/// What kind of generation job is this?
enum GenerationJobType: String, CaseIterable, Identifiable {
    case generateVariants = "Generate Variants"
    case generateFinal    = "Generate Final"
    case generateExample  = "Generate Example"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .generateVariants: return "square.grid.2x2"
        case .generateFinal:    return "checkmark.seal"
        case .generateExample:  return "eye"
        }
    }

    var color: Color {
        switch self {
        case .generateVariants: return .orange
        case .generateFinal:    return .green
        case .generateExample:  return .purple
        }
    }
}

/// Status of a Look / template example image.
enum LookStatus: String, CaseIterable, Identifiable {
    case noExample       = "No example available"
    case exampleAvailable = "Example available"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .noExample:        return .gray
        case .exampleAvailable: return .green
        }
    }
}

/// A generation template defines settings for image generation.
struct GenerationTemplate: Identifiable {
    let id: String
    var name: String
    var description: String
    var jobType: GenerationJobType
    var itemType: CastingItemType
    var averageDuration: Int              // seconds
    var generationModel: String
    var generationSteps: Int
    var lookStatus: LookStatus = .noExample
}

/// A job in the generation queue.
struct GenerationJob: Identifiable {
    let id: String
    let itemName: String
    let itemType: CastingItemType
    let jobType: GenerationJobType
    let lookName: String
    let queuedAt: Date
    let estimatedDuration: TimeInterval   // seconds
    /// Icon for the source item (gender/location-specific)
    let itemIcon: String
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

    // MARK: Default items (always present, cannot be deleted)

    static let defaultHero = CastingItem(
        id: "default-hero",
        name: "Hero",
        description: "Default hero character placeholder.",
        type: .character,
        gender: .male,
        status: .nothingGenerated,
        libraryLevel: .episode,
        variants: CastingItem.emptyVariants(prefix: "default-hero"),
        isDefault: true
    )

    static let defaultCity = CastingItem(
        id: "default-city",
        name: "City",
        description: "Default city location placeholder.",
        type: .location,
        locationSetting: .exterior,
        status: .nothingGenerated,
        libraryLevel: .episode,
        variants: CastingItem.emptyVariants(prefix: "default-city"),
        isDefault: true
    )

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
                            preferredLookID: "tpl-01",
                            characters: [
                                CastingItem(id: "gm-p-ch-01", name: "Alex",   description: "The hero. Determined, mid-30s.", type: .character, gender: .male,   status: .finalGenerated,    libraryLevel: .episode, variants: CastingItem.mockVariants(prefix: "gm-p-ch-01", generated: 4, approved: 2)),
                                CastingItem(id: "gm-p-ch-02", name: "Sam",    description: "Cheerful sidekick, early 20s.", type: .character, gender: .female, status: .variantsGenerated, libraryLevel: .episode, variants: CastingItem.mockVariants(prefix: "gm-p-ch-02", generated: 4, approved: nil)),
                            ],
                            locations: [
                                CastingItem(id: "gm-p-lo-01", name: "Office", description: "Corporate open-plan office.", type: .location, locationSetting: .interior, status: .nothingGenerated, libraryLevel: .episode, variants: CastingItem.emptyVariants(prefix: "gm-p-lo-01")),
                            ],
                            acts: MockData.sampleActs
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

    // MARK: Generation templates

    static let defaultTemplates: [GenerationTemplate] = [
        GenerationTemplate(
            id: "tpl-01",
            name: "Standard Character",
            description: "Full-body character portrait, neutral background, consistent lighting.",
            jobType: .generateVariants,
            itemType: .character,
            averageDuration: 300,
            generationModel: "SDXL 1.0",
            generationSteps: 30,
            lookStatus: .exampleAvailable
        ),
        GenerationTemplate(
            id: "tpl-02",
            name: "Character Final",
            description: "High-resolution final render from approved variant.",
            jobType: .generateFinal,
            itemType: .character,
            averageDuration: 180,
            generationModel: "SDXL 1.0",
            generationSteps: 50
        ),
        GenerationTemplate(
            id: "tpl-03",
            name: "Location Establishing",
            description: "Wide establishing shot, atmospheric mood, high detail.",
            jobType: .generateVariants,
            itemType: .location,
            averageDuration: 360,
            generationModel: "SDXL 1.0",
            generationSteps: 30
        ),
        GenerationTemplate(
            id: "tpl-04",
            name: "Location Final",
            description: "Final hi-res location render from approved variant.",
            jobType: .generateFinal,
            itemType: .location,
            averageDuration: 240,
            generationModel: "SDXL 1.0",
            generationSteps: 50
        ),
    ]

    // MARK: Mock generation queue

    static let sampleQueue: [GenerationJob] = [
        GenerationJob(
            id: "job-01", itemName: "Alex", itemType: .character,
            jobType: .generateVariants, lookName: "Standard Character",
            queuedAt: Date().addingTimeInterval(-120),
            estimatedDuration: 300, itemIcon: "figure.stand"
        ),
        GenerationJob(
            id: "job-02", itemName: "Rooftop", itemType: .location,
            jobType: .generateFinal, lookName: "Location Final",
            queuedAt: Date().addingTimeInterval(-60),
            estimatedDuration: 180, itemIcon: "mountain.2"
        ),
    ]

    // MARK: Other phases

    static func items(for section: AppSection?) -> [MockItem] {
        switch section {
        case .projects:
            return []   // Projects has its own dedicated browser
        case .storyboard:
            return []   // Storyboard has its own dedicated browser
        default:
            return []
        }
    }
}
