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
    var icon: String { "person.fill" }
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
    var approvedIndex: Int? { variants.firstIndex { $0.isApproved } }

    static func emptyVariants(prefix: String) -> [Variant] {
        (1...4).map { Variant(id: "\(prefix)-v\($0)", label: "Variant \($0)", isApproved: false) }
    }
}

// MARK: - Storyboard structs

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
        PanelStatusFlags(smallPanelAvailable: smallPanelAvailable,
                         largePanelAvailable: largePanelAvailable)
    }
}

struct MockScene: Identifiable, Hashable {
    let id: String
    var name: String
    var description: String
    var panels: [MockPanel]
}

struct MockSequence: Identifiable, Hashable {
    let id: String
    var name: String
    var description: String
    var scenes: [MockScene]
}

struct MockAct: Identifiable, Hashable {
    let id: String
    var name: String
    var description: String
    var sequences: [MockSequence]
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

// MARK: - Look template

enum LookStatus: String, CaseIterable, Identifiable {
    case noExample        = "No Example"
    case exampleAvailable = "Example Available"
    var id: String { rawValue }
}

/// A visual style template. No itemType — looks apply to all generation types.
struct GenerationTemplate: Identifiable {
    let id: String
    var name: String
    var description: String
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
    var startedAt: Date? = nil
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

// MARK: - Size configuration

enum SizeConfigKeys {
    static let previewVariantWidth  = "dts.previewVariantWidth"
    static let previewVariantHeight = "dts.previewVariantHeight"
    static let finalWidth           = "dts.finalWidth"
    static let finalHeight          = "dts.finalHeight"
    static let lookExamplePrompt    = "dts.lookExamplePrompt"
    static let lookPromptPanel      = "dts.lookPromptPanel"
}

enum SizeConfigDefaults {
    static let previewVariantWidth  = 576
    static let previewVariantHeight = 320
    static let finalWidth           = 1920
    static let finalHeight          = 1080
    static let lookExamplePrompt    = "An astronaut riding a horse."
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

// MARK: - MockData  (previews only)

struct MockData {
    static func items(for section: AppSection?) -> [MockItem] { [] }
}
