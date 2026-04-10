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
/// #87: Storyboard tree shows model + style names

struct StoryboardBrowserView: View {

    @Binding var storyboards: StoryboardsFile
    @Binding var selectedStoryboardIndex: Int
    @Binding var selection: StoryboardSelection?
    let models: ModelsFile
    let styles: StylesFile
    var onFountainImport: (([ActEntry], String) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            headerBar
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
                                onDelete: storyboards.storyboards.count > 1 ? {
                                    storyboards.storyboards.remove(at: si)
                                    if selectedStoryboardIndex >= storyboards.storyboards.count {
                                        selectedStoryboardIndex = max(0, storyboards.storyboards.count - 1)
                                    }
                                    selection = nil
                                } : nil
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
            Button { addStoryboard() } label: {
                Image(systemName: "plus").frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .help("Add a new storyboard with default structure")
            Button { importFountainFile() } label: {
                Image(systemName: "doc.badge.arrow.up").frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .help("Import Fountain screenplay (.fountain)")
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - Add storyboard with full minimal structure

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

private struct StoryboardRow: View {
    @Binding var storyboard: StoryboardEntry
    let storyboardIndex: Int
    @Binding var selection: StoryboardSelection?
    @Binding var selectedStoryboardIndex: Int
    let models: ModelsFile
    let styles: StylesFile
    let onDelete: (() -> Void)?
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
                Button { addAct() } label: {
                    Image(systemName: "plus").font(.caption2)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
                .help("Add act")
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.indigo.opacity(0.04))
            .contentShape(Rectangle())
            .onTapGesture {
                selectedStoryboardIndex = storyboardIndex
                selection = .storyboard(storyboardIndex)
            }
            .contextMenu {
                Button { addAct() } label: { Label("Add Act", systemImage: "plus") }
                Divider()
                if let onDelete {
                    Button(role: .destructive, action: onDelete) { Label("Delete Storyboard", systemImage: "trash") }
                }
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
                Button(action: onAddSequence) {
                    Image(systemName: "plus").font(.caption2)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
                .help("Add sequence")
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedStoryboardIndex = storyboardIndex
                selection = .act(storyboardIndex, actIndex)
            }
            .contextMenu {
                Button { onAddSequence() } label: { Label("Add Sequence", systemImage: "plus") }
                Divider()
                if let onMoveUp { Button { onMoveUp() } label: { Label("Move Up", systemImage: "arrow.up") } }
                if let onMoveDown { Button { onMoveDown() } label: { Label("Move Down", systemImage: "arrow.down") } }
                Divider()
                Button(role: .destructive, action: onDelete) { Label("Delete Act", systemImage: "trash") }
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
                Button(action: onAddScene) {
                    Image(systemName: "plus").font(.caption2)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
                .help("Add scene")
            }
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedStoryboardIndex = storyboardIndex
                selection = .sequence(storyboardIndex, actIndex, seqIndex)
            }
            .contextMenu {
                Button { onAddScene() } label: { Label("Add Scene", systemImage: "plus") }
                Divider()
                if let onMoveUp { Button { onMoveUp() } label: { Label("Move Up", systemImage: "arrow.up") } }
                if let onMoveDown { Button { onMoveDown() } label: { Label("Move Down", systemImage: "arrow.down") } }
                Divider()
                Button(role: .destructive, action: onDelete) { Label("Delete Sequence", systemImage: "trash") }
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
                Button(action: onAddPanel) {
                    Image(systemName: "plus").font(.caption2)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
                .help("Add panel")
            }
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedStoryboardIndex = storyboardIndex
                selection = .scene(storyboardIndex, actIndex, seqIndex, sceneIndex)
            }
            .contextMenu {
                Button { onAddPanel() } label: { Label("Add Panel", systemImage: "plus") }
                Divider()
                if let onMoveUp { Button { onMoveUp() } label: { Label("Move Up", systemImage: "arrow.up") } }
                if let onMoveDown { Button { onMoveDown() } label: { Label("Move Down", systemImage: "arrow.down") } }
                Divider()
                Button(role: .destructive, action: onDelete) { Label("Delete Scene", systemImage: "trash") }
            }

            if isExpanded {
                ForEach(scene.panels.indices, id: \.self) { pi in
                    PanelRow(
                        panel: $scene.panels[pi],
                        storyboardIndex: storyboardIndex,
                        selection: $selection,
                        selectedStoryboardIndex: $selectedStoryboardIndex,
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

private struct PanelRow: View {
    @Binding var panel: PanelEntry
    let storyboardIndex: Int
    @Binding var selection: StoryboardSelection?
    @Binding var selectedStoryboardIndex: Int
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
        }
        .padding(.horizontal, 12).padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedStoryboardIndex = storyboardIndex
            selection = .panel(panel.panelID)
        }
        .contextMenu {
            if let onMoveUp { Button { onMoveUp() } label: { Label("Move Up", systemImage: "arrow.up") } }
            if let onMoveDown { Button { onMoveDown() } label: { Label("Move Down", systemImage: "arrow.down") } }
            Divider()
            Button(role: .destructive, action: onDelete) { Label("Delete Panel", systemImage: "trash") }
        }
    }

    private var panelIcon: some View {
        Image(systemName: "list.and.film")
            .foregroundStyle(.blue).frame(width: 16)
    }
}
