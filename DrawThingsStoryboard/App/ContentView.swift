import SwiftUI

/// Root layout: three-pane NavigationSplitView.
struct ContentView: View {

    // MARK: - Navigation
    @State private var selectedSection: AppSection? = .models

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
    @State private var assetStyleID: String = ""
    @State private var assetModelID: String = ""
    @State private var stylesModelID: String = ""

    // MARK: - Production Queue
    @State private var generationQueue: [GenerationJob] = []
    @State private var doneQueue: [GenerationJob] = []
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false

    // MARK: - Queue Runner
    @StateObject private var queueRunner = QueueRunnerService()

    // MARK: - Helpers

    private var pushoverConfigured: Bool {
        !config.pushoverToken.isEmpty && !config.pushoverUser.isEmpty
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
        .onChange(of: notificationsEnabled) { _, enabled in
            queueRunner.notificationsEnabled = enabled
        }
        .frame(minWidth: 1100, minHeight: 680)
        .navigationTitle("Draw Things Storyboard")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                QueueStatusToolbarView(
                    queue: generationQueue,
                    queueRunner: queueRunner,
                    productionLog: productionLog,
                    models: models
                )
            }
            ToolbarItem(placement: .automatic) {
                ConnectionStatusView(
                    address: config.grpcAddress,
                    port: config.grpcPort
                )
            }
        }
        .onAppear {
            loadFromDisk()
            queueRunner.notificationsEnabled = notificationsEnabled
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
                models: models,
                styles: styles,
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
                assetStyleID: $assetStyleID,
                models: models,
                assetModelID: $assetModelID
            )
        case .styles:
            StylesBrowserView(
                styles: $styles,
                selectedStyleID: $selectedStyleID,
                generationQueue: $generationQueue,
                config: config,
                models: models,
                stylesModelID: $stylesModelID
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
                models: models,
                queueRunner: queueRunner,
                productionLog: productionLog,
                notificationsEnabled: $notificationsEnabled,
                pushoverConfigured: pushoverConfigured
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
                storyboards: $storyboards,
                selectedStoryboardIndex: selectedStoryboardIndex,
                selection: storyboardSelection,
                generationQueue: $generationQueue,
                assets: assets,
                styles: styles,
                models: models,
                config: config
            )
        case .assets:
            AssetsDetailView(
                assets: $assets,
                selectedAssetID: selectedAssetID,
                generationQueue: $generationQueue,
                config: config,
                styles: styles,
                assetModelID: assetModelID
            )
        case .styles:
            StylesDetailView(
                styles: $styles,
                selectedStyleID: $selectedStyleID,
                generationQueue: $generationQueue,
                config: config,
                stylesModelID: stylesModelID
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

        for (i, imgID) in job.savedImageIDs.enumerated() {
            let startStr: String
            let endStr: String
            if i < queueRunner.perImageStartTimes.count && i < queueRunner.perImageEndTimes.count {
                startStr = isoFormatter.string(from: queueRunner.perImageStartTimes[i])
                endStr = isoFormatter.string(from: queueRunner.perImageEndTimes[i])
            } else {
                startStr = job.startedAt.map { isoFormatter.string(from: $0) } ?? ""
                endStr = isoFormatter.string(from: done.completedAt ?? Date())
            }
            let entry = GeneratedImageEntry(
                imageID: imgID,
                type: job.jobType.rawValue,
                modelID: job.modelID,
                styleID: job.styleID,
                startTime: startStr,
                endTime: endStr,
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
                var sv = assets.assets[idx].variantsFor(style: job.styleID)
                if job.size == .large {
                    sv.largeImageID = firstImageID
                } else {
                    for imgID in job.savedImageIDs {
                        guard sv.variants.count < 4 else { break }
                        let effectiveSeed = job.seed == 0 ? SeedHelper.randomSeed() : job.seed + sv.variants.count
                        sv.variants.append(AssetVariant(smallImageID: imgID, seed: effectiveSeed, isApproved: false))
                    }
                }
                assets.assets[idx].styleVariants[job.styleID] = sv
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
        if assetStyleID.isEmpty {
            if let sb = storyboards.storyboards.first,
               styles.styles.contains(where: { $0.styleID == sb.styleID }) {
                assetStyleID = sb.styleID
            } else {
                assetStyleID = styles.styles.first?.styleID ?? ""
            }
        }
        if assetModelID.isEmpty {
            if let sb = storyboards.storyboards.first,
               models.models.contains(where: { $0.modelID == sb.modelID }) {
                assetModelID = sb.modelID
            } else {
                assetModelID = models.models.first?.modelID ?? ""
            }
        }
        if stylesModelID.isEmpty {
            stylesModelID = models.models.first?.modelID ?? ""
        }
    }
}

#Preview {
    ContentView()
}
