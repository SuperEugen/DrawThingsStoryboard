import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Storyboard selection

enum StoryboardSelection: Hashable {
    case act(String)
    case sequence(String)
    case scene(String)
    case panel(String)
}

// MARK: - StoryboardBrowserView
/// #45: Storyboard picker, move up/down for all tree levels
/// #52: Model picker in storyboard header

struct StoryboardBrowserView: View {

    @Binding var storyboards: StoryboardsFile
    @Binding var selectedStoryboardIndex: Int
    @Binding var selection: StoryboardSelection?
    let styles: StylesFile
    @Binding var currentStyleID: String
    let models: ModelsFile
    @Binding var currentModelID: String
    var onFountainImport: (([ActEntry], String) -> Void)? = nil

    /// The acts of the currently selected storyboard.
    private var acts: Binding<[ActEntry]> {
        guard storyboards.storyboards.indices.contains(selectedStoryboardIndex) else {
            return .constant([])
        }
        return $storyboards.storyboards[selectedStoryboardIndex].acts
    }

    private var currentStoryboard: StoryboardEntry? {
        guard storyboards.storyboards.indices.contains(selectedStoryboardIndex) else { return nil }
        return storyboards.storyboards[selectedStoryboardIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()

            if acts.wrappedValue.isEmpty {
                Spacer()
                ContentUnavailableView("No acts yet", systemImage: "pencil.and.list.clipboard",
                    description: Text("Use + to add an act, or import a Fountain file."))
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Storyboard name row
                        storyboardRow

                        ForEach(acts.wrappedValue.indices, id: \.self) { ai in
                            ActRow(
                                act: acts[ai],
                                actIndex: ai,
                                actCount: acts.wrappedValue.count,
                                selection: $selection,
                                onAddSequence: { addSequence(toAct: ai) },
                                onDelete: { acts.wrappedValue.remove(at: ai) },
                                onMoveUp: ai > 0 ? { acts.wrappedValue.swapAt(ai, ai - 1) } : nil,
                                onMoveDown: ai < acts.wrappedValue.count - 1 ? { acts.wrappedValue.swapAt(ai, ai + 1) } : nil
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
            Image(systemName: "pencil.and.list.clipboard").font(.title2).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text("Storyboards").font(.title2.bold())
            }
            Spacer()
            // Storyboard picker (when multiple exist)
            if storyboards.storyboards.count > 1 {
                Picker("Storyboard", selection: $selectedStoryboardIndex) {
                    ForEach(storyboards.storyboards.indices, id: \.self) { i in
                        Text(storyboards.storyboards[i].name).tag(i)
                    }
                }
                .pickerStyle(.menu).labelsHidden().frame(maxWidth: 180)
            }
            // #52: Model picker
            Picker("Model", selection: $currentModelID) {
                ForEach(models.models) { m in
                    Text(m.name).tag(m.modelID)
                }
            }
            .pickerStyle(.menu).labelsHidden().frame(maxWidth: 160)
            Picker("Style", selection: $currentStyleID) {
                ForEach(styles.styles) { s in
                    Text(s.name).tag(s.styleID)
                }
            }
            .pickerStyle(.menu).labelsHidden().frame(maxWidth: 160)
            // Add Act
            Button { addAct() } label: {
                Image(systemName: "plus").frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .help("Add a new act")
            // Add Storyboard
            Button { addStoryboard() } label: {
                Image(systemName: "doc.badge.plus").frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .help("Add a new storyboard")
            // Import Fountain
            Button { importFountainFile() } label: {
                Image(systemName: "doc.badge.arrow.up").frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .help("Import Fountain screenplay (.fountain)")
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - Storyboard name row

    @ViewBuilder
    private var storyboardRow: some View {
        if let sb = currentStoryboard {
            HStack(spacing: 6) {
                Image(systemName: "book.fill")
                    .foregroundStyle(.indigo).frame(width: 16)
                Text(sb.name).font(.subheadline.weight(.bold))
                Spacer()
                Text("\(acts.wrappedValue.count) act(s)").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Color.indigo.opacity(0.06))
        }
    }

    // MARK: - Add helpers

    private func addAct() {
        let name = "Act \(acts.wrappedValue.count + 1)"
        acts.wrappedValue.append(ActEntry(name: name, sequences: []))
        selection = .act(name)
    }

    private func addSequence(toAct ai: Int) {
        let name = "Sequence \(acts.wrappedValue[ai].sequences.count + 1)"
        acts.wrappedValue[ai].sequences.append(SequenceEntry(name: name, scenes: []))
        selection = .sequence(name)
    }

    private func addStoryboard() {
        let name = "Storyboard \(storyboards.storyboards.count + 1)"
        let modelID = models.models.first?.modelID ?? "M1"
        let styleID = styles.styles.first?.styleID ?? "S1"
        storyboards.storyboards.append(StoryboardEntry(name: name, acts: [], modelID: modelID, styleID: styleID))
        selectedStoryboardIndex = storyboards.storyboards.count - 1
        selection = nil
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

// MARK: - Act row

private struct ActRow: View {
    @Binding var act: ActEntry
    let actIndex: Int
    let actCount: Int
    @Binding var selection: StoryboardSelection?
    let onAddSequence: () -> Void
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button { isExpanded.toggle() } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.medium)).frame(width: 16)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
                Image(systemName: "theatermask.and.paintbrush")
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
            .background(selection == .act(act.name) ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture { selection = .act(act.name) }
            .contextMenu {
                Button { onAddSequence() } label: { Label("Add Sequence", systemImage: "plus") }
                Divider()
                if let onMoveUp {
                    Button { onMoveUp() } label: { Label("Move Up", systemImage: "arrow.up") }
                }
                if let onMoveDown {
                    Button { onMoveDown() } label: { Label("Move Down", systemImage: "arrow.down") }
                }
                Divider()
                Button(role: .destructive, action: onDelete) { Label("Delete Act", systemImage: "trash") }
            }

            if isExpanded {
                ForEach(act.sequences.indices, id: \.self) { si in
                    SequenceRow(
                        sequence: $act.sequences[si],
                        seqIndex: si,
                        seqCount: act.sequences.count,
                        selection: $selection,
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
        selection = .scene(name)
    }
}

// MARK: - Sequence row

private struct SequenceRow: View {
    @Binding var sequence: SequenceEntry
    let seqIndex: Int
    let seqCount: Int
    @Binding var selection: StoryboardSelection?
    let onAddScene: () -> Void
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button { isExpanded.toggle() } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.medium)).frame(width: 16)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
                Image(systemName: "arrow.triangle.branch")
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
            .background(selection == .sequence(sequence.name) ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture { selection = .sequence(sequence.name) }
            .contextMenu {
                Button { onAddScene() } label: { Label("Add Scene", systemImage: "plus") }
                Divider()
                if let onMoveUp {
                    Button { onMoveUp() } label: { Label("Move Up", systemImage: "arrow.up") }
                }
                if let onMoveDown {
                    Button { onMoveDown() } label: { Label("Move Down", systemImage: "arrow.down") }
                }
                Divider()
                Button(role: .destructive, action: onDelete) { Label("Delete Sequence", systemImage: "trash") }
            }

            if isExpanded {
                ForEach(sequence.scenes.indices, id: \.self) { sci in
                    SceneRow(
                        scene: $sequence.scenes[sci],
                        sceneIndex: sci,
                        sceneCount: sequence.scenes.count,
                        selection: $selection,
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
        selection = .panel(panel.panelID)
    }
}

// MARK: - Scene row

private struct SceneRow: View {
    @Binding var scene: SceneEntry
    let sceneIndex: Int
    let sceneCount: Int
    @Binding var selection: StoryboardSelection?
    let onAddPanel: () -> Void
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button { isExpanded.toggle() } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.medium)).frame(width: 16)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
                Image(systemName: "rectangle.on.rectangle")
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
            .background(selection == .scene(scene.name) ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture { selection = .scene(scene.name) }
            .contextMenu {
                Button { onAddPanel() } label: { Label("Add Panel", systemImage: "plus") }
                Divider()
                if let onMoveUp {
                    Button { onMoveUp() } label: { Label("Move Up", systemImage: "arrow.up") }
                }
                if let onMoveDown {
                    Button { onMoveDown() } label: { Label("Move Down", systemImage: "arrow.down") }
                }
                Divider()
                Button(role: .destructive, action: onDelete) { Label("Delete Scene", systemImage: "trash") }
            }

            if isExpanded {
                ForEach(scene.panels.indices, id: \.self) { pi in
                    PanelRow(
                        panel: $scene.panels[pi],
                        panelIndex: pi,
                        panelCount: scene.panels.count,
                        selection: $selection,
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
    let panelIndex: Int
    let panelCount: Int
    @Binding var selection: StoryboardSelection?
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?

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
        .background(selection == .panel(panel.panelID) ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { selection = .panel(panel.panelID) }
        .contextMenu {
            if let onMoveUp {
                Button { onMoveUp() } label: { Label("Move Up", systemImage: "arrow.up") }
            }
            if let onMoveDown {
                Button { onMoveDown() } label: { Label("Move Down", systemImage: "arrow.down") }
            }
            Divider()
            Button(role: .destructive, action: onDelete) { Label("Delete Panel", systemImage: "trash") }
        }
    }

    private var panelIcon: some View {
        Image(systemName: "photo")
            .foregroundStyle(.blue).frame(width: 16)
    }
}
