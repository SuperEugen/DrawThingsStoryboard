import Foundation

// MARK: - config.json

struct AppConfig: Codable, Equatable {
    var smallImageWidth: Int = 576
    var smallImageHeight: Int = 320
    var largeImageWidth: Int = 1920
    var largeImageHeight: Int = 1080
    var defaultPanelDuration: Int = 30
    var stylePrompt: String = "An astronaut riding a horse."
    var sharedSecret: String = ""
    var version: Int = 1
}

// MARK: - models.json

struct ModelsFile: Codable {
    var models: [ModelEntry]
    var version: Int = 1
}

struct ModelEntry: Codable, Identifiable {
    var modelID: String
    var name: String
    var guidanceScale: Double
    var model: String
    var steps: Int
    var defaultGenTimeSmall: Int = 60
    var defaultGenTimeLarge: Int = 180

    var id: String { modelID }
}

// MARK: - styles.json

struct StylesFile: Codable {
    var styles: [StyleEntry]
    var version: Int = 1
}

struct StyleEntry: Codable, Identifiable {
    var styleID: String
    var name: String
    var smallImageID: String = ""
    var isGenerated: Bool = false
    var style: String

    var id: String { styleID }
}

// MARK: - storyboards.json

struct StoryboardsFile: Codable {
    var storyboards: [StoryboardEntry]
    var version: Int = 1
}

struct StoryboardEntry: Codable, Identifiable {
    var name: String
    var acts: [ActEntry]
    var modelID: String
    var styleID: String

    var id: String { name }
}

struct ActEntry: Codable, Identifiable {
    var name: String
    var sequences: [SequenceEntry]

    var id: String { name }
}

struct SequenceEntry: Codable, Identifiable {
    var name: String
    var scenes: [SceneEntry]

    var id: String { name }
}

struct SceneEntry: Codable, Identifiable {
    var name: String
    var panels: [PanelEntry]

    var id: String { name }
}

struct PanelEntry: Codable, Identifiable {
    var panelID: String
    var name: String
    var description: String = ""
    var cameraMovement: String = ""
    var dialogue: String = ""
    var duration: Int = 30
    var smallImageID: String = ""
    var largeImageID: String = ""
    var ref1ID: String = ""
    var ref2ID: String = ""
    var ref3ID: String = ""
    var ref4ID: String = ""
    var seed: Int = 0

    var id: String { panelID }

    var hasSmallImage: Bool { !smallImageID.isEmpty }
    var hasLargeImage: Bool { !largeImageID.isEmpty }

    var refIDs: [String] {
        [ref1ID, ref2ID, ref3ID, ref4ID].filter { !$0.isEmpty }
    }
}

// MARK: - assets.json

struct AssetsFile: Codable {
    var assets: [AssetEntry]
    var version: Int = 1
}

struct AssetEntry: Codable, Identifiable {
    var assetID: String
    var name: String
    var type: String          // "character" or "location"
    var subType: String       // "male", "female", "interior", "exterior"
    var description: String
    var smallImageID: String = ""
    var largeImageID: String = ""
    var seed: Int = 0
    var variant1: AssetVariant = AssetVariant()
    var variant2: AssetVariant = AssetVariant()
    var variant3: AssetVariant = AssetVariant()
    var variant4: AssetVariant = AssetVariant()

    var id: String { assetID }

    var isCharacter: Bool { type == "character" }
    var isLocation: Bool { type == "location" }

    var hasSmallImage: Bool { !smallImageID.isEmpty }
    var hasLargeImage: Bool { !largeImageID.isEmpty }

    /// Returns all 4 variants as an array for iteration.
    var variants: [AssetVariant] {
        [variant1, variant2, variant3, variant4]
    }

    /// Returns the index (0-based) of the first approved variant, or nil.
    var approvedVariantIndex: Int? {
        variants.firstIndex { $0.isApproved }
    }

    var hasApprovedVariant: Bool { approvedVariantIndex != nil }

    /// Mutates a variant at the given index (0–3).
    mutating func setVariant(at index: Int, _ variant: AssetVariant) {
        switch index {
        case 0: variant1 = variant
        case 1: variant2 = variant
        case 2: variant3 = variant
        case 3: variant4 = variant
        default: break
        }
    }

    /// Returns the variant at the given index (0–3).
    func variant(at index: Int) -> AssetVariant {
        switch index {
        case 0: return variant1
        case 1: return variant2
        case 2: return variant3
        case 3: return variant4
        default: return AssetVariant()
        }
    }
}

struct AssetVariant: Codable {
    var smallImageID: String = ""
    var seed: Int = 0
    var isApproved: Bool = false

    var hasImage: Bool { !smallImageID.isEmpty }
}

// MARK: - production-log.json

struct ProductionLogFile: Codable {
    var generatedImages: [GeneratedImageEntry]
    var version: Int = 1
}

struct GeneratedImageEntry: Codable, Identifiable {
    var imageID: String = ""
    var type: String = ""
    var modelID: String = ""
    var styleID: String = ""
    var ref1ID: String = ""
    var ref2ID: String = ""
    var ref3ID: String = ""
    var ref4ID: String = ""
    var startTime: String = ""
    var endTime: String = ""
    var size: String = ""
    var seed: Int = 0
    var combinedPrompt: String = ""

    var id: String { imageID.isEmpty ? UUID().uuidString : imageID }
}

// MARK: - Seed Helper

enum SeedHelper {
    /// Generate a random seed for Draw Things (1 ... 999_999).
    static func randomSeed() -> Int {
        Int.random(in: 1...999_999)
    }

    /// Returns true if the seed is unassigned (0 = not yet generated).
    static func isUnassigned(_ seed: Int) -> Bool {
        seed == 0
    }
}
