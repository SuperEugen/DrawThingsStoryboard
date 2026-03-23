import SwiftUI

// MARK: - Enums

/// One of 4 variant slots for a CastingItem.
struct Variant: Identifiable, Equatable {
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
        && lhs.variantsAvailable == rhs.variantsAvailable
        && lhs.smallImageAvailable == rhs.smallImageAvailable
        && lhs.largeImageAvailable == rhs.largeImageAvailable
        && lhs.libraryLevel == rhs.libraryLevel
        && lhs.variants == rhs.variants
    }

    let id: String
    var name: String
    var description: String
    var type: CastingItemType
    var gender: CharacterGender? = nil           // only for characters
    var locationSetting: LocationSetting? = nil  // only for locations
    var variantsAvailable: Bool = false
    var smallImageAvailable: Bool = false
    var largeImageAvailable: Bool = false
    var libraryLevel: LibraryLevel
    /// Always exactly 4 variant slots.
    var variants: [Variant]
    /// Default items cannot be deleted from the library.
    var isDefault: Bool = false
    /// Generated file name (read-only display, schema TBD).
    var fileName: String = ""

    /// Deep equality check comparing user-editable metadata fields (not variant state).
    /// Used for dirty-tracking in the asset editor.
    func contentEquals(_ other: CastingItem) -> Bool {
        name == other.name
        && description == other.description
        && type == other.type
        && gender == other.gender
        && locationSetting == other.locationSetting
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
    var preferredLookID: String? = nil
    var episodes: [MockEpisode]
    var characters: [CastingItem] = []   // customer-level shared characters
    var locations: [CastingItem] = []    // customer-level shared locations

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
    var preferredLookID: String? = nil
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
    case generateExample = "Generate Example"
    case generateAsset   = "Generate Asset"
    case generatePanel   = "Generate Panel"

    var id: String { rawValue }

    /// Single-letter abbreviation for list rows.
    var letter: String {
        switch self {
        case .generateExample: return "E"
        case .generateAsset:   return "A"
        case .generatePanel:   return "P"
        }
    }

    var icon: String {
        switch self {
        case .generateExample: return "eye"
        case .generateAsset:   return "photo.badge.checkmark"
        case .generatePanel:   return "photo"
        }
    }

    var color: Color {
        switch self {
        case .generateExample: return .purple
        case .generateAsset:   return .blue
        case .generatePanel:   return .orange
        }
    }
}

/// Size of a generation job.
enum GenerationSize: String, CaseIterable, Identifiable {
    case small = "Small"
    case large = "Large"

    var id: String { rawValue }

    /// Single-letter abbreviation for list rows.
    var letter: String {
        switch self {
        case .small: return "S"
        case .large: return "L"
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
    var itemType: CastingItemType
    var averageDuration: Int              // seconds (variant generation)
    var averageDurationLargeImage: Int = 180  // seconds (large image generation)
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
    /// Small or Large.
    let size: GenerationSize
    let lookName: String
    let queuedAt: Date
    let estimatedDuration: TimeInterval   // seconds
    /// Icon for the source item (gender/location-specific)
    let itemIcon: String
    /// Gender for character items (used by thumbnail).
    var itemGender: CharacterGender? = nil
    /// Setting for location items (used by thumbnail).
    var itemLocationSetting: LocationSetting? = nil
    /// Random seed for generation reproducibility (-1 = random).
    let seed: Int64
    /// Pixel width derived from job type + configuration.
    let width: Int
    /// Pixel height derived from job type + configuration.
    let height: Int
    /// Combined prompt assembled from studio rules, customer rules, episode rules,
    /// look description, and item description.
    let combinedPrompt: String
    /// Number of variants to generate (1–4, for variant/asset jobs only).
    var variantCount: Int = 0
    /// Attached assets summary (for panel jobs only).
    var attachedAssets: [JobAssetInfo] = []
}

/// Lightweight summary of an attached asset for display in production queue.
struct JobAssetInfo: Identifiable {
    let id: String
    let name: String
    let type: CastingItemType
    let icon: String
    /// Gender for character assets (used by thumbnail).
    var gender: CharacterGender? = nil
    /// Setting for location assets (used by thumbnail).
    var locationSetting: LocationSetting? = nil
}

// MARK: - Size configuration keys (stored via @AppStorage)

enum SizeConfigKeys {
    static let previewVariantWidth  = "dts.previewVariantWidth"
    static let previewVariantHeight = "dts.previewVariantHeight"
    static let finalWidth           = "dts.finalWidth"
    static let finalHeight          = "dts.finalHeight"
}

enum SizeConfigDefaults {
    static let previewVariantWidth  = 576
    static let previewVariantHeight = 320
    static let finalWidth           = 1920
    static let finalHeight          = 1080
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
        libraryLevel: .episode,
        variants: CastingItem.emptyVariants(prefix: "default-city"),
        isDefault: true
    )

    // MARK: Casting phase (flat lists for center pane)

    static let castingCharacters: [CastingItem] = [
        CastingItem(id: "ch-01", name: "Alex",   description: "The hero. Determined, mid-30s, athletic build.", type: .character, gender: .male,   variantsAvailable: true, smallImageAvailable: true, largeImageAvailable: true, libraryLevel: .customer, variants: CastingItem.mockVariants(prefix: "ch-01", generated: 4, approved: 2)),
        CastingItem(id: "ch-02", name: "Sam",    description: "The sidekick. Cheerful, early 20s.",             type: .character, gender: .female, variantsAvailable: true, libraryLevel: .episode,  variants: CastingItem.mockVariants(prefix: "ch-02", generated: 4, approved: nil)),
        CastingItem(id: "ch-03", name: "Jordan", description: "The antagonist. Cold, late 40s, sharp eyes.",    type: .character, gender: .other,  libraryLevel: .episode,  variants: CastingItem.emptyVariants(prefix: "ch-03")),
    ]

    static let castingLocations: [CastingItem] = [
        CastingItem(id: "lo-01", name: "Rooftop",     description: "Urban rooftop, night skyline, neon reflections.", type: .location, locationSetting: .exterior, variantsAvailable: true, smallImageAvailable: true, largeImageAvailable: true, libraryLevel: .studio,   variants: CastingItem.mockVariants(prefix: "lo-01", generated: 4, approved: 1)),
        CastingItem(id: "lo-02", name: "Office",      description: "Corporate open-plan office, daytime.",             type: .location, locationSetting: .interior, libraryLevel: .episode,  variants: CastingItem.emptyVariants(prefix: "lo-02")),
        CastingItem(id: "lo-03", name: "Underground", description: "Subway station, flickering lights.",               type: .location, locationSetting: .interior, variantsAvailable: true, libraryLevel: .customer, variants: CastingItem.mockVariants(prefix: "lo-03", generated: 4, approved: nil)),
    ]

    // MARK: Library tree — initial studios list

    static let defaultStudios: [MockStudio] = [
        MockStudio(
            id: "studio_pixelforge",
            name: "PixelForge Studios",
            rules: "cinematic lighting, photorealistic, 8k resolution, dramatic shadows",
            preferredLookID: "tpl-01",
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
                                CastingItem(id: "gm-p-ch-01", name: "Alex",   description: "The hero. Determined, mid-30s.", type: .character, gender: .male,   variantsAvailable: true, smallImageAvailable: true, largeImageAvailable: true, libraryLevel: .episode, variants: CastingItem.mockVariants(prefix: "gm-p-ch-01", generated: 4, approved: 2)),
                                CastingItem(id: "gm-p-ch-02", name: "Sam",    description: "Cheerful sidekick, early 20s.", type: .character, gender: .female, variantsAvailable: true, libraryLevel: .episode, variants: CastingItem.mockVariants(prefix: "gm-p-ch-02", generated: 4, approved: nil)),
                            ],
                            locations: [
                                CastingItem(id: "gm-p-lo-01", name: "Office", description: "Corporate open-plan office.", type: .location, locationSetting: .interior, libraryLevel: .episode, variants: CastingItem.emptyVariants(prefix: "gm-p-lo-01")),
                            ],
                            acts: MockData.sampleActs
                        ),
                        MockEpisode(
                            id: "ep_gm_chase",
                            name: "The Chase",
                            characters: [
                                CastingItem(id: "gm-c-ch-01", name: "Jordan", description: "The antagonist, late 40s.", type: .character, gender: .other, libraryLevel: .episode, variants: CastingItem.emptyVariants(prefix: "gm-c-ch-01")),
                            ],
                            locations: [
                                CastingItem(id: "gm-c-lo-01", name: "Rooftop", description: "Urban rooftop, neon night.", type: .location, locationSetting: .exterior, variantsAvailable: true, libraryLevel: .episode, variants: CastingItem.mockVariants(prefix: "gm-c-lo-01", generated: 4, approved: nil)),
                            ]
                        ),
                        MockEpisode(
                            id: "ep_gm_finale",
                            name: "The Finale",
                            characters: [],
                            locations: []
                        ),
                    ],
                    characters: [
                        CastingItem(id: "gm-ch-01", name: "Detective Rose", description: "Recurring detective across all Global Media episodes.", type: .character, gender: .female, variantsAvailable: true, smallImageAvailable: true, libraryLevel: .customer, variants: CastingItem.mockVariants(prefix: "gm-ch-01", generated: 4, approved: 1)),
                        CastingItem(id: "gm-ch-02", name: "Mr. Black", description: "Mysterious informant, appears in shadows.", type: .character, gender: .male, variantsAvailable: true, libraryLevel: .customer, variants: CastingItem.mockVariants(prefix: "gm-ch-02", generated: 4, approved: nil)),
                    ],
                    locations: [
                        CastingItem(id: "gm-lo-01", name: "Police HQ", description: "Brutalist police headquarters, exterior.", type: .location, locationSetting: .exterior, variantsAvailable: true, smallImageAvailable: true, largeImageAvailable: true, libraryLevel: .customer, variants: CastingItem.mockVariants(prefix: "gm-lo-01", generated: 4, approved: 2)),
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
                                CastingItem(id: "nv-o-ch-01", name: "Lyra", description: "Nova's protagonist.", type: .character, gender: .female, variantsAvailable: true, smallImageAvailable: true, libraryLevel: .episode, variants: CastingItem.mockVariants(prefix: "nv-o-ch-01", generated: 4, approved: 0)),
                            ],
                            locations: [
                                CastingItem(id: "nv-o-lo-01", name: "Lab", description: "High-tech research lab.", type: .location, locationSetting: .interior, libraryLevel: .episode, variants: CastingItem.emptyVariants(prefix: "nv-o-lo-01")),
                            ]
                        ),
                        MockEpisode(
                            id: "ep_nv_breach",
                            name: "The Breach",
                            characters: [
                                CastingItem(id: "nv-b-ch-01", name: "Rex", description: "Security chief.", type: .character, gender: .male, libraryLevel: .episode, variants: CastingItem.emptyVariants(prefix: "nv-b-ch-01")),
                            ],
                            locations: [
                                CastingItem(id: "nv-b-lo-01", name: "Server Room", description: "Dim blue light, racks.", type: .location, locationSetting: .interior, libraryLevel: .episode, variants: CastingItem.emptyVariants(prefix: "nv-b-lo-01")),
                            ]
                        ),
                    ]
                ),
            ],
            characters: [
                CastingItem(id: "pf-ch-01", name: "Narrator", description: "Neutral voice-over character.", type: .character, gender: .other, variantsAvailable: true, smallImageAvailable: true, largeImageAvailable: true, libraryLevel: .studio, variants: CastingItem.mockVariants(prefix: "pf-ch-01", generated: 4, approved: 0)),
            ],
            locations: [
                CastingItem(id: "pf-lo-01", name: "Black Void", description: "Pure black infinite background.", type: .location, locationSetting: .interior, variantsAvailable: true, smallImageAvailable: true, largeImageAvailable: true, libraryLevel: .studio, variants: CastingItem.mockVariants(prefix: "pf-lo-01", generated: 4, approved: 1)),
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
                                CastingItem(id: "sm-d-ch-01", name: "Kai", description: "Young explorer.", type: .character, gender: .male, libraryLevel: .episode, variants: CastingItem.emptyVariants(prefix: "sm-d-ch-01")),
                            ],
                            locations: [
                                CastingItem(id: "sm-d-lo-01", name: "Mountain Pass", description: "Snowy alpine trail.", type: .location, locationSetting: .exterior, libraryLevel: .episode, variants: CastingItem.emptyVariants(prefix: "sm-d-lo-01")),
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
            itemType: .character,
            averageDuration: 180,
            generationModel: "SDXL 1.0",
            generationSteps: 50
        ),
        GenerationTemplate(
            id: "tpl-03",
            name: "Location Establishing",
            description: "Wide establishing shot, atmospheric mood, high detail.",
            itemType: .location,
            averageDuration: 360,
            generationModel: "SDXL 1.0",
            generationSteps: 30
        ),
        GenerationTemplate(
            id: "tpl-04",
            name: "Location Final",
            description: "Final hi-res location render from approved variant.",
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
            jobType: .generateAsset, size: .small, lookName: "Standard Character",
            queuedAt: Date().addingTimeInterval(-120),
            estimatedDuration: 300, itemIcon: "figure.stand",
            itemGender: .male,
            seed: 42,
            width: SizeConfigDefaults.previewVariantWidth,
            height: SizeConfigDefaults.previewVariantHeight,
            combinedPrompt: "cinematic lighting, photorealistic, 8k resolution, dramatic shadows, corporate thriller aesthetic, muted color palette, urban environments, night scenes, noir atmosphere, rain-soaked streets, Full-body character portrait, neutral background, consistent lighting., The hero. Determined, mid-30s.",
            variantCount: 4
        ),
        GenerationJob(
            id: "job-02", itemName: "Rooftop", itemType: .location,
            jobType: .generateAsset, size: .large, lookName: "Location Final",
            queuedAt: Date().addingTimeInterval(-60),
            estimatedDuration: 180, itemIcon: "mountain.2",
            itemLocationSetting: .exterior,
            seed: 1337,
            width: SizeConfigDefaults.finalWidth,
            height: SizeConfigDefaults.finalHeight,
            combinedPrompt: "cinematic lighting, photorealistic, 8k resolution, dramatic shadows, corporate thriller aesthetic, muted color palette, urban environments, night scenes, noir atmosphere, rain-soaked streets, Final hi-res location render from approved variant., Urban rooftop, night skyline, neon reflections."
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
