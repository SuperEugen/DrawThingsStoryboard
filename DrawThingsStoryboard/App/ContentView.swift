import SwiftUI

/// Root layout: three-pane NavigationSplitView.
/// #84: Clear Done empties production-log.json via callback
/// #85: Average gen times written back to models.json
/// #86: Per-variant seeds stored in AssetVariant + production log
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
                generationQueue: $generationQueue,
                config: config,
                assets: assets,
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
                pushoverConfigured: pushoverConfigured,
                onClearProductionLog: {
                    productionLog = ProductionLogFile(generatedImages: [])
                    StorageLoadService.shared.saveProductionLog(productionLog)
                }
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
                doneQueue: doneQueue,
                productionLog: productionLog,
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
    /// #85: Updates model default gen times from production log averages
    /// #86: Stores per-variant seeds from QueueRunner

    private func handleJobCompleted(_ job: GenerationJob) {
        var done = job
        done.completedAt = Date()
        doneQueue.insert(done, at: 0)
        generationQueue.removeAll { $0.id == job.id }

        let isoFormatter = ISO8601DateFormatter()

        // #86: Collect per-image seeds from QueueRunner
        let seeds = queueRunner.perImageSeeds

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
            // #86: Use per-image seed if available
            let imageSeed = i < seeds.count ? seeds[i] : job.seed
            let entry = GeneratedImageEntry(
                imageID: imgID,
                type: job.jobType.rawValue,
                modelID: job.modelID,
                styleID: job.styleID,
                startTime: startStr,
                endTime: endStr,
                size: job.size.rawValue,
                seed: imageSeed,
                combinedPrompt: job.combinedPrompt
            )
            productionLog.generatedImages.append(entry)
        }
        StorageLoadService.shared.saveProductionLog(productionLog)

        // #85: Update model default gen times from production log averages (last 3)
        updateModelGenTimes(modelID: job.modelID, size: job.size)

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
                    // #86: Store per-variant seeds from QueueRunner
                    for (imgIdx, imgID) in job.savedImageIDs.enumerated() {
                        guard sv.variants.count < 4 else { break }
                        let variantSeed = imgIdx < seeds.count ? seeds[imgIdx] : SeedHelper.randomSeed()
                        sv.variants.append(AssetVariant(smallImageID: imgID, seed: variantSeed, isApproved: false))
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

    // MARK: - #85: Update model gen times from production log

    private func updateModelGenTimes(modelID: String, size: GenerationSize) {
        guard let modelIdx = models.models.firstIndex(where: { $0.modelID == modelID }) else { return }
        let sizeStr = size.rawValue
        let isoFormatter = ISO8601DateFormatter()
        let matching = productionLog.generatedImages.filter { entry in
            entry.modelID == modelID && entry.size == sizeStr
                && !entry.startTime.isEmpty && !entry.endTime.isEmpty
        }
        let recent = Array(matching.suffix(3))
        guard !recent.isEmpty else { return }
        let totalDuration = recent.reduce(0.0) { acc, entry in
            guard let start = isoFormatter.date(from: entry.startTime),
                  let end = isoFormatter.date(from: entry.endTime) else { return acc }
            return acc + end.timeIntervalSince(start)
        }
        let avg = Int(totalDuration / Double(recent.count))
        if size == .small {
            models.models[modelIdx].defaultGenTimeSmall = avg
        } else {
            models.models[modelIdx].defaultGenTimeLarge = avg
        }
        StorageLoadService.shared.saveModels(models)
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
