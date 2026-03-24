import SwiftUI

// MARK: - Casting item types

enum CastingItemType: String, CaseIterable, Identifiable, Equatable {
    case character
    case location
    var id: String { rawValue }
}

enum CharacterGender: String, CaseIterable, Identifiable, Hashable, Equatable {
    case male
    case female
    case nonBinary = "non-binary"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .male:      return "Male"
        case .female:    return "Female"
        case .nonBinary: return "Non-binary"
        }
    }
    var icon: String {
        switch self {
        case .male:      return "person.fill"
        case .female:    return "person.fill"
        case .nonBinary: return "person.fill"
        }
    }
}

enum LocationSetting: String, CaseIterable, Identifiable, Hashable, Equatable {
    case interior
    case exterior
    var id: String { rawValue }
    var label: String {
        switch self {
        case .interior: return "Interior"
        case .exterior: return "Exterior"
        }
    }
    var icon: String {
        switch self {
        case .interior: return "house.fill"
        case .exterior: return "map"
        }
    }
}

enum LibraryLevel: String, CaseIterable, Identifiable, Equatable {
    case studio
    case customer
    case episode
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .studio:   return "building.columns"
        case .customer: return "person.text.rectangle"
        case .episode:  return "film"
        }
    }
    var badgeText: String {
        switch self {
        case .studio:   return "ST"
        case .customer: return "CU"
        case .episode:  return "EP"
        }
    }
    var badgeColor: Color {
        switch self {
        case .studio:   return .purple
        case .customer: return .blue
        case .episode:  return .teal
        }
    }
}

// MARK: - Variant

struct Variant: Identifiable, Equatable {
    let id: String
    var label: String
    var isApproved: Bool
    var isGenerated: Bool = false
}

// MARK: - Panel status

struct PanelStatusFlags {
    var smallPanelAvailable: Bool
    var largePanelAvailable: Bool
}

// MARK: - CastingItem

struct CastingItem: Identifiable, Equatable {
    let id: String
    var name: String
    var description: String
    var type: CastingItemType
    var gender: CharacterGender?
    var locationSetting: LocationSetting?
    var libraryLevel: LibraryLevel
    var variants: [Variant]
    var smallImageAvailable: Bool = false
    var largeImageAvailable: Bool = false
    var fileName: String = ""

    var variantsAvailable: Bool { variants.contains { $0.isApproved } }

    /// Index of the currently approved variant (first approved one).
    var approvedIndex: Int? { variants.firstIndex { $0.isApproved } }

    static func emptyVariants(prefix: String) -> [Variant] {
        (1...4).map { Variant(id: "\(prefix)-v\($0)", label: "Variant \($0)", isApproved: false) }
    }
}

// MARK: - Library tree structs

struct MockPanel: Identifiable, Hashable {
    let id: String
    var name: String
    var description: String
    var smallPanelAvailable: Bool = false
    var largePanelAvailable: Bool = false
    var attachedAssetIDs: [String] = []
    var fileName: String = ""
}

extension MockPanel {
    var panelStatusFlags: PanelStatusFlags {
        PanelStatusFlags(
            smallPanelAvailable: smallPanelAvailable,
            largePanelAvailable: largePanelAvailable
        )
    }
}

struct MockScene: Identifiable, Hashable {
    let id: String
    var name: String
    var description: String
    var panels: [MockPanel]
}

struct MockAct: Identifiable, Hashable {
    let id: String
    var name: String
    var description: String
    var sequences: [MockSequence]
}

struct MockSequence: Identifiable, Hashable {
    let id: String
    var name: String
    var description: String
    var scenes: [MockScene]
}

struct MockEpisode: Identifiable {
    let id: String
    var name: String
    var rules: String = ""
    var preferredLookID: String? = nil
    var characters: [CastingItem]
    var locations: [CastingItem]
    var acts: [MockAct] = []
}

struct MockCustomer: Identifiable {
    let id: String
    var name: String
    var rules: String = ""
    var preferredLookID: String? = nil
    var episodes: [MockEpisode]
    var characters: [CastingItem] = []
    var locations: [CastingItem] = []
}

struct MockStudio: Identifiable {
    let id: String
    var name: String
    var rules: String = ""
    var preferredLookID: String? = nil
    var customers: [MockCustomer]
    var characters: [CastingItem]
    var locations: [CastingItem]
}

// MARK: - Generation job types

enum GenerationJobType: String, CaseIterable, Identifiable {
    case generateAsset   = "Generate Asset"
    case generateExample = "Generate Example"
    case generatePanel   = "Generate Panel"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .generateAsset:   return "photo"
        case .generateExample: return "eye"
        case .generatePanel:   return "rectangle.and.pencil.and.ellipsis"
        }
    }

    var color: Color {
        switch self {
        case .generateAsset:   return .blue
        case .generateExample: return .purple
        case .generatePanel:   return .orange
        }
    }

    var letter: String {
        switch self {
        case .generateAsset:   return "A"
        case .generateExample: return "E"
        case .generatePanel:   return "P"
        }
    }
}

enum GenerationSize: String, CaseIterable, Identifiable {
    case small = "Small"
    case large = "Large"
    var id: String { rawValue }
    var letter: String {
        switch self {
        case .small: return "S"
        case .large: return "L"
        }
    }
}

// MARK: - Look template (name + style prompt only)

/// Status of a Look / template example image.
enum LookStatus: String, CaseIterable, Identifiable {
    case noExample       = "No Example"
    case exampleAvailable = "Example Available"
    var id: String { rawValue }
}

struct GenerationTemplate: Identifiable {
    let id: String
    var name: String
    /// Style prompt: describes the visual look, e.g. "Photorealistic" or "Comic Style".
    var description: String
    var itemType: CastingItemType
    var lookStatus: LookStatus = .noExample
}

// MARK: - Generation job

struct GenerationJob: Identifiable {
    let id: String
    let itemName: String
    let itemType: CastingItemType
    let jobType: GenerationJobType
    let size: GenerationSize
    let lookName: String
    let queuedAt: Date
    let estimatedDuration: TimeInterval
    let itemIcon: String
    var itemGender: CharacterGender? = nil
    var itemLocationSetting: LocationSetting? = nil
    let seed: Int64
    let width: Int
    let height: Int
    let combinedPrompt: String
    var variantCount: Int = 0
    var attachedAssets: [JobAssetInfo] = []
    /// Set when generation starts (first image of the job).
    var startedAt: Date? = nil
    /// Set when the job is moved to the done list.
    var completedAt: Date? = nil
}

struct JobAssetInfo: Identifiable {
    let id: String
    let name: String
    let type: CastingItemType
    let icon: String
    var gender: CharacterGender? = nil
    var locationSetting: LocationSetting? = nil
}

// MARK: - Size configuration keys

enum SizeConfigKeys {
    static let previewVariantWidth  = "dts.previewVariantWidth"
    static let previewVariantHeight = "dts.previewVariantHeight"
    static let finalWidth           = "dts.finalWidth"
    static let finalHeight          = "dts.finalHeight"
    // Look example prompts — appended to the look description per type
    static let lookPromptCharacter  = "dts.lookPromptCharacter"
    static let lookPromptLocation   = "dts.lookPromptLocation"
    static let lookPromptPanel      = "dts.lookPromptPanel"
}

enum SizeConfigDefaults {
    static let previewVariantWidth  = 576
    static let previewVariantHeight = 320
    static let finalWidth           = 1920
    static let finalHeight          = 1080
    static let lookPromptCharacter  = "Full-body character portrait, neutral background, consistent lighting."
    static let lookPromptLocation   = "Wide establishing shot, detailed environment, consistent lighting."
    static let lookPromptPanel      = "Cinematic composition, detailed scene, consistent lighting."
}

// MARK: - Generic browser item

struct MockItem: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    var status: String = ""
    var variantCount: Int = 0
}

// MARK: - Mock data

struct MockData {
    static let defaultStudios: [MockStudio] = [
        MockStudio(
            id: "studio-thriller",
            name: "Noir Productions",
            preferredLookID: "tpl-01",
            customers: [
                MockCustomer(
                    id: "cust-alpha",
                    name: "Alpha Films",
                    preferredLookID: "tpl-01",
                    episodes: [
                        MockEpisode(
                            id: "ep_main",
                            name: "The Heist",
                            preferredLookID: "tpl-01",
                            characters: [
                                CastingItem(id: "ch-01", name: "Alex", description: "The hero. Determined, mid-30s.", type: .character, gender: .male, libraryLevel: .episode, variants: [
                                    Variant(id: "ch-01-v1", label: "Variant 1", isApproved: true),
                                    Variant(id: "ch-01-v2", label: "Variant 2", isApproved: false),
                                    Variant(id: "ch-01-v3", label: "Variant 3", isApproved: false),
                                    Variant(id: "ch-01-v4", label: "Variant 4", isApproved: false),
                                ], smallImageAvailable: true),
                                CastingItem(id: "ch-02", name: "River", description: "The strategist. Cool, late-20s.", type: .character, gender: .female, libraryLevel: .episode, variants: CastingItem.emptyVariants(prefix: "ch-02")),
                                CastingItem(id: "ch-03", name: "Jordan", description: "The wildcard.", type: .character, gender: .nonBinary, libraryLevel: .episode, variants: CastingItem.emptyVariants(prefix: "ch-03")),
                            ],
                            locations: [
                                CastingItem(id: "lo-01", name: "Rooftop", description: "Urban rooftop, night skyline, neon reflections.", type: .location, locationSetting: .exterior, libraryLevel: .episode, variants: [
                                    Variant(id: "lo-01-v1", label: "Variant 1", isApproved: true),
                                    Variant(id: "lo-01-v2", label: "Variant 2", isApproved: false),
                                ], smallImageAvailable: true, largeImageAvailable: true),
                                CastingItem(id: "lo-02", name: "Vault", description: "Bank vault interior, steel walls, motion sensors.", type: .location, locationSetting: .interior, libraryLevel: .episode, variants: CastingItem.emptyVariants(prefix: "lo-02")),
                            ]
                        ),
                    ]
                ),
            ],
            characters: [
                CastingItem(id: "st-ch-01", name: "Guard", description: "Generic security guard.", type: .character, gender: .male, libraryLevel: .studio, variants: CastingItem.emptyVariants(prefix: "st-ch-01")),
            ],
            locations: []
        ),
        MockStudio(
            id: "studio-scifi",
            name: "Stellar Stories",
            customers: [
                MockCustomer(
                    id: "cust-beta",
                    name: "Beta Channel",
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

    // MARK: - Look templates (style prompts only)

    static let defaultTemplates: [GenerationTemplate] = [
        GenerationTemplate(
            id: "tpl-01",
            name: "Photorealistic",
            description: "Photorealistic, cinematic lighting, 8k resolution, dramatic shadows.",
            itemType: .character,
            lookStatus: .exampleAvailable
        ),
        GenerationTemplate(
            id: "tpl-02",
            name: "Comic Style",
            description: "Bold outlines, flat colors, comic book style, high contrast.",
            itemType: .character
        ),
        GenerationTemplate(
            id: "tpl-03",
            name: "Noir",
            description: "Black and white, high contrast, film noir aesthetic, dramatic shadows.",
            itemType: .location
        ),
        GenerationTemplate(
            id: "tpl-04",
            name: "Watercolor",
            description: "Soft watercolor illustration, pastel tones, painterly style.",
            itemType: .location
        ),
    ]

    // MARK: - Model configurations

    static let defaultModelConfigs: [DTModelConfig] = [
        DTModelConfig(
            id: "mc-01",
            name: "SDXL Standard",
            model: "sd_xl_base_1.0.safetensors",
            steps: 30,
            guidanceScale: 7.0
        ),
        DTModelConfig(
            id: "mc-02",
            name: "SDXL Fast",
            model: "sd_xl_base_1.0.safetensors",
            steps: 15,
            guidanceScale: 5.0
        ),
        DTModelConfig(
            id: "mc-03",
            name: "Flux Schnell",
            model: "flux_1_schnell_q5p.ckpt",
            steps: 4,
            guidanceScale: 1.0
        ),
    ]

    // MARK: - Mock generation queue

    static let sampleQueue: [GenerationJob] = [
        GenerationJob(
            id: "job-01", itemName: "Alex", itemType: .character,
            jobType: .generateAsset, size: .small, lookName: "Photorealistic",
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
            jobType: .generateAsset, size: .large, lookName: "Noir",
            queuedAt: Date().addingTimeInterval(-60),
            estimatedDuration: 180, itemIcon: "mountain.2",
            itemLocationSetting: .exterior,
            seed: 1337,
            width: SizeConfigDefaults.finalWidth,
            height: SizeConfigDefaults.finalHeight,
            combinedPrompt: "Black and white, high contrast, film noir aesthetic, dramatic shadows, Urban rooftop, night skyline, neon reflections."
        ),
    ]

    static func items(for section: AppSection?) -> [MockItem] {
        return []
    }
}
