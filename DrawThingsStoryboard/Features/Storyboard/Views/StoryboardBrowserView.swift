import SwiftUI

/// Center pane for the Storyboard section.
/// Shows a nested outline of Acts > Sequences > Scenes > Panel thumbnails.
/// Clicking on an Act, Sequence, or Scene header selects it for the detail pane.
/// Each grouping level is collapsible via a disclosure triangle and has +/- buttons.
struct StoryboardBrowserView: View {

    @Binding var acts: [MockAct]
    @Binding var selection: StoryboardSelection?

    /// Tracks which IDs are collapsed (hidden children). Expanded by default.
    @State private var collapsedIDs: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "pencil.and.list.clipboard")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Storyboard")
                    .font(.title2.bold())
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()

            if acts.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No acts yet",
                    systemImage: "theatermask.and.paintbrush",
                    description: Text("Add an act to start building your storyboard.")
                )
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(acts.enumerated()), id: \.element.id) { actIdx, _ in
                            ActSectionView(
                                acts: $acts,
                                actIndex: actIdx,
                                selection: $selection,
                                collapsedIDs: $collapsedIDs
                            )

                            if actIdx < acts.count - 1 {
                                Divider().padding(.vertical, 6).padding(.horizontal, 14)
                            }
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            ensureSelection()
        }
    }

    private func ensureSelection() {
        guard !acts.isEmpty, selection == nil else { return }
        selection = .act(acts[0].id)
    }
}

// MARK: - Act section

private struct ActSectionView: View {
    @Binding var acts: [MockAct]
    let actIndex: Int
    @Binding var selection: StoryboardSelection?
    @Binding var collapsedIDs: Set<String>

    private var act: MockAct { acts[actIndex] }

    private var isSelected: Bool {
        selection == .act(act.id)
    }

    private var isCollapsed: Bool {
        collapsedIDs.contains(act.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StoryboardOutlineHeader(
                level: .act,
                name: act.name,
                number: actIndex + 1,
                isSelected: isSelected,
                isCollapsed: isCollapsed,
                canRemove: acts.count > 1,
                onTap: { selection = .act(act.id) },
                onToggleCollapse: { toggleCollapse(act.id) },
                onAdd: addAct,
                onRemove: removeAct
            )

            if !isCollapsed {
                ForEach(Array(act.sequences.enumerated()), id: \.element.id) { seqIdx, _ in
                    SequenceSectionView(
                        sequences: $acts[actIndex].sequences,
                        sequenceIndex: seqIdx,
                        selection: $selection,
                        collapsedIDs: $collapsedIDs
                    )
                }
            }
        }
    }

    private func addAct() {
        let newAct = MockAct(
            id: UUID().uuidString,
            name: "New Act",
            description: "",
            sequences: [
                MockSequence(
                    id: UUID().uuidString,
                    name: "New Sequence",
                    description: "",
                    scenes: [
                        MockScene(
                            id: UUID().uuidString,
                            name: "New Scene",
                            description: "",
                            panels: []
                        )
                    ]
                )
            ]
        )
        acts.insert(newAct, at: actIndex + 1)
        selection = .act(newAct.id)
    }

    private func removeAct() {
        guard acts.count > 1 else { return }
        acts.remove(at: actIndex)
        let fallbackIdx = min(actIndex, acts.count - 1)
        selection = .act(acts[fallbackIdx].id)
    }

    private func toggleCollapse(_ id: String) {
        if collapsedIDs.contains(id) {
            collapsedIDs.remove(id)
        } else {
            collapsedIDs.insert(id)
        }
    }
}

// MARK: - Sequence section

private struct SequenceSectionView: View {
    @Binding var sequences: [MockSequence]
    let sequenceIndex: Int
    @Binding var selection: StoryboardSelection?
    @Binding var collapsedIDs: Set<String>

    private var sequence: MockSequence { sequences[sequenceIndex] }

    private var isSelected: Bool {
        selection == .sequence(sequence.id)
    }

    private var isCollapsed: Bool {
        collapsedIDs.contains(sequence.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StoryboardOutlineHeader(
                level: .sequence,
                name: sequence.name,
                number: sequenceIndex + 1,
                isSelected: isSelected,
                isCollapsed: isCollapsed,
                canRemove: sequences.count > 1,
                onTap: { selection = .sequence(sequence.id) },
                onToggleCollapse: { toggleCollapse(sequence.id) },
                onAdd: addSequence,
                onRemove: removeSequence
            )
            .padding(.leading, 16)

            if !isCollapsed {
                ForEach(Array(sequence.scenes.enumerated()), id: \.element.id) { scnIdx, _ in
                    SceneSectionView(
                        scenes: $sequences[sequenceIndex].scenes,
                        sceneIndex: scnIdx,
                        selection: $selection,
                        collapsedIDs: $collapsedIDs
                    )
                }
            }
        }
    }

    private func addSequence() {
        let newSeq = MockSequence(
            id: UUID().uuidString,
            name: "New Sequence",
            description: "",
            scenes: [
                MockScene(
                    id: UUID().uuidString,
                    name: "New Scene",
                    description: "",
                    panels: []
                )
            ]
        )
        sequences.insert(newSeq, at: sequenceIndex + 1)
        selection = .sequence(newSeq.id)
    }

    private func removeSequence() {
        guard sequences.count > 1 else { return }
        sequences.remove(at: sequenceIndex)
        let fallbackIdx = min(sequenceIndex, sequences.count - 1)
        selection = .sequence(sequences[fallbackIdx].id)
    }

    private func toggleCollapse(_ id: String) {
        if collapsedIDs.contains(id) {
            collapsedIDs.remove(id)
        } else {
            collapsedIDs.insert(id)
        }
    }
}

// MARK: - Scene section (contains panel thumbnails)

private struct SceneSectionView: View {
    @Binding var scenes: [MockScene]
    let sceneIndex: Int
    @Binding var selection: StoryboardSelection?
    @Binding var collapsedIDs: Set<String>

    private let columns = [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 8)]

    private var scene: MockScene { scenes[sceneIndex] }

    private var isSelected: Bool {
        selection == .scene(scene.id)
    }

    private var isCollapsed: Bool {
        collapsedIDs.contains(scene.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            StoryboardOutlineHeader(
                level: .scene,
                name: scene.name,
                number: sceneIndex + 1,
                isSelected: isSelected,
                isCollapsed: isCollapsed,
                canRemove: scenes.count > 1,
                onTap: { selection = .scene(scene.id) },
                onToggleCollapse: { toggleCollapse(scene.id) },
                onAdd: addScene,
                onRemove: removeScene
            )
            .padding(.leading, 32)

            // Panel thumbnails with + / - in a small toolbar
            if !isCollapsed {
                if !scene.panels.isEmpty {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(scene.panels) { panel in
                            StoryboardPanelTileView(
                                panel: panel,
                                isSelected: selection == .panel(panel.id),
                                onTap: { selection = .panel(panel.id) }
                            )
                        }
                    }
                    .padding(.horizontal, 46)
                    .padding(.vertical, 4)
                }

                // Panel + / - buttons
                HStack {
                    Spacer()
                    Button(action: removePanel) {
                        Image(systemName: "minus")
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .disabled(!canRemovePanel)

                    Button(action: addPanel) {
                        Image(systemName: "plus")
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
                .padding(.horizontal, 46)
                .padding(.bottom, 4)
            }
        }
    }

    private var canRemovePanel: Bool {
        guard case .panel(let id) = selection else { return false }
        return scene.panels.contains { $0.id == id }
    }

    private func addPanel() {
        let newPanel = MockPanel(
            id: UUID().uuidString,
            name: "New Panel",
            description: "",
            status: .nothingGenerated
        )
        scenes[sceneIndex].panels.append(newPanel)
        selection = .panel(newPanel.id)
    }

    private func removePanel() {
        guard case .panel(let id) = selection,
              let idx = scenes[sceneIndex].panels.firstIndex(where: { $0.id == id }) else { return }
        scenes[sceneIndex].panels.remove(at: idx)
        if scenes[sceneIndex].panels.isEmpty {
            selection = .scene(scene.id)
        } else {
            let fallbackIdx = min(idx, scenes[sceneIndex].panels.count - 1)
            selection = .panel(scenes[sceneIndex].panels[fallbackIdx].id)
        }
    }

    private func addScene() {
        let newScene = MockScene(
            id: UUID().uuidString,
            name: "New Scene",
            description: "",
            panels: []
        )
        scenes.insert(newScene, at: sceneIndex + 1)
        selection = .scene(newScene.id)
    }

    private func removeScene() {
        guard scenes.count > 1 else { return }
        scenes.remove(at: sceneIndex)
        let fallbackIdx = min(sceneIndex, scenes.count - 1)
        selection = .scene(scenes[fallbackIdx].id)
    }

    private func toggleCollapse(_ id: String) {
        if collapsedIDs.contains(id) {
            collapsedIDs.remove(id)
        } else {
            collapsedIDs.insert(id)
        }
    }
}

// MARK: - Outline header (clickable Act / Sequence / Scene header with disclosure + / -)

private struct StoryboardOutlineHeader: View {
    let level: StoryboardLevel
    let name: String
    let number: Int
    let isSelected: Bool
    let isCollapsed: Bool
    let canRemove: Bool
    let onTap: () -> Void
    let onToggleCollapse: () -> Void
    let onAdd: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Disclosure triangle
            Button(action: onToggleCollapse) {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Selectable header content
            Button(action: onTap) {
                HStack(spacing: 6) {
                    Image(systemName: level.icon)
                        .foregroundStyle(level.color)
                        .frame(width: 16)
                    Text("\(level.label) \(number)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(level.color)
                    Text("— \(name)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                        .lineLimit(1)
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            // + / - buttons
            Button(action: onRemove) {
                Image(systemName: "minus")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
            .disabled(!canRemove)

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
        .padding(.vertical, 6)
        .padding(.leading, 6)
        .padding(.trailing, 14)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? level.color.opacity(0.1) : Color.clear)
        )
    }
}

// MARK: - Panel thumbnail tile

private struct StoryboardPanelTileView: View {
    let panel: MockPanel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(StoryboardLevel.panel.color.opacity(0.13))
                    .frame(height: 64)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 20))
                            .foregroundStyle(StoryboardLevel.panel.color.opacity(0.7))
                    }

                // Status dot — bottom-right
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(panel.status.color)
                            .frame(width: 6, height: 6)
                            .padding(4)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )

            Text(panel.name)
                .font(.caption2)
                .lineLimit(1)
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.07) : Color.clear)
        )
        .onTapGesture { onTap() }
    }
}

#Preview {
    @Previewable @State var acts = MockData.sampleActs
    @Previewable @State var sel: StoryboardSelection? = nil
    StoryboardBrowserView(acts: $acts, selection: $sel)
        .frame(width: 420, height: 600)
}
