import Foundation

// MARK: - StorageLoadService
//
// Reads the persisted folder structure from disk and builds the in-memory
// app models (MockStudio hierarchy, GenerationTemplate list, DTModelConfig list).
//
// Call load() once at app start, after StorageSetupService.setupIfNeeded().

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
    }

    func load() -> AppState {
        let root    = StorageService.shared.rootURL
        let library = root.appendingPathComponent("library")

        let templates    = loadTemplates(from: library)
        let modelConfigs = loadModelConfigs(from: root)
        let studios      = loadStudios(from: library, root: root, templates: templates)

        return AppState(
            studios: studios,
            templates: templates,
            modelConfigs: modelConfigs.isEmpty ? DTModelConfig.defaultConfigs : modelConfigs
        )
    }

    // MARK: - Looks

    private func loadTemplates(from library: URL) -> [GenerationTemplate] {
        let url = library.appendingPathComponent("lo-config.json")
        guard let config: LooksConfig = decode(url) else { return [] }
        return config.looks.map { look in
            GenerationTemplate(
                id: look.id,
                name: look.name,
                description: look.description,
                itemType: look.itemType == "location" ? .location : .character,
                lookStatus: look.lookStatus == "exampleAvailable" ? .exampleAvailable : .noExample
            )
        }
    }

    // MARK: - Model configs

    private func loadModelConfigs(from root: URL) -> [DTModelConfig] {
        let url = root.appendingPathComponent("dtsb-config.json")
        guard let config: AppConfig = decode(url) else { return [] }
        return config.modelConfigs.map { mc in
            DTModelConfig(id: mc.id, name: mc.name, model: mc.model,
                          steps: mc.steps, guidanceScale: mc.guidanceScale)
        }
    }

    // MARK: - Studios

    private func loadStudios(from library: URL, root: URL,
                             templates: [GenerationTemplate]) -> [MockStudio] {
        let studioDirs = subdirectories(of: library)
        guard !studioDirs.isEmpty else { return [] }

        return studioDirs.compactMap { studioDir in
            guard let sc: StudioConfig = decode(studioDir.appendingPathComponent("st-config.json"))
            else { return nil }

            let customers = loadCustomers(from: studioDir, root: root)
            let (chars, locs) = loadAssets(from: studioDir, level: .studio)

            return MockStudio(
                id: sc.id,
                name: sc.name,
                rules: sc.rules,
                preferredLookID: sc.preferredLookID,
                customers: customers,
                characters: chars,
                locations: locs
            )
        }
    }

    // MARK: - Customers

    private func loadCustomers(from studioDir: URL, root: URL) -> [MockCustomer] {
        return subdirectories(of: studioDir).compactMap { custDir in
            guard let cc: CustomerConfig = decode(custDir.appendingPathComponent("cu-config.json"))
            else { return nil }

            let episodes = loadEpisodes(from: root, customerConfig: cc)
            let (chars, locs) = loadAssets(from: custDir, level: .customer)

            return MockCustomer(
                id: cc.id,
                name: cc.name,
                rules: cc.rules,
                preferredLookID: cc.preferredLookID,
                episodes: episodes,
                characters: chars,
                locations: locs
            )
        }
    }

    // MARK: - Episodes
    //
    // Episodes live directly under root (not inside library/).
    // We match them by the characterIDs / locationIDs in the customer's config.

    private func loadEpisodes(from root: URL, customerConfig: CustomerConfig) -> [MockEpisode] {
        // Scan all episode folders (those containing ep-config.json)
        let episodeDirs = subdirectories(of: root).filter { dir in
            fm.fileExists(atPath: dir.appendingPathComponent("ep-config.json").path)
        }
        return episodeDirs.compactMap { epDir in
            guard let ec: EpisodeConfig = decode(epDir.appendingPathComponent("ep-config.json"))
            else { return nil }

            // Only load episodes whose assets reference this customer's assets
            // (simple heuristic: any ep whose char/loc IDs overlap with customer's)
            // For now we load all episodes — proper parent-linking comes with persistence.
            let (chars, locs) = loadEpisodeAssets(from: epDir, config: ec)
            let acts = loadActs(from: epDir)

            return MockEpisode(
                id: ec.id,
                name: ec.name,
                rules: ec.rules,
                preferredLookID: ec.preferredLookID,
                characters: chars,
                locations: locs,
                acts: acts
            )
        }
    }

    // MARK: - Assets at library level (studio / customer)

    private func loadAssets(from dir: URL, level: LibraryLevel) -> ([CastingItem], [CastingItem]) {
        var chars: [CastingItem] = []
        var locs:  [CastingItem] = []

        for sub in subdirectories(of: dir) {
            let folderName = sub.lastPathComponent
            guard let ac: AssetConfig = decode(sub.appendingPathComponent("as-config.json"))
            else { continue }

            let item = buildCastingItem(from: ac, level: level)
            if folderName.hasPrefix("ch-") {
                chars.append(item)
            } else if folderName.hasPrefix("lo-") {
                locs.append(item)
            }
        }
        return (chars, locs)
    }

    // MARK: - Assets at episode level (referenced by IDs in ep-config)

    private func loadEpisodeAssets(from epDir: URL,
                                   config: EpisodeConfig) -> ([CastingItem], [CastingItem]) {
        // Episode assets are stored inside the customer folder.
        // For now we collect any as-config.json files inside the episode folder itself.
        var chars: [CastingItem] = []
        var locs:  [CastingItem] = []
        for sub in subdirectories(of: epDir) {
            let folderName = sub.lastPathComponent
            guard let ac: AssetConfig = decode(sub.appendingPathComponent("as-config.json"))
            else { continue }
            let item = buildCastingItem(from: ac, level: .episode)
            if folderName.hasPrefix("ch-") {
                chars.append(item)
            } else if folderName.hasPrefix("lo-") {
                locs.append(item)
            }
        }
        return (chars, locs)
    }

    private func buildCastingItem(from ac: AssetConfig, level: LibraryLevel) -> CastingItem {
        let gender: CharacterGender? = ac.gender.flatMap { CharacterGender(rawValue: $0) }
        let setting: LocationSetting? = ac.locationSetting.flatMap { LocationSetting(rawValue: $0) }
        let variants = ac.variants.map { v in
            Variant(id: v.id, label: v.label,
                    isApproved: v.isApproved, isGenerated: v.isGenerated)
        }
        return CastingItem(
            id: ac.id, name: ac.name, description: ac.description,
            type: ac.assetType == "location" ? .location : .character,
            gender: gender, locationSetting: setting,
            libraryLevel: level, variants: variants
        )
    }

    // MARK: - Storyboard (Acts → Sequences → Scenes → Panels)

    private func loadActs(from epDir: URL) -> [MockAct] {
        return subdirectories(of: epDir)
            .filter { isActDir($0) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { actDir in
                let sequences = loadSequences(from: actDir)
                return MockAct(
                    id: actDir.lastPathComponent,
                    name: actDir.lastPathComponent,
                    description: "",
                    sequences: sequences
                )
            }
    }

    private func loadSequences(from actDir: URL) -> [MockSequence] {
        return subdirectories(of: actDir)
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { seqDir in
                let scenes = loadScenes(from: seqDir)
                return MockSequence(
                    id: seqDir.lastPathComponent,
                    name: seqDir.lastPathComponent,
                    description: "",
                    scenes: scenes
                )
            }
    }

    private func loadScenes(from seqDir: URL) -> [MockScene] {
        return subdirectories(of: seqDir)
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { sceneDir in
                let panels = loadPanels(from: sceneDir)
                return MockScene(
                    id: sceneDir.lastPathComponent,
                    name: sceneDir.lastPathComponent,
                    description: "",
                    panels: panels
                )
            }
    }

    private func loadPanels(from sceneDir: URL) -> [MockPanel] {
        return subdirectories(of: sceneDir)
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { panelDir in
                guard let pc: PanelConfig = decode(panelDir.appendingPathComponent("pa-config.json"))
                else { return nil }
                return MockPanel(
                    id: pc.id,
                    name: pc.name,
                    description: pc.description,
                    smallPanelAvailable: pc.smallPanelAvailable,
                    largePanelAvailable: pc.largePanelAvailable,
                    attachedAssetIDs: pc.attachedAssetIDs
                )
            }
    }

    // Act dirs are direct subdirs of the episode folder that don't contain
    // ep-config.json themselves (so we don't mistake nested episode dirs).
    private func isActDir(_ url: URL) -> Bool {
        let name = url.lastPathComponent
        // Skip hidden, skip asset folders (ch-/lo-), skip catalog files
        return !name.hasPrefix(".") &&
               !name.hasPrefix("ch-") &&
               !name.hasPrefix("lo-") &&
               !fm.fileExists(atPath: url.appendingPathComponent("ep-config.json").path)
    }

    // MARK: - File system helpers

    private func subdirectories(of url: URL) -> [URL] {
        guard let contents = try? fm.contentsOfDirectory(
            at: url, includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
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
