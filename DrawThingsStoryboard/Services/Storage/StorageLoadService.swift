import Foundation

// MARK: - StorageLoadService

final class StorageLoadService {

    static let shared = StorageLoadService()
    private init() {}

    private let fm = FileManager.default
    private let decoder = JSONDecoder()

    // MARK: - Top-level load

    struct AppState {
        var studios: [MockStudio]
        var templates: [GenerationTemplate]
        var modelConfigs: [DTModelConfig]
        var appConfig: AppConfig?
    }

    func load() -> AppState {
        let root    = StorageService.shared.rootURL
        let library = root.appendingPathComponent("library")

        let appConfig    = loadAppConfig(from: root)
        let templates    = loadTemplates(from: library)
        let modelConfigs = appConfig?.modelConfigs.map {
            DTModelConfig(id: $0.id, name: $0.name, model: $0.model,
                          steps: $0.steps, guidanceScale: $0.guidanceScale)
        } ?? DTModelConfig.defaultConfigs
        let studios = loadStudios(from: library, root: root)

        return AppState(studios: studios, templates: templates,
                        modelConfigs: modelConfigs, appConfig: appConfig)
    }

    // MARK: - App config

    func loadAppConfig(from root: URL) -> AppConfig? {
        decode(root.appendingPathComponent("dtsb-config.json"))
    }

    func saveAppConfig(_ config: AppConfig) {
        let url = StorageService.shared.rootURL.appendingPathComponent("dtsb-config.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(config) else { return }
        try? data.write(to: url, options: .atomic)
    }

    // MARK: - Looks

    private func loadTemplates(from library: URL) -> [GenerationTemplate] {
        let url = library.appendingPathComponent("lo-config.json")
        guard let config: LooksConfig = decode(url) else { return [] }
        return config.looks.map { look in
            GenerationTemplate(
                id: look.id, name: look.name, description: look.description,
                lookStatus: look.lookStatus == "exampleAvailable" ? .exampleAvailable : .noExample
            )
        }
    }

    /// Persists the current in-memory templates back to lo-config.json.
    func saveTemplates(_ templates: [GenerationTemplate]) {
        let library = StorageService.shared.rootURL.appendingPathComponent("library")
        let url = library.appendingPathComponent("lo-config.json")
        let looks = templates.map { t in
            LookJSON(id: t.id, name: t.name, description: t.description,
                     lookStatus: t.lookStatus == .exampleAvailable ? "exampleAvailable" : "noExample",
                     exampleFileName: nil)
        }
        let config = LooksConfig(version: 1, looks: looks)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(config) else { return }
        try? data.write(to: url, options: .atomic)
    }

    // MARK: - Studios

    private func loadStudios(from library: URL, root: URL) -> [MockStudio] {
        return subdirectories(of: library).compactMap { studioDir in
            guard let sc: StudioConfig = decode(studioDir.appendingPathComponent("st-config.json"))
            else { return nil }
            let customers = loadCustomers(from: studioDir, root: root)
            let (chars, locs) = loadAssets(from: studioDir, level: .studio)
            return MockStudio(id: sc.id, name: sc.name, rules: sc.rules,
                              preferredLookID: sc.preferredLookID,
                              customers: customers, characters: chars, locations: locs)
        }
    }

    // MARK: - Customers

    private func loadCustomers(from studioDir: URL, root: URL) -> [MockCustomer] {
        return subdirectories(of: studioDir).compactMap { custDir in
            guard let cc: CustomerConfig = decode(custDir.appendingPathComponent("cu-config.json"))
            else { return nil }
            let episodes = loadEpisodes(from: root)
            let (chars, locs) = loadAssets(from: custDir, level: .customer)
            return MockCustomer(id: cc.id, name: cc.name, rules: cc.rules,
                                preferredLookID: cc.preferredLookID,
                                episodes: episodes, characters: chars, locations: locs)
        }
    }

    // MARK: - Episodes

    private func loadEpisodes(from root: URL) -> [MockEpisode] {
        return subdirectories(of: root).filter { dir in
            fm.fileExists(atPath: dir.appendingPathComponent("ep-config.json").path)
        }.compactMap { epDir in
            guard let ec: EpisodeConfig = decode(epDir.appendingPathComponent("ep-config.json"))
            else { return nil }
            let (chars, locs) = loadEpisodeAssets(from: epDir)
            let acts = loadActs(from: epDir)
            return MockEpisode(id: ec.id, name: ec.name, rules: ec.rules,
                               preferredLookID: ec.preferredLookID,
                               characters: chars, locations: locs, acts: acts)
        }
    }

    // MARK: - Assets

    private func loadAssets(from dir: URL, level: LibraryLevel) -> ([CastingItem], [CastingItem]) {
        var chars: [CastingItem] = []
        var locs:  [CastingItem] = []
        for sub in subdirectories(of: dir) {
            let name = sub.lastPathComponent
            guard let ac: AssetConfig = decode(sub.appendingPathComponent("as-config.json")) else { continue }
            let item = buildCastingItem(from: ac, level: level)
            if name.hasPrefix("ch-") { chars.append(item) }
            else if name.hasPrefix("lo-") { locs.append(item) }
        }
        return (chars, locs)
    }

    private func loadEpisodeAssets(from epDir: URL) -> ([CastingItem], [CastingItem]) {
        var chars: [CastingItem] = []
        var locs:  [CastingItem] = []
        for sub in subdirectories(of: epDir) {
            let name = sub.lastPathComponent
            guard let ac: AssetConfig = decode(sub.appendingPathComponent("as-config.json")) else { continue }
            let item = buildCastingItem(from: ac, level: .episode)
            if name.hasPrefix("ch-") { chars.append(item) }
            else if name.hasPrefix("lo-") { locs.append(item) }
        }
        return (chars, locs)
    }

    private func buildCastingItem(from ac: AssetConfig, level: LibraryLevel) -> CastingItem {
        let gender:  CharacterGender? = ac.gender.flatMap { CharacterGender(rawValue: $0) }
        let setting: LocationSetting? = ac.locationSetting.flatMap { LocationSetting(rawValue: $0) }
        let variants = ac.variants.map { v in
            Variant(id: v.id, label: v.label, isApproved: v.isApproved, isGenerated: v.isGenerated)
        }
        return CastingItem(id: ac.id, name: ac.name, description: ac.description,
                           type: ac.assetType == "location" ? .location : .character,
                           gender: gender, locationSetting: setting,
                           libraryLevel: level, variants: variants)
    }

    // MARK: - Storyboard

    private func loadActs(from epDir: URL) -> [MockAct] {
        return subdirectories(of: epDir)
            .filter { isActDir($0) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { actDir in
                MockAct(id: actDir.lastPathComponent, name: actDir.lastPathComponent,
                        description: "", sequences: loadSequences(from: actDir))
            }
    }

    private func loadSequences(from actDir: URL) -> [MockSequence] {
        return subdirectories(of: actDir)
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { seqDir in
                MockSequence(id: seqDir.lastPathComponent, name: seqDir.lastPathComponent,
                             description: "", scenes: loadScenes(from: seqDir))
            }
    }

    private func loadScenes(from seqDir: URL) -> [MockScene] {
        return subdirectories(of: seqDir)
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { sceneDir in
                MockScene(id: sceneDir.lastPathComponent, name: sceneDir.lastPathComponent,
                          description: "", panels: loadPanels(from: sceneDir))
            }
    }

    private func loadPanels(from sceneDir: URL) -> [MockPanel] {
        return subdirectories(of: sceneDir)
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { panelDir in
                guard let pc: PanelConfig = decode(panelDir.appendingPathComponent("pa-config.json"))
                else { return nil }
                return MockPanel(id: pc.id, name: pc.name, description: pc.description,
                                 smallPanelAvailable: pc.smallPanelAvailable,
                                 largePanelAvailable: pc.largePanelAvailable,
                                 attachedAssetIDs: pc.attachedAssetIDs)
            }
    }

    private func isActDir(_ url: URL) -> Bool {
        let name = url.lastPathComponent
        return !name.hasPrefix(".") && !name.hasPrefix("ch-") && !name.hasPrefix("lo-") &&
               !fm.fileExists(atPath: url.appendingPathComponent("ep-config.json").path)
    }

    // MARK: - File system helpers

    private func subdirectories(of url: URL) -> [URL] {
        guard let contents = try? fm.contentsOfDirectory(
            at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
        ) else { return [] }
        return contents.filter { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        }
    }

    private func decode<T: Decodable>(_ url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }
}
