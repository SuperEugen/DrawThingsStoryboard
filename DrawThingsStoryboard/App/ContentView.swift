import SwiftUI

/// Root layout: three-pane NavigationSplitView.
/// #45: Storyboard picker wiring
/// #48: Asset style picker wiring
struct ContentView: View {

    // MARK: - Navigation
    @State private var selectedSection: AppSection? = .storyboard

    // MARK: - Data state
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
    /// #48: Style used for asset generation (independent of storyboard style).
    @State private var assetStyleID: String = ""

    // MARK: - Production Queue
    @State private var generationQueue: [GenerationJob] = []
    @State private var doneQueue: [GenerationJob] = []

    // MARK: - Queue Runner
    @StateObject private var queueRunner = QueueRunnerService()

    // MARK: - Helpers

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

    private var currentStyleIDBinding: Binding<String> {
        guard storyboards.storyboards.indices.contains(selectedStoryboardIndex) else {
            return .constant("")
        }
        return $storyboards.storyboards[selectedStoryboardIndex].styleID
    }

    private var resolvedStyleName: String? {
        guard let sb = currentStoryboard else { return nil }
        return styles.styles.first { $0.styleID == sb.styleID }?.name
    }

    private var resolvedStyleDescription: String {
        guard let sb = currentStoryboard else { return "" }
        return styles.styles.first { $0.styleID == sb.styleID }?.style ?? ""
    }

    /// #48: Resolved style description for asset generation.
    private var resolvedAssetStyleDescription: String {
        styles.styles.first { $0.styleID == assetStyleID }?.style ?? ""
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
        .onChange(of: generationQueue.count) { _, _ in
            triggerQueueRunner()
        }
        .onChange(of: queueRunner.isRunning) { _, running in
            if !running { triggerQueueRunner() }
        }
        .onChange(of: storyboards) { _, _ in
            StorageLoadService.shared.saveStoryboards(storyboards)
        }
        .frame(minWidth: 1100, minHeight: 680)
        .navigationTitle(windowTitle)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                ConnectionStatusView(
                    address: config.grpcAddress,
                    port: config.grpcPort
                )
            }
        }
        .onAppear {
            loadFromDisk()
            queueRunner.configure { completedJob in
                handleJobCompleted(completedJob)
            }
        }
    }

    // MARK: - Queue runner trigger

    private func triggerQueueRunner() {
        queueRunner.queueDidChange(
            queue: generationQueue,
            config: config,
            models: models,
            selectedModelID: selectedModelID
        )
    }

    // MARK: - Content pane

    @ViewBuilder
    private var contentPane: some View {
        switch selectedSection {
        case .storyboard:
            StoryboardBrowserView(
                storyboards: $storyboards,
                selectedStoryboardIndex: $selectedStoryboardIndex,
                selection: $storyboardSelection,
                styles: styles,
                currentStyleID: currentStyleIDBinding,
                onFountainImport: { importedActs, name in
                    handleFountainImport(acts: importedActs, name: name)
                }
            )
        case .assets:
            AssetsBrowserView(
                assets: $assets,
                selectedAssetID: $selectedAssetID,
                generationQueue: $generationQueue,
                config: config,
                styles: styles,
                assetStyleID: $assetStyleID
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
                selectedModelID: $selectedModelID,
                queueRunner: queueRunner,
                productionLog: productionLog
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
                config: config,
                assetStyleDescription: resolvedAssetStyleDescription
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
                queueRunner: queueRunner
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

    // MARK: - Fountain import

    private func handleFountainImport(acts: [ActEntry], name: String) {
        if storyboards.storyboards.indices.contains(selectedStoryboardIndex) {
            storyboards.storyboards[selectedStoryboardIndex].acts = acts
            storyboards.storyboards[selectedStoryboardIndex].name = name
        } else {
            let modelID = models.models.first?.modelID ?? "M1"
            let styleID = styles.styles.first?.styleID ?? "S1"
            let sb = StoryboardEntry(name: name, acts: acts, modelID: modelID, styleID: styleID)
            storyboards.storyboards.append(sb)
            selectedStoryboardIndex = storyboards.storyboards.count - 1
        }
        StorageLoadService.shared.saveStoryboards(storyboards)
        storyboardSelection = nil
    }

    // MARK: - Job completion

    private func handleJobCompleted(_ job: GenerationJob) {
        var done = job
        done.completedAt = Date()
        doneQueue.insert(done, at: 0)
        generationQueue.removeAll { $0.id == job.id }

        let isoFormatter = ISO8601DateFormatter()
        let startTimeStr = job.startedAt.map { isoFormatter.string(from: $0) } ?? ""
        let endTimeStr = isoFormatter.string(from: done.completedAt ?? Date())
        let resolvedModelID = selectedModelID ?? models.models.first?.modelID ?? ""
        let resolvedStyleID: String = {
            if !job.styleID.isEmpty { return job.styleID }
            if let sb = currentStoryboard { return sb.styleID }
            return ""
        }()

        for imgID in job.savedImageIDs {
            let entry = GeneratedImageEntry(
                imageID: imgID,
                type: job.jobType.rawValue,
                modelID: resolvedModelID,
                styleID: resolvedStyleID,
                startTime: startTimeStr,
                endTime: endTimeStr,
                size: job.size.rawValue,
                seed: job.seed,
                combinedPrompt: job.combinedPrompt
            )
            productionLog.generatedImages.append(entry)
        }
        StorageLoadService.shared.saveProductionLog(productionLog)

        guard let firstImageID = job.savedImageIDs.first else { return }

        switch job.jobType {
        case .generateStyle:
            if let idx = styles.styles.firstIndex(where: { $0.styleID == job.styleID }) {
                styles.styles[idx].smallImageID = firstImageID
                styles.styles[idx].isGenerated = true
                StorageLoadService.shared.saveStyles(styles)
            }

        case .generateAsset:
            if let idx = assets.assets.firstIndex(where: { $0.assetID == job.assetID }) {
                if job.size == .large {
                    assets.assets[idx].largeImageID = firstImageID
                } else {
                    let imageIDs = job.savedImageIDs
                    var filled = 0
                    for imgID in imageIDs {
                        for vi in 0..<4 {
                            let existing = assets.assets[idx].variant(at: vi)
                            if !existing.hasImage {
                                let effectiveSeed = job.seed == 0 ? SeedHelper.randomSeed() : job.seed + filled
                                let newVariant = AssetVariant(
                                    smallImageID: imgID,
                                    seed: effectiveSeed,
                                    isApproved: false
                                )
                                assets.assets[idx].setVariant(at: vi, newVariant)
                                filled += 1
                                break
                            }
                        }
                    }
                }
                StorageLoadService.shared.saveAssets(assets)
            }

        case .generatePanel:
            for si in storyboards.storyboards.indices {
                for ai in storyboards.storyboards[si].acts.indices {
                    for seqi in storyboards.storyboards[si].acts[ai].sequences.indices {
                        for sci in storyboards.storyboards[si].acts[ai].sequences[seqi].scenes.indices {
                            for pi in storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].panels.indices {
                                let panel = storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].panels[pi]
                                if panel.panelID == job.panelID {
                                    if job.size == .large {
                                        storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].panels[pi].largeImageID = firstImageID
                                    } else {
                                        storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].panels[pi].smallImageID = firstImageID
                                    }
                                    StorageLoadService.shared.saveStoryboards(storyboards)
                                    return
                                }
                            }
                        }
                    }
                }
            }
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
        // #48: Default asset style to first style or current storyboard's style
        if assetStyleID.isEmpty {
            if let sb = storyboards.storyboards.first,
               styles.styles.contains(where: { $0.styleID == sb.styleID }) {
                assetStyleID = sb.styleID
            } else {
                assetStyleID = styles.styles.first?.styleID ?? ""
            }
        }
    }
}

#Preview {
    ContentView()
}
