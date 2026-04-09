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
    // #19: gRPC server settings
    var grpcAddress: String = "localhost"
    var grpcPort: Int = 7859
    // #49: Character turn-around prompt fragment
    var characterTurnAround: String = "Character turn-around sheet with exactly two views: frontal and side looking to the right. Full body-view, neutral grey background."
    // #59: Pushover notification credentials
    var pushoverToken: String = ""
    var pushoverUser: String = ""
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
    // #51: Sampler name (free text, e.g. "UniPC Trailing")
    var sampler: String = ""
    // #51: Whether this model supports img2img generation
    var isImg2ImgCapable: Bool = false

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

struct StoryboardsFile: Codable, Equatable {
    var storyboards: [StoryboardEntry]
    var version: Int = 1
}

struct StoryboardEntry: Codable, Identifiable, Equatable {
    var name: String
    var acts: [ActEntry]
    var modelID: String
    var styleID: String

    var id: String { name }
}

struct ActEntry: Codable, Identifiable, Equatable {
    var name: String
    var sequences: [SequenceEntry]

    var id: String { name }
}

struct SequenceEntry: Codable, Identifiable, Equatable {
    var name: String
    var scenes: [SceneEntry]

    var id: String { name }
}

struct SceneEntry: Codable, Identifiable, Equatable {
    var name: String
    var panels: [PanelEntry]

    var id: String { name }
}

struct PanelEntry: Codable, Identifiable, Equatable {
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
/// #57: Per-style asset variants

struct AssetsFile: Codable {
    var assets: [AssetEntry]
    var version: Int = 1
}

/// Per-style collection of up to 4 variants + one large image.
struct AssetStyleVariants: Codable {
    var variants: [AssetVariant] = []
    var largeImageID: String = ""

    var hasLargeImage: Bool { !largeImageID.isEmpty }

    var approvedVariantIndex: Int? {
        variants.firstIndex { $0.isApproved }
    }

    var hasApprovedVariant: Bool { approvedVariantIndex != nil }

    /// Number of empty variant slots (max 4).
    var emptySlotCount: Int {
        max(0, 4 - variants.count)
    }

    /// Approved variant’s seed, or 0 if none.
    var approvedSeed: Int {
        guard let idx = approvedVariantIndex else { return 0 }
        return variants[idx].seed
    }

    /// Best available image ID: large > approved variant > first variant with image.
    var bestImageID: String {
        if hasLargeImage { return largeImageID }
        if let idx = approvedVariantIndex, variants[idx].hasImage {
            return variants[idx].smallImageID
        }
        return variants.first(where: { $0.hasImage })?.smallImageID ?? ""
    }
}

struct AssetEntry: Codable, Identifiable {
    var assetID: String
    var name: String
    var type: String
    var subType: String
    var description: String
    /// #57: Per-style variants. Key = styleID.
    var styleVariants: [String: AssetStyleVariants] = [:]

    var id: String { assetID }

    var isCharacter: Bool { type == "character" }
    var isLocation: Bool { type == "location" }

    // MARK: - Style-aware accessors

    /// Get or create the AssetStyleVariants for a given style.
    func variantsFor(style styleID: String) -> AssetStyleVariants {
        styleVariants[styleID] ?? AssetStyleVariants()
    }

    /// Best image for a given style (large > approved > first variant).
    func bestImageID(forStyle styleID: String) -> String {
        variantsFor(style: styleID).bestImageID
    }

    /// Whether this asset has an approved variant for a given style.
    func hasApprovedVariant(forStyle styleID: String) -> Bool {
        variantsFor(style: styleID).hasApprovedVariant
    }

    /// Whether this asset has a large image for a given style.
    func hasLargeImage(forStyle styleID: String) -> Bool {
        variantsFor(style: styleID).hasLargeImage
    }

    /// All style IDs that have at least one generated image.
    var generatedStyleIDs: [String] {
        styleVariants.filter { !$0.value.variants.isEmpty || $0.value.hasLargeImage }
            .map { $0.key }
            .sorted()
    }

    /// Whether any style has any image at all.
    var hasAnyImage: Bool {
        styleVariants.values.contains { !$0.variants.isEmpty || $0.hasLargeImage }
    }

    /// Best display image across all styles (for tiles when no style filter is active).
    var bestDisplayImageID: String {
        for sv in styleVariants.values {
            let img = sv.bestImageID
            if !img.isEmpty { return img }
        }
        return ""
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
    static func randomSeed() -> Int {
        Int.random(in: 1...999_999)
    }

    static func isUnassigned(_ seed: Int) -> Bool {
        seed == 0
    }
}

// MARK: - Validation Helpers

enum ValidationHelper {
    static func isValidDimension(_ value: Int) -> Bool {
        value > 0 && value % 64 == 0
    }

    static func isValidGuidanceScale(_ value: Double) -> Bool {
        value >= 0 && value <= 30
    }

    static func isValidModelFilename(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }
        let lower = name.lowercased()
        return lower.hasSuffix(".ckpt") || lower.hasSuffix(".safetensors")
    }

    static func isValidPort(_ port: Int) -> Bool {
        port >= 1 && port <= 65535
    }
}
