import Foundation

// MARK: - Versioned JSON base

/// Every persisted JSON file carries a schema version for future migration.
protocol VersionedJSON: Codable {
    var version: Int { get }
}

// MARK: - dtsb-config.json  (app-wide)

/// Top-level app config stored at ~/Pictures/DrawThings-Storyboard/dtsb-config.json
struct AppConfig: VersionedJSON {
    var version: Int = 1
    var defaultLookName: String?
    var modelConfigs: [ModelConfigJSON]

    // Image sizes
    var previewVariantWidth:  Int = SizeConfigDefaults.previewVariantWidth
    var previewVariantHeight: Int = SizeConfigDefaults.previewVariantHeight
    var finalWidth:           Int = SizeConfigDefaults.finalWidth
    var finalHeight:          Int = SizeConfigDefaults.finalHeight

    // Look example prompt (single, appended to every look description)
    var lookExamplePrompt: String = SizeConfigDefaults.lookExamplePrompt

    // Panel prompt
    var lookPromptPanel: String = SizeConfigDefaults.lookPromptPanel

    // Draw Things shared secret
    var sharedSecret: String = ""
}

struct ModelConfigJSON: Codable, Identifiable {
    var id: String
    var name: String
    var model: String
    var steps: Int
    var guidanceScale: Double
}

// MARK: - lo-config.json  (looks library)

/// Stored at ~/Pictures/DrawThings-Storyboard/library/lo-config.json
struct LooksConfig: VersionedJSON {
    var version: Int = 1
    var looks: [LookJSON]
}

struct LookJSON: Codable, Identifiable {
    var id: String
    var name: String
    /// Style prompt describing the visual look.
    var description: String
    var lookStatus: String        // "noExample" | "exampleAvailable"
    var exampleFileName: String?
}

// MARK: - lo-catalog.json  (looks library)

/// Lists all look example PNG files in the looks folder.
struct LooksCatalog: VersionedJSON {
    var version: Int = 1
    var entries: [LookCatalogEntry]
}

struct LookCatalogEntry: Codable {
    var lookID: String
    var fileName: String
}

// MARK: - st-config.json  (studio)

struct StudioConfig: VersionedJSON {
    var version: Int = 1
    var id: String
    var name: String
    var rules: String
    var preferredLookID: String?
}

// MARK: - st-catalog.json / cu-catalog.json  (asset catalogs)

/// Lists all asset PNG files at this library level.
struct AssetCatalog: VersionedJSON {
    var version: Int = 1
    var entries: [AssetCatalogEntry]
}

struct AssetCatalogEntry: Codable {
    var assetID: String
    var variantIndex: Int
    var fileName: String
    var isApproved: Bool
}

// MARK: - cu-config.json  (customer)

struct CustomerConfig: VersionedJSON {
    var version: Int = 1
    var id: String
    var name: String
    var rules: String
    var preferredLookID: String?
}

// MARK: - as-config.json  (asset — character or location)

struct AssetConfig: VersionedJSON {
    var version: Int = 1
    var id: String
    var name: String
    var description: String
    var assetType: String         // "character" | "location"
    var gender: String?           // character only
    var locationSetting: String?  // location only
    var libraryLevel: String      // "studio" | "customer" | "episode"
    var variants: [VariantJSON]
}

struct VariantJSON: Codable {
    var id: String
    var label: String
    var isApproved: Bool
    var isGenerated: Bool
    var fileName: String?
}

// MARK: - ep-config.json  (episode)

struct EpisodeConfig: VersionedJSON {
    var version: Int = 1
    var id: String
    var name: String
    var rules: String
    var preferredLookID: String?
    var characterIDs: [String]
    var locationIDs: [String]
}

// MARK: - ep-catalog.json  (episode panel images)

struct EpisodeCatalog: VersionedJSON {
    var version: Int = 1
    var entries: [PanelCatalogEntry]
}

struct PanelCatalogEntry: Codable {
    var panelID: String
    var fileName: String
    var isSmall: Bool
}

// MARK: - pa-config.json  (panel)

struct PanelConfig: VersionedJSON {
    var version: Int = 1
    var id: String
    var name: String
    var description: String
    var actName: String
    var sequenceName: String
    var sceneName: String
    var attachedAssetIDs: [String]
    var smallPanelAvailable: Bool
    var largePanelAvailable: Bool
    var smallFileName: String?
    var largeFileName: String?
}
