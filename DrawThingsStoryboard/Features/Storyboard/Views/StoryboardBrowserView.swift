import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Storyboard selection
/// Storyboard-level selection added so clicking a storyboard row shows its settings in detail.

enum StoryboardSelection: Hashable {
    case storyboard(Int)
    case act(Int, Int)             // storyboardIndex, actIndex
    case sequence(Int, Int, Int)   // storyboardIndex, actIndex, seqIndex
    case scene(Int, Int, Int, Int) // storyboardIndex, actIndex, seqIndex, sceneIndex
    case panel(String)             // panelID (globally unique)
}

// MARK: - StoryboardBrowserView
/// #89: Action menu (Generate/Add/Arrange/Export) replaces context menus; x-buttons for deletion
/// #90: Fountain import moved into Import group in action menu

struct StoryboardBrowserView: View {

    @Binding var storyboards: StoryboardsFile
    @Binding var selectedStoryboardIndex: Int
    @Binding var selection: StoryboardSelection?
    let models: ModelsFile
    let styles: StylesFile
    @Binding var generationQueue: [GenerationJob]
    let config: AppConfig
    let assets: AssetsFile
    var onFountainImport: (([ActEntry], String) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            actionMenuBar
            Divider()

            if storyboards.storyboards.isEmpty {
                Spacer()
                ContentUnavailableView("No storyboards yet", systemImage: "film.stack",
                    description: Text("Add a storyboard or import a Fountain file."))
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(storyboards.storyboards.indices, id: \.self) { si in
                            StoryboardRow(
                                storyboard: $storyboards.storyboards[si],
                                storyboardIndex: si,
                                selection: $selection,
                                selectedStoryboardIndex: $selectedStoryboardIndex,
                                models: models,
                                styles: styles,
                                canDelete: storyboards.storyboards.count > 1,
                                onDelete: {
                                    storyboards.storyboards.remove(at: si)
                                    if selectedStoryboardIndex >= storyboards.storyboards.count {
                                        selectedStoryboardIndex = max(0, storyboards.storyboards.count - 1)
                                    }
                                    selection = nil
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Header

    @ViewBuilder
    private var headerBar: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "film.stack").font(.title2).foregroundStyle(.secondary)
            Text("Storyboards").font(.title2.bold())
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - Action menu bar

    @ViewBuilder
    private var actionMenuBar: some View {
        HStack(spacing: 12) {
            // GROUP 1: Generate
            GroupBox {
                HStack(spacing: 6) {
                    Button { generateSmall() } label: {
                        Label("(\(smallGeneratedCount))", systemImage: "arrow.down.right.and.arrow.up.left.square")
                            .font(.callout)
                    }
                    .buttonStyle(.bordered).controlSize(.regular)
                    .disabled(!canGenerate)
                    .help("Generate small images for panels without one")

                    Button { generateLarge() } label: {
                        Label("(\(largeGeneratedCount))", systemImage: "arrow.up.left.and.arrow.down.right.rectangle")
                            .font(.callout)
                    }
                    .buttonStyle(.bordered).controlSize(.regular)
                    .disabled(!canGenerate)
                    .help("Generate large images for panels without one")
                }
            } label: {
                Label("Generate", systemImage: "wand.and.sparkles")
                    .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
            }

            // GROUP 2: Add
            GroupBox {
                HStack(spacing: 6) {
                    Button { addStoryboard() } label: {
                        Image(systemName: "film").font(.callout)
                    }
                    .buttonStyle(.bordered).controlSize(.regular)
                    .help("Add Storyboard")

                    Button { addActFromMenu() } label: {
                        Image(systemName: "theatermasks").font(.callout)
                    }
                    .buttonStyle(.bordered).controlSize(.regular)
                    .disabled(!canAddAct)
                    .help("Add Act")

                    Button { addSequenceFromMenu() } label: {
                        Image(systemName: "ellipsis.rectangle").font(.callout)
                    }
                    .buttonStyle(.bordered).controlSize(.regular)
                    .disabled(!canAddSequence)
                    .help("Add Sequence")

                    Button { addSceneFromMenu() } label: {
                        Image(systemName: "photo").font(.callout)
                    }
                    .buttonStyle(.bordered).controlSize(.regular)
                    .disabled(!canAddScene)
                    .help("Add Scene")

                    Button { addPanelFromMenu() } label: {
                        Image(systemName: "list.and.film").font(.callout)
                    }
                    .buttonStyle(.bordered).controlSize(.regular)
                    .disabled(!canAddPanel)
                    .help("Add Panel")
                }
            } label: {
                Label("Add", systemImage: "plus")
                    .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
            }

            // GROUP 3: Arrange
            GroupBox {
                HStack(spacing: 6) {
                    Button { moveUp() } label: {
                        Image(systemName: "arrow.up").font(.callout)
                    }
                    .buttonStyle(.bordered).controlSize(.regular)
                    .disabled(!canMoveUp)
                    .help("Move up")

                    Button { moveDown() } label: {
                        Image(systemName: "arrow.down").font(.callout)
                    }
                    .buttonStyle(.bordered).controlSize(.regular)
                    .disabled(!canMoveDown)
                    .help("Move down")
                }
            } label: {
                Label("Arrange", systemImage: "arrow.up.arrow.down")
                    .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
            }

            // GROUP 4: Export
            GroupBox {
                Button { exportPDF() } label: {
                    Label("(\(panelsInScope.count))", systemImage: "doc").font(.callout)
                }
                .buttonStyle(.bordered).controlSize(.regular)
                .disabled(panelsInScope.isEmpty)
                .help("Export panels to PDF")
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
                    .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
            }

            // GROUP 5: Import
            GroupBox {
                Button { importFountainFile() } label: {
                    Image(systemName: "text.page").font(.callout)
                }
                .buttonStyle(.bordered).controlSize(.regular)
                .help("Import Fountain screenplay (.fountain)")
            } label: {
                Label("Import", systemImage: "square.and.arrow.down")
                    .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 14).padding(.bottom, 10).padding(.top, 6)
    }

    // MARK: - Selection helpers

    private var activeStoryboardIndex: Int {
        switch selection {
        case .storyboard(let si): return si
        case .act(let si, _): return si
        case .sequence(let si, _, _): return si
        case .scene(let si, _, _, _): return si
        case .panel: return selectedStoryboardIndex
        case .none: return selectedStoryboardIndex
        }
    }

    private var activeStoryboard: StoryboardEntry? {
        guard storyboards.storyboards.indices.contains(activeStoryboardIndex) else { return nil }
        return storyboards.storyboards[activeStoryboardIndex]
    }

    private var panelsInScope: [PanelEntry] {
        switch selection {
        case .storyboard(let si):
            guard storyboards.storyboards.indices.contains(si) else { return [] }
            return storyboards.storyboards[si].acts.flatMap { $0.sequences.flatMap { $0.scenes.flatMap { $0.panels } } }
        case .act(let si, let ai):
            guard storyboards.storyboards.indices.contains(si),
                  storyboards.storyboards[si].acts.indices.contains(ai) else { return [] }
            return storyboards.storyboards[si].acts[ai].sequences.flatMap { $0.scenes.flatMap { $0.panels } }
        case .sequence(let si, let ai, let seqi):
            guard storyboards.storyboards.indices.contains(si),
                  storyboards.storyboards[si].acts.indices.contains(ai),
                  storyboards.storyboards[si].acts[ai].sequences.indices.contains(seqi) else { return [] }
            return storyboards.storyboards[si].acts[ai].sequences[seqi].scenes.flatMap { $0.panels }
        case .scene(let si, let ai, let seqi, let sci):
            guard storyboards.storyboards.indices.contains(si),
                  storyboards.storyboards[si].acts.indices.contains(ai),
                  storyboards.storyboards[si].acts[ai].sequences.indices.contains(seqi),
                  storyboards.storyboards[si].acts[ai].sequences[seqi].scenes.indices.contains(sci) else { return [] }
            return storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].panels
        case .panel(let id):
            if let (si, ai, seqi, sci, pi) = findPanel(id) {
                return [storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].panels[pi]]
            }
            return []
        case .none:
            return []
        }
    }

    private var smallGeneratedCount: Int { panelsInScope.filter { $0.hasSmallImage }.count }
    private var largeGeneratedCount: Int { panelsInScope.filter { $0.hasLargeImage }.count }

    private var canGenerate: Bool {
        guard let sb = activeStoryboard, !sb.styleID.isEmpty, !sb.modelID.isEmpty else { return false }
        return !panelsInScope.isEmpty
    }

    // MARK: - Add enabled states

    private var canAddAct: Bool { selection != nil }

    private var canAddSequence: Bool {
        switch selection {
        case .act, .sequence, .scene, .panel: return true
        default: return false
        }
    }

    private var canAddScene: Bool {
        switch selection {
        case .sequence, .scene, .panel: return true
        default: return false
        }
    }

    private var canAddPanel: Bool {
        switch selection {
        case .scene, .panel: return true
        default: return false
        }
    }

    // MARK: - Arrange enabled states

    private var canMoveUp: Bool {
        switch selection {
        case .storyboard(let si): return si > 0
        case .act(_, let ai): return ai > 0
        case .sequence(_, _, let seqi): return seqi > 0
        case .scene(_, _, _, let sci): return sci > 0
        case .panel(let id):
            if let (_, _, _, _, pi) = findPanel(id) { return pi > 0 }
            return false
        case .none: return false
        }
    }

    private var canMoveDown: Bool {
        switch selection {
        case .storyboard(let si):
            return si < storyboards.storyboards.count - 1
        case .act(let si, let ai):
            guard storyboards.storyboards.indices.contains(si) else { return false }
            return ai < storyboards.storyboards[si].acts.count - 1
        case .sequence(let si, let ai, let seqi):
            guard storyboards.storyboards.indices.contains(si),
                  storyboards.storyboards[si].acts.indices.contains(ai) else { return false }
            return seqi < storyboards.storyboards[si].acts[ai].sequences.count - 1
        case .scene(let si, let ai, let seqi, let sci):
            guard storyboards.storyboards.indices.contains(si),
                  storyboards.storyboards[si].acts.indices.contains(ai),
                  storyboards.storyboards[si].acts[ai].sequences.indices.contains(seqi) else { return false }
            return sci < storyboards.storyboards[si].acts[ai].sequences[seqi].scenes.count - 1
        case .panel(let id):
            if let (si, ai, seqi, sci, pi) = findPanel(id) {
                guard storyboards.storyboards.indices.contains(si),
                      storyboards.storyboards[si].acts.indices.contains(ai),
                      storyboards.storyboards[si].acts[ai].sequences.indices.contains(seqi),
                      storyboards.storyboards[si].acts[ai].sequences[seqi].scenes.indices.contains(sci) else { return false }
                return pi < storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].panels.count - 1
            }
            return false
        case .none: return false
        }
    }

    // MARK: - Add actions

    private func addStoryboard() {
        let name = "Storyboard \(storyboards.storyboards.count + 1)"
        let modelID = models.models.first?.modelID ?? "M1"
        let styleID = styles.styles.first?.styleID ?? "S1"
        let panel = PanelEntry(panelID: UUID().uuidString, name: "Panel 1", duration: 30)
        let scene = SceneEntry(name: "Scene 1", panels: [panel])
        let sequence = SequenceEntry(name: "Sequence 1", scenes: [scene])
        let act = ActEntry(name: "Act 1", sequences: [sequence])
        let sb = StoryboardEntry(name: name, acts: [act], modelID: modelID, styleID: styleID)
        storyboards.storyboards.append(sb)
        let newIndex = storyboards.storyboards.count - 1
        selectedStoryboardIndex = newIndex
        selection = .storyboard(newIndex)
    }

    private func addActFromMenu() {
        let si = activeStoryboardIndex
        guard storyboards.storyboards.indices.contains(si) else { return }
        let name = "Act \(storyboards.storyboards[si].acts.count + 1)"
        storyboards.storyboards[si].acts.append(ActEntry(name: name, sequences: []))
        selectedStoryboardIndex = si
        selection = .act(si, storyboards.storyboards[si].acts.count - 1)
    }

    private func addSequenceFromMenu() {
        var si = 0, ai = 0
        switch selection {
        case .act(let s, let a): si = s; ai = a
        case .sequence(let s, let a, _): si = s; ai = a
        case .scene(let s, let a, _, _): si = s; ai = a
        case .panel(let id):
            if let (s, a, _, _, _) = findPanel(id) { si = s; ai = a } else { return }
        default: return
        }
        guard storyboards.storyboards.indices.contains(si),
              storyboards.storyboards[si].acts.indices.contains(ai) else { return }
        let name = "Sequence \(storyboards.storyboards[si].acts[ai].sequences.count + 1)"
        storyboards.storyboards[si].acts[ai].sequences.append(SequenceEntry(name: name, scenes: []))
        selectedStoryboardIndex = si
        selection = .sequence(si, ai, storyboards.storyboards[si].acts[ai].sequences.count - 1)
    }

    private func addSceneFromMenu() {
        var si = 0, ai = 0, seqi = 0
        switch selection {
        case .sequence(let s, let a, let sq): si = s; ai = a; seqi = sq
        case .scene(let s, let a, let sq, _): si = s; ai = a; seqi = sq
        case .panel(let id):
            if let (s, a, sq, _, _) = findPanel(id) { si = s; ai = a; seqi = sq } else { return }
        default: return
        }
        guard storyboards.storyboards.indices.contains(si),
              storyboards.storyboards[si].acts.indices.contains(ai),
              storyboards.storyboards[si].acts[ai].sequences.indices.contains(seqi) else { return }
        let name = "Scene \(storyboards.storyboards[si].acts[ai].sequences[seqi].scenes.count + 1)"
        let panel = PanelEntry(panelID: UUID().uuidString, name: "Panel 1", duration: 30)
        storyboards.storyboards[si].acts[ai].sequences[seqi].scenes.append(SceneEntry(name: name, panels: [panel]))
        selectedStoryboardIndex = si
        let newSci = storyboards.storyboards[si].acts[ai].sequences[seqi].scenes.count - 1
        selection = .scene(si, ai, seqi, newSci)
    }

    private func addPanelFromMenu() {
        var si = 0, ai = 0, seqi = 0, sci = 0
        switch selection {
        case .scene(let s, let a, let sq, let sc): si = s; ai = a; seqi = sq; sci = sc
        case .panel(let id):
            if let (s, a, sq, sc, _) = findPanel(id) { si = s; ai = a; seqi = sq; sci = sc } else { return }
        default: return
        }
        guard storyboards.storyboards.indices.contains(si),
              storyboards.storyboards[si].acts.indices.contains(ai),
              storyboards.storyboards[si].acts[ai].sequences.indices.contains(seqi),
              storyboards.storyboards[si].acts[ai].sequences[seqi].scenes.indices.contains(sci) else { return }
        let count = storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].panels.count
        let name = "Panel \(count + 1)"
        let panel = PanelEntry(panelID: UUID().uuidString, name: name, duration: 30)
        storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].panels.append(panel)
        selectedStoryboardIndex = si
        selection = .panel(panel.panelID)
    }

    // MARK: - Arrange actions

    private func moveUp() {
        switch selection {
        case .storyboard(let si):
            guard si > 0 else { return }
            storyboards.storyboards.swapAt(si, si - 1)
            selectedStoryboardIndex = si - 1
            selection = .storyboard(si - 1)
        case .act(let si, let ai):
            guard storyboards.storyboards.indices.contains(si), ai > 0 else { return }
            storyboards.storyboards[si].acts.swapAt(ai, ai - 1)
            selection = .act(si, ai - 1)
        case .sequence(let si, let ai, let seqi):
            guard storyboards.storyboards.indices.contains(si),
                  storyboards.storyboards[si].acts.indices.contains(ai), seqi > 0 else { return }
            storyboards.storyboards[si].acts[ai].sequences.swapAt(seqi, seqi - 1)
            selection = .sequence(si, ai, seqi - 1)
        case .scene(let si, let ai, let seqi, let sci):
            guard storyboards.storyboards.indices.contains(si),
                  storyboards.storyboards[si].acts.indices.contains(ai),
                  storyboards.storyboards[si].acts[ai].sequences.indices.contains(seqi),
                  sci > 0 else { return }
            storyboards.storyboards[si].acts[ai].sequences[seqi].scenes.swapAt(sci, sci - 1)
            selection = .scene(si, ai, seqi, sci - 1)
        case .panel(let id):
            if let (si, ai, seqi, sci, pi) = findPanel(id), pi > 0 {
                storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].panels.swapAt(pi, pi - 1)
            }
        case .none: break
        }
    }

    private func moveDown() {
        switch selection {
        case .storyboard(let si):
            guard si < storyboards.storyboards.count - 1 else { return }
            storyboards.storyboards.swapAt(si, si + 1)
            selectedStoryboardIndex = si + 1
            selection = .storyboard(si + 1)
        case .act(let si, let ai):
            guard storyboards.storyboards.indices.contains(si),
                  ai < storyboards.storyboards[si].acts.count - 1 else { return }
            storyboards.storyboards[si].acts.swapAt(ai, ai + 1)
            selection = .act(si, ai + 1)
        case .sequence(let si, let ai, let seqi):
            guard storyboards.storyboards.indices.contains(si),
                  storyboards.storyboards[si].acts.indices.contains(ai),
                  seqi < storyboards.storyboards[si].acts[ai].sequences.count - 1 else { return }
            storyboards.storyboards[si].acts[ai].sequences.swapAt(seqi, seqi + 1)
            selection = .sequence(si, ai, seqi + 1)
        case .scene(let si, let ai, let seqi, let sci):
            guard storyboards.storyboards.indices.contains(si),
                  storyboards.storyboards[si].acts.indices.contains(ai),
                  storyboards.storyboards[si].acts[ai].sequences.indices.contains(seqi),
                  sci < storyboards.storyboards[si].acts[ai].sequences[seqi].scenes.count - 1 else { return }
            storyboards.storyboards[si].acts[ai].sequences[seqi].scenes.swapAt(sci, sci + 1)
            selection = .scene(si, ai, seqi, sci + 1)
        case .panel(let id):
            if let (si, ai, seqi, sci, pi) = findPanel(id) {
                let count = storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].panels.count
                guard pi < count - 1 else { return }
                storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].panels.swapAt(pi, pi + 1)
            }
        case .none: break
        }
    }

    // MARK: - Export action

    private func exportPDF() {
        let panels = panelsInScope
        guard !panels.isEmpty else { return }
        let title: String
        switch selection {
        case .storyboard(let si): title = storyboards.storyboards[si].name
        case .act(let si, let ai): title = storyboards.storyboards[si].acts[ai].name
        case .sequence(let si, let ai, let seqi): title = storyboards.storyboards[si].acts[ai].sequences[seqi].name
        case .scene(let si, let ai, let seqi, let sci): title = storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].name
        case .panel(let id): title = findPanel(id).map { storyboards.storyboards[$0.0].acts[$0.1].sequences[$0.2].scenes[$0.3].panels[$0.4].name } ?? "Panel"
        case .none: title = "Export"
        }
        let filename = "\(title.replacingOccurrences(of: " ", with: "_")).pdf"
        PDFExportService.exportWithSavePanel(panels: panels, headerTitle: title, defaultFilename: filename)
    }

    // MARK: - Generate actions

    private func generateSmall() {
        queuePanels(panelsInScope.filter { !$0.hasSmallImage }, size: .small)
    }

    private func generateLarge() {
        queuePanels(panelsInScope.filter { !$0.hasLargeImage }, size: .large)
    }

    private func queuePanels(_ panels: [PanelEntry], size: GenerationSize) {
        guard let sb = activeStoryboard, !sb.styleID.isEmpty, !sb.modelID.isEmpty else { return }
        let styleDesc = styles.styles.first { $0.styleID == sb.styleID }?.style ?? ""
        let styleName = styles.styles.first { $0.styleID == sb.styleID }?.name ?? ""
        let w = size == .large ? config.largeImageWidth : config.smallImageWidth
        let h = size == .large ? config.largeImageHeight : config.smallImageHeight
        for panel in panels {
            let prompt = buildPrompt(panel: panel, styleDesc: styleDesc)
            let locID = locationImageID(for: panel, styleID: sb.styleID)
            let charIDs = characterImageIDs(for: panel, styleID: sb.styleID)
            let seed = panel.seed == 0 ? SeedHelper.randomSeed() : panel.seed
            let job = GenerationJob(
                id: UUID().uuidString, itemName: panel.name, jobType: .generatePanel,
                size: size, styleName: styleName, queuedAt: Date(),
                estimatedDuration: size == .large ? 180 : 60, itemIcon: "list.and.film",
                seed: seed, width: w, height: h, combinedPrompt: prompt,
                styleID: sb.styleID, panelID: panel.panelID, modelID: sb.modelID,
                initImageID: locID, moodboardImageIDs: charIDs
            )
            generationQueue.append(job)
        }
    }

    private func buildPrompt(panel: PanelEntry, styleDesc: String) -> String {
        var parts: [String] = []
        if !styleDesc.isEmpty { parts.append(styleDesc) }
        if !panel.description.isEmpty { parts.append(panel.description) }
        if !panel.cameraMovement.isEmpty { parts.append(panel.cameraMovement) }
        return parts.joined(separator: ", ")
    }

    private func locationImageID(for panel: PanelEntry, styleID: String) -> String {
        for id in panel.refIDs {
            if let entry = assets.assets.first(where: { $0.assetID == id }), entry.isLocation {
                return entry.bestImageID(forStyle: styleID)
            }
        }
        return ""
    }

    private func characterImageIDs(for panel: PanelEntry, styleID: String) -> [String] {
        panel.refIDs.compactMap { id in
            guard let entry = assets.assets.first(where: { $0.assetID == id }), entry.isCharacter else { return nil }
            let img = entry.bestImageID(forStyle: styleID)
            return img.isEmpty ? nil : img
        }
    }

    // MARK: - Panel finder

    private func findPanel(_ id: String) -> (Int, Int, Int, Int, Int)? {
        for si in storyboards.storyboards.indices {
            for ai in storyboards.storyboards[si].acts.indices {
                for seqi in storyboards.storyboards[si].acts[ai].sequences.indices {
                    for sci in storyboards.storyboards[si].acts[ai].sequences[seqi].scenes.indices {
                        for pi in storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].panels.indices {
                            if storyboards.storyboards[si].acts[ai].sequences[seqi].scenes[sci].panels[pi].panelID == id {
                                return (si, ai, seqi, sci, pi)
                            }
                        }
                    }
                }
            }
        }
        return nil
    }

    // MARK: - Fountain import

    private func importFountainFile() {
        let panel = NSOpenPanel()
        panel.title = "Import Fountain Screenplay"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        let fountainType = UTType(filenameExtension: "fountain") ?? UTType.plainText
        panel.allowedContentTypes = [fountainType, .plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let importedActs = try FountainParser.parse(contentsOf: url)
            guard !importedActs.isEmpty else { return }
            let name = FountainParser.storyboardName(from: url)
            onFountainImport?(importedActs, name)
        } catch {
            print("[FountainImport] Error: \(error)")
        }
    }
}

// MARK: - Storyboard row (top-level branch)
/// #87: Shows model name + style name below storyboard name
/// #89: x-button for deletion; context menu removed

private struct StoryboardRow: View {
    @Binding var storyboard: StoryboardEntry
    let storyboardIndex: Int
    @Binding var selection: StoryboardSelection?
    @Binding var selectedStoryboardIndex: Int
    let models: ModelsFile
    let styles: StylesFile
    let canDelete: Bool
    let onDelete: () -> Void
    @State private var isExpanded = true

    private var isSelected: Bool {
        selection == .storyboard(storyboardIndex)
    }

    private var modelName: String {
        models.models.first(where: { $0.modelID == storyboard.modelID })?.name ?? "—"
    }
    private var styleName: String {
        styles.styles.first(where: { $0.styleID == storyboard.styleID })?.name ?? "—"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button { isExpanded.toggle() } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.medium)).frame(width: 16)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
                Image(systemName: "film")
                    .foregroundStyle(.indigo).frame(width: 16)
                VStack(alignment: .leading, spacing: 1) {
                    Text(storyboard.name).font(.subheadline.weight(.bold))
                    // #87: Model + Style names
                    HStack(spacing: 4) {
                        Text(modelName).font(.caption2).foregroundStyle(.blue.opacity(0.8)).lineLimit(1)
                        Text("\u{00b7}").font(.caption2).foregroundStyle(.quaternary)
                        Text(styleName).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Spacer()
                Text("\(storyboard.acts.count) act(s)").font(.caption).foregroundStyle(.secondary)
                Button(action: onDelete) {
                    Image(systemName: "x.circle.fill")
                        .font(.system(size: 13))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(!canDelete)
                .help("Delete storyboard")
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.indigo.opacity(0.04))
            .contentShape(Rectangle())
            .onTapGesture {
                selectedStoryboardIndex = storyboardIndex
                selection = .storyboard(storyboardIndex)
            }

            if isExpanded {
                ForEach(storyboard.acts.indices, id: \.self) { ai in
                    ActRow(
                        act: $storyboard.acts[ai],
                        storyboardIndex: storyboardIndex,
                        actIndex: ai,
                        actCount: storyboard.acts.count,
                        selection: $selection,
                        selectedStoryboardIndex: $selectedStoryboardIndex,
                        onAddSequence: { addSequence(toAct: ai) },
                        onDelete: { storyboard.acts.remove(at: ai) },
                        onMoveUp: ai > 0 ? { storyboard.acts.swapAt(ai, ai - 1) } : nil,
                        onMoveDown: ai < storyboard.acts.count - 1 ? { storyboard.acts.swapAt(ai, ai + 1) } : nil
                    )
                    .padding(.leading, 16)
                }
            }
        }
    }

    private func addAct() {
        let name = "Act \(storyboard.acts.count + 1)"
        storyboard.acts.append(ActEntry(name: name, sequences: []))
        selectedStoryboardIndex = storyboardIndex
        selection = .act(storyboardIndex, storyboard.acts.count - 1)
    }

    private func addSequence(toAct ai: Int) {
        let name = "Sequence \(storyboard.acts[ai].sequences.count + 1)"
        storyboard.acts[ai].sequences.append(SequenceEntry(name: name, scenes: []))
        selectedStoryboardIndex = storyboardIndex
        selection = .sequence(storyboardIndex, ai, storyboard.acts[ai].sequences.count - 1)
    }
}

// MARK: - Act row
/// #89: x-button for deletion; context menu removed

private struct ActRow: View {
    @Binding var act: ActEntry
    let storyboardIndex: Int
    let actIndex: Int
    let actCount: Int
    @Binding var selection: StoryboardSelection?
    @Binding var selectedStoryboardIndex: Int
    let onAddSequence: () -> Void
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    @State private var isExpanded = true

    private var isSelected: Bool {
        selection == .act(storyboardIndex, actIndex)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button { isExpanded.toggle() } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.medium)).frame(width: 16)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
                Image(systemName: "theatermasks")
                    .foregroundStyle(.purple).frame(width: 16)
                Text(act.name).font(.subheadline.weight(.semibold))
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "x.circle.fill")
                        .font(.system(size: 13))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(actCount <= 1)
                .help("Delete act")
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedStoryboardIndex = storyboardIndex
                selection = .act(storyboardIndex, actIndex)
            }

            if isExpanded {
                ForEach(act.sequences.indices, id: \.self) { si in
                    SequenceRow(
                        sequence: $act.sequences[si],
                        storyboardIndex: storyboardIndex,
                        actIndex: actIndex,
                        seqIndex: si,
                        seqCount: act.sequences.count,
                        selection: $selection,
                        selectedStoryboardIndex: $selectedStoryboardIndex,
                        onAddScene: { addScene(toSequence: si) },
                        onDelete: { act.sequences.remove(at: si) },
                        onMoveUp: si > 0 ? { act.sequences.swapAt(si, si - 1) } : nil,
                        onMoveDown: si < act.sequences.count - 1 ? { act.sequences.swapAt(si, si + 1) } : nil
                    )
                    .padding(.leading, 16)
                    .background(Color.secondary.opacity(0.02))
                }
            }
        }
    }

    private func addScene(toSequence si: Int) {
        let name = "Scene \(act.sequences[si].scenes.count + 1)"
        let panel = PanelEntry(panelID: UUID().uuidString, name: "Panel 1", duration: 30)
        act.sequences[si].scenes.append(SceneEntry(name: name, panels: [panel]))
        selectedStoryboardIndex = storyboardIndex
        selection = .scene(storyboardIndex, actIndex, si, act.sequences[si].scenes.count - 1)
    }
}

// MARK: - Sequence row
/// #89: x-button for deletion; context menu removed

private struct SequenceRow: View {
    @Binding var sequence: SequenceEntry
    let storyboardIndex: Int
    let actIndex: Int
    let seqIndex: Int
    let seqCount: Int
    @Binding var selection: StoryboardSelection?
    @Binding var selectedStoryboardIndex: Int
    let onAddScene: () -> Void
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    @State private var isExpanded = true

    private var isSelected: Bool {
        selection == .sequence(storyboardIndex, actIndex, seqIndex)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button { isExpanded.toggle() } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.medium)).frame(width: 16)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
                Image(systemName: "ellipsis.rectangle")
                    .foregroundStyle(.orange).frame(width: 16)
                Text(sequence.name).font(.subheadline)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "x.circle.fill")
                        .font(.system(size: 13))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(seqCount <= 1)
                .help("Delete sequence")
            }
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedStoryboardIndex = storyboardIndex
                selection = .sequence(storyboardIndex, actIndex, seqIndex)
            }

            if isExpanded {
                ForEach(sequence.scenes.indices, id: \.self) { sci in
                    SceneRow(
                        scene: $sequence.scenes[sci],
                        storyboardIndex: storyboardIndex,
                        actIndex: actIndex,
                        seqIndex: seqIndex,
                        sceneIndex: sci,
                        sceneCount: sequence.scenes.count,
                        selection: $selection,
                        selectedStoryboardIndex: $selectedStoryboardIndex,
                        onAddPanel: { addPanel(toScene: sci) },
                        onDelete: { sequence.scenes.remove(at: sci) },
                        onMoveUp: sci > 0 ? { sequence.scenes.swapAt(sci, sci - 1) } : nil,
                        onMoveDown: sci < sequence.scenes.count - 1 ? { sequence.scenes.swapAt(sci, sci + 1) } : nil
                    )
                    .padding(.leading, 16)
                    .background(Color.secondary.opacity(0.04))
                }
            }
        }
    }

    private func addPanel(toScene sci: Int) {
        let name = "Panel \(sequence.scenes[sci].panels.count + 1)"
        let panel = PanelEntry(panelID: UUID().uuidString, name: name, duration: 30)
        sequence.scenes[sci].panels.append(panel)
        selectedStoryboardIndex = storyboardIndex
        selection = .panel(panel.panelID)
    }
}

// MARK: - Scene row
/// #89: x-button for deletion; context menu removed

private struct SceneRow: View {
    @Binding var scene: SceneEntry
    let storyboardIndex: Int
    let actIndex: Int
    let seqIndex: Int
    let sceneIndex: Int
    let sceneCount: Int
    @Binding var selection: StoryboardSelection?
    @Binding var selectedStoryboardIndex: Int
    let onAddPanel: () -> Void
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    @State private var isExpanded = true

    private var isSelected: Bool {
        selection == .scene(storyboardIndex, actIndex, seqIndex, sceneIndex)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button { isExpanded.toggle() } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.medium)).frame(width: 16)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
                Image(systemName: "photo")
                    .foregroundStyle(.teal).frame(width: 16)
                Text(scene.name).font(.subheadline)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "x.circle.fill")
                        .font(.system(size: 13))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(sceneCount <= 1)
                .help("Delete scene")
            }
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedStoryboardIndex = storyboardIndex
                selection = .scene(storyboardIndex, actIndex, seqIndex, sceneIndex)
            }

            if isExpanded {
                ForEach(scene.panels.indices, id: \.self) { pi in
                    PanelRow(
                        panel: $scene.panels[pi],
                        storyboardIndex: storyboardIndex,
                        selection: $selection,
                        selectedStoryboardIndex: $selectedStoryboardIndex,
                        panelCount: scene.panels.count,
                        onDelete: { scene.panels.remove(at: pi) },
                        onMoveUp: pi > 0 ? { scene.panels.swapAt(pi, pi - 1) } : nil,
                        onMoveDown: pi < scene.panels.count - 1 ? { scene.panels.swapAt(pi, pi + 1) } : nil
                    )
                    .padding(.leading, 16)
                    .background(Color.secondary.opacity(0.06))
                }
            }
        }
    }
}

// MARK: - Panel row
/// #89: x-button for deletion; context menu removed

private struct PanelRow: View {
    @Binding var panel: PanelEntry
    let storyboardIndex: Int
    @Binding var selection: StoryboardSelection?
    @Binding var selectedStoryboardIndex: Int
    let panelCount: Int
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?

    private var isSelected: Bool {
        selection == .panel(panel.panelID)
    }

    var body: some View {
        HStack(spacing: 6) {
            if panel.hasSmallImage {
                let img = StorageService.shared.loadImage(id: panel.smallImageID)
                if let img {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                } else {
                    panelIcon
                }
            } else {
                panelIcon
            }
            Text(panel.name).font(.subheadline)
            Spacer()
            if panel.hasSmallImage {
                Text("S").font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.orange).padding(2)
            }
            if panel.hasLargeImage {
                Text("L").font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.green).padding(2)
            }
            Button(action: onDelete) {
                Image(systemName: "x.circle.fill")
                    .font(.system(size: 13))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(panelCount <= 1)
            .help("Delete panel")
        }
        .padding(.horizontal, 12).padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedStoryboardIndex = storyboardIndex
            selection = .panel(panel.panelID)
        }
    }

    private var panelIcon: some View {
        Image(systemName: "list.and.film")
            .foregroundStyle(.blue).frame(width: 16)
    }
}
