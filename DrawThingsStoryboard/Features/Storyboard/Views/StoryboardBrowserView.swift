import SwiftUI

// MARK: - StoryboardBrowserView

struct StoryboardBrowserView: View {

    @Binding var acts: [MockAct]
    @Binding var selection: StoryboardSelection?
    @Binding var lookName: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "pencil.and.list.clipboard").font(.title2).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Storyboard").font(.title2.bold())
                    if let name = lookName {
                        Text(name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            Divider()

            if acts.isEmpty {
                Spacer()
                ContentUnavailableView("No acts yet", systemImage: "pencil.and.list.clipboard",
                    description: Text("Add an act to start building your storyboard."))
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(acts.indices, id: \.self) { ai in
                            ActRow(act: $acts[ai], selection: $selection)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Act row

private struct ActRow: View {
    @Binding var act: MockAct
    @Binding var selection: StoryboardSelection?
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button { isExpanded.toggle() } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.medium)).frame(width: 16)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
                Image(systemName: StoryboardLevel.act.icon)
                    .foregroundStyle(StoryboardLevel.act.color).frame(width: 16)
                Text(act.name).font(.subheadline.weight(.semibold))
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(selection == .act(act.id) ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture { selection = .act(act.id) }

            if isExpanded {
                ForEach(act.sequences.indices, id: \.self) { si in
                    SequenceRow(sequence: $act.sequences[si], selection: $selection)
                        .padding(.leading, 16)
                }
            }
        }
    }
}

// MARK: - Sequence row

private struct SequenceRow: View {
    @Binding var sequence: MockSequence
    @Binding var selection: StoryboardSelection?
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button { isExpanded.toggle() } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.medium)).frame(width: 16)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
                Image(systemName: StoryboardLevel.sequence.icon)
                    .foregroundStyle(StoryboardLevel.sequence.color).frame(width: 16)
                Text(sequence.name).font(.subheadline)
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(selection == .sequence(sequence.id) ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture { selection = .sequence(sequence.id) }

            if isExpanded {
                ForEach(sequence.scenes.indices, id: \.self) { sci in
                    SceneRow(scene: $sequence.scenes[sci], selection: $selection)
                        .padding(.leading, 16)
                }
            }
        }
    }
}

// MARK: - Scene row

private struct SceneRow: View {
    @Binding var scene: MockScene
    @Binding var selection: StoryboardSelection?
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button { isExpanded.toggle() } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.medium)).frame(width: 16)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary)
                Image(systemName: StoryboardLevel.scene.icon)
                    .foregroundStyle(StoryboardLevel.scene.color).frame(width: 16)
                Text(scene.name).font(.subheadline)
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(selection == .scene(scene.id) ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture { selection = .scene(scene.id) }

            if isExpanded {
                ForEach(scene.panels.indices, id: \.self) { pi in
                    PanelRow(panel: $scene.panels[pi], selection: $selection)
                        .padding(.leading, 16)
                }
            }
        }
    }
}

// MARK: - Panel row

private struct PanelRow: View {
    @Binding var panel: MockPanel
    @Binding var selection: StoryboardSelection?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: StoryboardLevel.panel.icon)
                .foregroundStyle(StoryboardLevel.panel.color).frame(width: 16)
            Text(panel.name).font(.subheadline)
            Spacer()
            if panel.smallPanelAvailable {
                Text("S").font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.orange).padding(2)
            }
            if panel.largePanelAvailable {
                Text("L").font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.green).padding(2)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 4)
        .background(selection == .panel(panel.id) ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { selection = .panel(panel.id) }
    }
}

#Preview {
    @Previewable @State var acts: [MockAct] = []
    @Previewable @State var sel: StoryboardSelection? = nil
    @Previewable @State var lookName: String? = "Photorealistic"
    StoryboardBrowserView(acts: $acts, selection: $sel, lookName: $lookName)
        .frame(width: 300, height: 600)
}
