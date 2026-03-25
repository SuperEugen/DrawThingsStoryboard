import Foundation

// MARK: - StorageSetupService

final class StorageSetupService {

    static let shared = StorageSetupService()
    private init() {}

    private let fm = FileManager.default
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

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

    private func createDefaultStructure(root: URL, appConfigURL: URL) throws {

        let studioID    = UUID().uuidString
        let customerID  = UUID().uuidString
        let episodeID   = UUID().uuidString
        let look1ID     = UUID().uuidString
        let look2ID     = UUID().uuidString
        let charID      = UUID().uuidString
        let locID       = UUID().uuidString
        let panelID     = UUID().uuidString

        let studioName   = "My Studio"
        let customerName = "My Customer"
        let episodeName  = "My Episode"
        let charName     = "My Character"
        let locName      = "My Location"

        let libraryURL  = root.appendingPathComponent("library")
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

        // ── dtsb-config.json
        let appConfig = AppConfig(
            version: 1,
            defaultLookName: "Photorealistic",
            modelConfigs: [
                ModelConfigJSON(id: UUID().uuidString,
                                name: "FLUX 2 klein KV",
                                model: "flux_2_klein_9b_kv_q8p.ckpt",
                                steps: 4,
                                guidanceScale: 1.0),
            ],
            previewVariantWidth:  SizeConfigDefaults.previewVariantWidth,
            previewVariantHeight: SizeConfigDefaults.previewVariantHeight,
            finalWidth:           SizeConfigDefaults.finalWidth,
            finalHeight:          SizeConfigDefaults.finalHeight,
            lookExamplePrompt:    SizeConfigDefaults.lookExamplePrompt,
            sharedSecret:         ""
        )
        try write(appConfig, to: appConfigURL)

        // ── lo-config.json
        let looksConfig = LooksConfig(version: 1, looks: [
            LookJSON(id: look1ID, name: "Photorealistic",
                     description: "Photorealistic, cinematic lighting, 8k resolution, dramatic shadows.",
                     lookStatus: "noExample", exampleFileName: nil),
            LookJSON(id: look2ID, name: "Comic Style",
                     description: "Illustration in 2-d flat color art style. Highly stylised with very low detail and no textures, simplified. Minimalistic background.",
                     lookStatus: "noExample", exampleFileName: nil),
        ])
        try write(looksConfig, to: libraryURL.appendingPathComponent("lo-config.json"))

        try write(LooksCatalog(version: 1, entries: []), to: libraryURL.appendingPathComponent("lo-catalog.json"))
        try write(StudioConfig(version: 1, id: studioID, name: studioName, rules: "", preferredLookID: look1ID),
                  to: studioURL.appendingPathComponent("st-config.json"))
        try write(AssetCatalog(version: 1, entries: []), to: studioURL.appendingPathComponent("st-catalog.json"))
        try write(CustomerConfig(version: 1, id: customerID, name: customerName, rules: "", preferredLookID: nil),
                  to: customerURL.appendingPathComponent("cu-config.json"))
        try write(AssetCatalog(version: 1, entries: []), to: customerURL.appendingPathComponent("cu-catalog.json"))

        let charConfig = AssetConfig(
            version: 1, id: charID, name: charName,
            description: "Describe your character here.",
            assetType: "character", gender: "male",
            locationSetting: nil, libraryLevel: "customer",
            variants: (1...4).map {
                VariantJSON(id: "\(charID)-v\($0)", label: "Variant \($0)",
                            isApproved: false, isGenerated: false, fileName: nil)
            }
        )
        try write(charConfig, to: charURL.appendingPathComponent("as-config.json"))

        let locConfig = AssetConfig(
            version: 1, id: locID, name: locName,
            description: "Describe your location here.",
            assetType: "location", gender: nil,
            locationSetting: "interior", libraryLevel: "customer",
            variants: (1...4).map {
                VariantJSON(id: "\(locID)-v\($0)", label: "Variant \($0)",
                            isApproved: false, isGenerated: false, fileName: nil)
            }
        )
        try write(locConfig, to: locURL.appendingPathComponent("as-config.json"))

        try write(
            EpisodeConfig(version: 1, id: episodeID, name: episodeName, rules: "",
                          preferredLookID: nil, characterIDs: [charID], locationIDs: [locID]),
            to: episodeURL.appendingPathComponent("ep-config.json")
        )
        try write(EpisodeCatalog(version: 1, entries: []), to: episodeURL.appendingPathComponent("ep-catalog.json"))
        try write(
            PanelConfig(version: 1, id: panelID, name: "Panel 1", description: "",
                        actName: "Act 1", sequenceName: "Sequence 1", sceneName: "Scene 1",
                        attachedAssetIDs: [], smallPanelAvailable: false, largePanelAvailable: false,
                        smallFileName: nil, largeFileName: nil),
            to: panelURL.appendingPathComponent("pa-config.json")
        )
    }

    private func makeDir(_ url: URL) throws {
        try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }

    private func write<T: Encodable>(_ value: T, to url: URL) throws {
        let data = try encoder.encode(value)
        try data.write(to: url, options: .atomic)
    }
}
