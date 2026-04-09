import Foundation

// MARK: - StorageSetupService

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

        // models.json — #51: sampler + isImg2ImgCapable; #56: renamed F2K KV + new ZIB model
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
                defaultGenTimeSmall: 360,
                defaultGenTimeLarge: 900,
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
            ),
            StyleEntry(
                styleID: "S2",
                name: "Comic Style",
                style: "Illustration in 2-d flat color art style. Highly stylised with very low detail and no textures, simplified. Minimalistic background."
            ),
            StyleEntry(
                styleID: "S3",
                name: "Sketch",
                style: "A rough hand-drawn sketch from a 1950s cartoon, very sketchy. Mainly rough outlines with shadows in charcoal. Very minimalistic, very loose, very few details. Few colors, UPA style. No signing on the drawing."
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
                styleID: "S2"
            )
        ])
        storage.write(storyboards, to: storage.storyboardsURL)

        // assets.json
        let assets = AssetsFile(assets: [
            AssetEntry(assetID: "A1", name: "SuperEugen", type: "character", subType: "male",
                       description: "A 60yo man with a slight belly and a prominent chin wearing black glasses with a thick frame."),
            AssetEntry(assetID: "A2", name: "Michael", type: "character", subType: "male",
                       description: "A 65yo man with a bald head wearing glasses with a thin frame."),
            AssetEntry(assetID: "A3", name: "Olli", type: "character", subType: "male",
                       description: "A 40yo sportive man."),
            AssetEntry(assetID: "A4", name: "Sylli", type: "character", subType: "female",
                       description: "A 55yo sportive slim woman with a ponytail."),
            AssetEntry(assetID: "A5", name: "SuperEugen's apartment", type: "location", subType: "interior",
                       description: "Attic apartment with slope walls a round window and a red brick church outside."),
            AssetEntry(assetID: "A6", name: "Park", type: "location", subType: "exterior",
                       description: "A small park with a basketball court and a red brick church in the background."),
            AssetEntry(assetID: "A7", name: "Restaurant", type: "location", subType: "interior",
                       description: "A restaurant with a bar in the middle of the room and floor to ceiling windows on street level."),
            AssetEntry(assetID: "A8", name: "Staircase", type: "location", subType: "interior",
                       description: "A staircase in an old Berlin building.")
        ])
        storage.write(assets, to: storage.assetsURL)

        // production-log.json
        let log = ProductionLogFile(generatedImages: [])
        storage.write(log, to: storage.productionLogURL)
    }
}
