import Foundation

// MARK: - StorageSetupService
/// #57: Demo assets use new styleVariants structure (no pre-generated variants)
/// #77: ZIB default gen times updated to 380/1500

final class StorageSetupService {

    static let shared = StorageSetupService()
    private init() {}

    func setupIfNeeded() {
        let storage = StorageService.shared
        guard !FileManager.default.fileExists(atPath: storage.configURL.path) else { return }
        do {
            try storage.ensureRootExists()
            createDefaultFiles(storage: storage)
            print("[StorageSetupService] First-launch structure created at \(storage.rootURL.path)")
        } catch {
            print("[StorageSetupService] Setup failed: \(error)")
        }
    }

    private func createDefaultFiles(storage: StorageService) {

        // config.json
        let config = AppConfig()
        storage.write(config, to: storage.configURL)

        // models.json
        let models = ModelsFile(models: [
            ModelEntry(
                modelID: "M1",
                name: "F2K KV",
                guidanceScale: 1,
                model: "flux_2_klein_9b_kv_q8p.ckpt",
                steps: 6,
                defaultGenTimeSmall: 60,
                defaultGenTimeLarge: 180,
                sampler: "UniPC Trailing",
                isImg2ImgCapable: true
            ),
            ModelEntry(
                modelID: "M2",
                name: "ZIB",
                guidanceScale: 4,
                model: "z_image_1.0_q8p.ckpt",
                steps: 35,
                defaultGenTimeSmall: 380,
                defaultGenTimeLarge: 1500,
                sampler: "UniPC Trailing",
                isImg2ImgCapable: false
            )
        ])
        storage.write(models, to: storage.modelsURL)

        // styles.json
        let styles = StylesFile(styles: [
            StyleEntry(
                styleID: "S1",
                name: "Photorealistic",
                style: "Photorealistic, cinematic lighting, 8k resolution, dramatic shadows."
            )
        ])
        storage.write(styles, to: storage.stylesURL)

        // storyboards.json
        let storyboards = StoryboardsFile(storyboards: [
            StoryboardEntry(
                name: "My Storyboard",
                acts: [
                    ActEntry(name: "Act 1", sequences: [
                        SequenceEntry(name: "Sequence 1", scenes: [
                            SceneEntry(name: "Scene 1", panels: [
                                PanelEntry(
                                    panelID: "P1",
                                    name: "My panel",
                                    description: "Describe your panel here.",
                                    duration: 30
                                )
                            ])
                        ])
                    ])
                ],
                modelID: "M1",
                styleID: "S1"
            )
        ])
        storage.write(storyboards, to: storage.storyboardsURL)

        // assets.json — empty by default, import via Assets view
        let assets = AssetsFile(assets: [])
        storage.write(assets, to: storage.assetsURL)

        // production-log.json
        let log = ProductionLogFile(generatedImages: [])
        storage.write(log, to: storage.productionLogURL)
    }
}
