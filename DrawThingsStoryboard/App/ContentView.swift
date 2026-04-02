import SwiftUI

/// Root layout: three-pane NavigationSplitView.
/// State is loaded from disk via StorageLoadService on appear.
struct ContentView: View {

    // MARK: - Navigation
    @State private var selectedSection: AppSection? = .storyboard

    // MARK: - Data state (loaded from JSON files)
    @State private var config: AppConfig = AppConfig()
    @State private var models: ModelsFile = ModelsFile(models: [])
    @State private var styles: StylesFile = StylesFile(styles: [])
    @State private var storyboards: StoryboardsFile = StoryboardsFile(storyboards: [])
    @State private var assets: AssetsFile = AssetsFile(assets: [])
    @State private var productionLog: ProductionLogFile = ProductionLogFile(generatedImages: [])

    // MARK: - Selection state
    @State private var selectedStoryboardIndex: Int = 0
    @State private var selectedStyleID: String? = nil
    @State private var selectedModelID: String? = nil
    @State private var selectedAssetID: String? = nil
    @State private var selectedJobID: String? = nil
    @State private var storyboardSelection: StoryboardSelection? = nil

    // MARK: - Production Queue
    @State private var generationQueue: [GenerationJob] = []
    @State private var doneQueue: [GenerationJob] = []

    // MARK: - Current storyboard helpers

    private var currentStoryboard: StoryboardEntry? {
        guard storyboards.storyboards.indices.contains(selectedStoryboardIndex) else { return nil }
        return storyboards.storyboards[selectedStoryboardIndex]
    }

    private var currentActsBinding: Binding<[ActEntry]> {
        guard storyboards.storyboards.indices.contains(selectedStoryboardIndex) else {
            return .constant([])
        }
        return $storyboards.storyboards[selectedStoryboardIndex].acts
    }

    private var resolvedStyleName: String? {
        guard let sb = currentStoryboard else { return nil }
        return styles.styles.first { $0.styleID == sb.styleID }?.name
    }

    private var resolvedStyleDescription: String {
        guard let sb = currentStoryboard else { return "" }
        return styles.styles.first { $0.styleID == sb.styleID }?.style ?? ""
    }

    private var windowTitle: String {
        if let sb = currentStoryboard {
            return "Draw Things Storyboard \u{2014} \(sb.name)"
        }
        return "Draw Things Storyboard"
    }

    // MARK: - Body

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedSection: $selectedSection)
        } content: {
            contentPane
        } detail: {
            detailPane
        }
        .onChange(of: selectedSection) { _, _ in
            clearSelections()
        }
        .frame(minWidth: 1100, minHeight: 680)
        .navigationTitle(windowTitle)
        .onAppear {
            loadFromDisk()
        }
    }

    // MARK: - Content pane

    @ViewBuilder
    private var contentPane: some View {
        switch selectedSection {
        case .storyboard:
            StoryboardBrowserView(
                acts: currentActsBinding,
                selection: $storyboardSelection,
                styleName: Binding(
                    get: { resolvedStyleName },
                    set: { _ in }
                )
            )
        case .assets:
            AssetsBrowserView(
                assets: $assets,
                selectedAssetID: $selectedAssetID
            )
        case .styles:
            StylesBrowserView(
                styles: $styles,
                selectedStyleID: $selectedStyleID,
                generationQueue: $generationQueue,
                config: config
            )
        case .models:
            ModelsBrowserView(
                models: $models,
                selectedModelID: $selectedModelID
            )
        case .productionQueue:
            ProductionBrowserView(
                queue: $generationQueue,
                selectedJobID: $selectedJobID,
                doneQueue: $doneQueue,
                models: $models,
                selectedModelID: $selectedModelID
            )
        case .settings:
            SettingsContentView(config: $config)
        default:
            Text("Select a section")
        }
    }

    // MARK: - Detail pane

    @ViewBuilder
    private var detailPane: some View {
        switch selectedSection {
        case .storyboard:
            StoryboardDetailView(
                acts: currentActsBinding,
                selection: storyboardSelection,
                generationQueue: $generationQueue,
                assets: assets,
                resolvedStyleName: resolvedStyleName,
                styleDescription: resolvedStyleDescription,
                config: config
            )
        case .assets:
            AssetsDetailView(
                assets: $assets,
                selectedAssetID: selectedAssetID,
                generationQueue: $generationQueue,
                config: config
            )
        case .styles:
            StylesDetailView(
                styles: $styles,
                selectedStyleID: $selectedStyleID,
                generationQueue: $generationQueue,
                config: config
            )
        case .models:
            ModelsDetailView(
                models: $models,
                selectedModelID: $selectedModelID
            )
        case .productionQueue:
            ProductionJobDetailView(
                queue: generationQueue,
                selectedJobID: selectedJobID,
                models: models,
                selectedModelID: selectedModelID,
                config: config,
                assets: assets,
                onJobCompleted: { completedJob in
                    handleJobCompleted(completedJob)
                }
            )
        case .settings:
            EmptyView()
        default:
            ContentUnavailableView(
                "Nothing selected",
                systemImage: "square.dashed",
                description: Text("Select a section from the sidebar.")
            )
        }
    }

    // MARK: - Job completion handler

    private func handleJobCompleted(_ job: GenerationJob) {
        var done = job
        done.completedAt = Date()
        doneQueue.insert(done, at: 0)
        generationQueue.removeAll { $0.id == job.id }

        guard let firstImageID = job.savedImageIDs.first else { return }

        switch job.jobType {
        case .generateStyle:
            if let idx = styles.styles.firstIndex(where: { $0.styleID == job.styleID }) {
                styles.styles[idx].smallImageID = firstImageID
                styles.styles[idx].isGenerated = true
                StorageLoadService.shared.saveStyles(styles)
            }

        case .generateAsset:
            // TODO: write image UUIDs back into asset variants
            break

        case .generatePanel:
            // TODO: write image UUID back into panel
            break
        }
    }

    // MARK: - Helpers

    private func clearSelections() {
        selectedAssetID = nil
        selectedStyleID = nil
        selectedModelID = nil
        selectedJobID = nil
        storyboardSelection = nil
    }

    private func loadFromDisk() {
        let state = StorageLoadService.shared.load()
        config = state.config
        models = state.models
        styles = state.styles
        storyboards = state.storyboards
        assets = state.assets
        productionLog = state.productionLog

        if selectedStyleID == nil { selectedStyleID = styles.styles.first?.styleID }
        if selectedModelID == nil { selectedModelID = models.models.first?.modelID }
        if selectedAssetID == nil { selectedAssetID = assets.assets.first?.assetID }
    }
}

#Preview {
    ContentView()
}
