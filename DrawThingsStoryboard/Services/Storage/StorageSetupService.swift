import Foundation

// MARK: - StorageSetupService
//
// Runs once at app launch. If dtsb-config.json is missing, creates the
// complete default folder structure and all *-config / *-catalog JSON files.
//
// Default structure:
//
//   ~/Pictures/DrawThings-Storyboard/
//   │   dtsb-config.json
//   ├── library/
//   │   ├── lo-config.json
//   │   ├── lo-catalog.json
//   │   └── My Studio/
//   │       ├── st-config.json
//   │       ├── st-catalog.json
//   │       └── My Customer/
//   │           ├── cu-config.json
//   │           ├── cu-catalog.json
//   │           ├── ch-My Character/
//   │           │   └── as-config.json
//   │           └── lo-My Location/
//   │               └── as-config.json
//   └── My Episode/
//       ├── ep-config.json
//       ├── ep-catalog.json
//       └── Act 1/
//           └── Sequence 1/
//               └── Scene 1/
//                   └── Panel 1/
//                       └── pa-config.json

final class StorageSetupService {

    static let shared = StorageSetupService()
    private init() {}

    private let fm = FileManager.default
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    // MARK: - Entry point

    /// Call once from the App entry point.
    /// Does nothing if dtsb-config.json already exists.
    func setupIfNeeded() {
        let root = StorageService.shared.rootURL
        let appConfigURL = root.appendingPathComponent("dtsb-config.json")
        guard !fm.fileExists(atPath: appConfigURL.path) else { return }

        do {
            try createDefaultStructure(root: root, appConfigURL: appConfigURL)
            print("[StorageSetupService] First-launch structure created at \(root.path)")
        } catch {
            print("[StorageSetupService] Setup failed: \(error)")
        }
    }

    // MARK: - Default structure

    private func createDefaultStructure(root: URL, appConfigURL: URL) throws {

        // IDs for cross-referencing
        let studioID    = UUID().uuidString
        let customerID  = UUID().uuidString
        let episodeID   = UUID().uuidString
        let lookID      = UUID().uuidString
        let charID      = UUID().uuidString
        let locID       = UUID().uuidString
        let panelID     = UUID().uuidString

        let studioName   = "My Studio"
        let customerName = "My Customer"
        let episodeName  = "My Episode"
        let lookName     = "Default Look"
        let charName     = "My Character"
        let locName      = "My Location"

        // ── Folder URLs ──────────────────────────────────────────────────
        let libraryURL  = root.appendingPathComponent("library")
        let looksURL    = libraryURL
        let studioURL   = libraryURL.appendingPathComponent(studioName)
        let customerURL = studioURL.appendingPathComponent(customerName)
        let charURL     = customerURL.appendingPathComponent("ch-\(charName)")
        let locURL      = customerURL.appendingPathComponent("lo-\(locName)")
        let episodeURL  = root.appendingPathComponent(episodeName)
        let panelURL    = episodeURL
            .appendingPathComponent("Act 1")
            .appendingPathComponent("Sequence 1")
            .appendingPathComponent("Scene 1")
            .appendingPathComponent("Panel 1")

        for url in [libraryURL, studioURL, customerURL, charURL, locURL, episodeURL, panelURL] {
            try makeDir(url)
        }

        // ── dtsb-config.json ─────────────────────────────────────────────
        let appConfig = AppConfig(
            version: 1,
            defaultLookName: lookName,
            modelConfigs: [
                ModelConfigJSON(id: UUID().uuidString, name: "SDXL Standard",
                                model: "sd_xl_base_1.0.safetensors", steps: 30, guidanceScale: 7.0),
                ModelConfigJSON(id: UUID().uuidString, name: "Flux Schnell",
                                model: "flux_1_schnell_q5p.ckpt", steps: 4, guidanceScale: 1.0),
            ],
            previewVariantWidth:  SizeConfigDefaults.previewVariantWidth,
            previewVariantHeight: SizeConfigDefaults.previewVariantHeight,
            finalWidth:           SizeConfigDefaults.finalWidth,
            finalHeight:          SizeConfigDefaults.finalHeight,
            lookPromptCharacter:  "An astronaut riding a horse.",
            lookPromptLocation:   "Wide establishing shot, big city.",
            lookPromptPanel:      "Cinematic composition, detailed scene, consistent lighting.",
            sharedSecret:         ""
        )
        try write(appConfig, to: appConfigURL)

        // ── lo-config.json ───────────────────────────────────────────────
        let looksConfig = LooksConfig(
            version: 1,
            looks: [
                LookJSON(id: lookID, name: lookName,
                         description: "Photorealistic, cinematic lighting, 8k resolution, dramatic shadows.",
                         itemType: "character", lookStatus: "noExample", exampleFileName: nil)
            ]
        )
        try write(looksConfig, to: looksURL.appendingPathComponent("lo-config.json"))

        // ── lo-catalog.json
        try write(LooksCatalog(version: 1, entries: []), to: looksURL.appendingPathComponent("lo-catalog.json"))

        // ── st-config.json
        try write(StudioConfig(version: 1, id: studioID, name: studioName, rules: "", preferredLookID: lookID),
                  to: studioURL.appendingPathComponent("st-config.json"))

        // ── st-catalog.json
        try write(AssetCatalog(version: 1, entries: []), to: studioURL.appendingPathComponent("st-catalog.json"))

        // ── cu-config.json
        try write(CustomerConfig(version: 1, id: customerID, name: customerName, rules: "", preferredLookID: nil),
                  to: customerURL.appendingPathComponent("cu-config.json"))

        // ── cu-catalog.json
        try write(AssetCatalog(version: 1, entries: []), to: customerURL.appendingPathComponent("cu-catalog.json"))

        // ── ch-My Character/as-config.json
        let charConfig = AssetConfig(
            version: 1, id: charID, name: charName,
            description: "Describe your character here.",
            assetType: "character", gender: "male",
            locationSetting: nil, libraryLevel: "customer",
            variants: (1...4).map {
                VariantJSON(id: "\(charID)-v\($0)", label: "Variant \($0)", isApproved: false, isGenerated: false, fileName: nil)
            }
        )
        try write(charConfig, to: charURL.appendingPathComponent("as-config.json"))

        // ── lo-My Location/as-config.json
        let locConfig = AssetConfig(
            version: 1, id: locID, name: locName,
            description: "Describe your location here.",
            assetType: "location", gender: nil,
            locationSetting: "interior", libraryLevel: "customer",
            variants: (1...4).map {
                VariantJSON(id: "\(locID)-v\($0)", label: "Variant \($0)", isApproved: false, isGenerated: false, fileName: nil)
            }
        )
        try write(locConfig, to: locURL.appendingPathComponent("as-config.json"))

        // ── ep-config.json
        try write(
            EpisodeConfig(version: 1, id: episodeID, name: episodeName, rules: "",
                          preferredLookID: nil, characterIDs: [charID], locationIDs: [locID]),
            to: episodeURL.appendingPathComponent("ep-config.json")
        )

        // ── ep-catalog.json
        try write(EpisodeCatalog(version: 1, entries: []), to: episodeURL.appendingPathComponent("ep-catalog.json"))

        // ── Panel 1/pa-config.json
        try write(
            PanelConfig(version: 1, id: panelID, name: "Panel 1", description: "",
                        actName: "Act 1", sequenceName: "Sequence 1", sceneName: "Scene 1",
                        attachedAssetIDs: [], smallPanelAvailable: false, largePanelAvailable: false,
                        smallFileName: nil, largeFileName: nil),
            to: panelURL.appendingPathComponent("pa-config.json")
        )
    }

    // MARK: - Helpers

    private func makeDir(_ url: URL) throws {
        try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }

    private func write<T: Encodable>(_ value: T, to url: URL) throws {
        let data = try encoder.encode(value)
        try data.write(to: url, options: .atomic)
    }
}
