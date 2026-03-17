import SwiftUI

/// Center pane for the Storyboard section.
/// Shows a nested outline of Acts > Sequences > Scenes > Panel thumbnails.
/// Clicking on an Act, Sequence, or Scene header selects it for the detail pane.
/// Each grouping level is collapsible via a disclosure triangle.
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
                        ForEach(Array(acts.enumerated()), id: \.element.id) { actIdx, act in
                            ActSectionView(
                                act: act,
                                actIndex: actIdx,
                                totalActs: acts.count,
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
    let act: MockAct
    let actIndex: Int
    let totalActs: Int
    @Binding var selection: StoryboardSelection?
    @Binding var collapsedIDs: Set<String>

    private var isSelected: Bool {
        selection == .act(act.id)
    }

    private var isCollapsed: Bool {
        collapsedIDs.contains(act.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Act header
            StoryboardOutlineHeader(
                level: .act,
                name: act.name,
                number: actIndex + 1,
                isSelected: isSelected,
                isCollapsed: isCollapsed,
                onTap: { selection = .act(act.id) },
                onToggleCollapse: { toggleCollapse(act.id) }
            )

            // Sequences inside this act (collapsible)
            if !isCollapsed {
                ForEach(Array(act.sequences.enumerated()), id: \.element.id) { seqIdx, sequence in
                    SequenceSectionView(
                        sequence: sequence,
                        sequenceIndex: seqIdx,
                        selection: $selection,
                        collapsedIDs: $collapsedIDs
                    )
                }
            }
        }
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
    let sequence: MockSequence
    let sequenceIndex: Int
    @Binding var selection: StoryboardSelection?
    @Binding var collapsedIDs: Set<String>

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
                onTap: { selection = .sequence(sequence.id) },
                onToggleCollapse: { toggleCollapse(sequence.id) }
            )
            .padding(.leading, 16)

            // Scenes inside this sequence (collapsible)
            if !isCollapsed {
                ForEach(Array(sequence.scenes.enumerated()), id: \.element.id) { scnIdx, scene in
                    SceneSectionView(
                        scene: scene,
                        sceneIndex: scnIdx,
                        selection: $selection,
                        collapsedIDs: $collapsedIDs
                    )
                }
            }
        }
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
    let scene: MockScene
    let sceneIndex: Int
    @Binding var selection: StoryboardSelection?
    @Binding var collapsedIDs: Set<String>

    private let columns = [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 8)]

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
                onTap: { selection = .scene(scene.id) },
                onToggleCollapse: { toggleCollapse(scene.id) }
            )
            .padding(.leading, 32)

            // Panel thumbnails (collapsible)
            if !isCollapsed && !scene.panels.isEmpty {
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
        }
    }

    private func toggleCollapse(_ id: String) {
        if collapsedIDs.contains(id) {
            collapsedIDs.remove(id)
        } else {
            collapsedIDs.insert(id)
        }
    }
}

// MARK: - Outline header (clickable Act / Sequence / Scene header with disclosure)

private struct StoryboardOutlineHeader: View {
    let level: StoryboardLevel
    let name: String
    let number: Int
    let isSelected: Bool
    let isCollapsed: Bool
    let onTap: () -> Void
    let onToggleCollapse: () -> Void

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
