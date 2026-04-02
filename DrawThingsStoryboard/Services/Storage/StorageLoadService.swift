import Foundation

// MARK: - StorageLoadService

final class StorageLoadService {

    static let shared = StorageLoadService()
    private init() {}

    // MARK: - AppState

    struct AppState {
        var config: AppConfig
        var models: ModelsFile
        var styles: StylesFile
        var storyboards: StoryboardsFile
        var assets: AssetsFile
        var productionLog: ProductionLogFile
    }

    func load() -> AppState {
        let s = StorageService.shared
        return AppState(
            config:        s.read(s.configURL)        ?? AppConfig(),
            models:        s.read(s.modelsURL)        ?? ModelsFile(models: []),
            styles:        s.read(s.stylesURL)        ?? StylesFile(styles: []),
            storyboards:   s.read(s.storyboardsURL)   ?? StoryboardsFile(storyboards: []),
            assets:        s.read(s.assetsURL)        ?? AssetsFile(assets: []),
            productionLog: s.read(s.productionLogURL) ?? ProductionLogFile(generatedImages: [])
        )
    }

    // MARK: - Individual save helpers

    func saveConfig(_ config: AppConfig) {
        let s = StorageService.shared
        s.write(config, to: s.configURL)
    }

    func saveModels(_ models: ModelsFile) {
        let s = StorageService.shared
        s.write(models, to: s.modelsURL)
    }

    func saveStyles(_ styles: StylesFile) {
        let s = StorageService.shared
        s.write(styles, to: s.stylesURL)
    }

    func saveStoryboards(_ storyboards: StoryboardsFile) {
        let s = StorageService.shared
        s.write(storyboards, to: s.storyboardsURL)
    }

    func saveAssets(_ assets: AssetsFile) {
        let s = StorageService.shared
        s.write(assets, to: s.assetsURL)
    }

    func saveProductionLog(_ log: ProductionLogFile) {
        let s = StorageService.shared
        s.write(log, to: s.productionLogURL)
    }
}
