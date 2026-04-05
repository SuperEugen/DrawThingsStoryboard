import SwiftUI

// MARK: - Storyboard selection

enum StoryboardSelection: Hashable {
    case act(String)
    case sequence(String)
    case scene(String)
    case panel(String)
}

// MARK: - StoryboardBrowserView

struct StoryboardBrowserView: View {

    @Binding var acts: [ActEntry]
    @Binding var selection: StoryboardSelection?
    @Binding var styleName: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "pencil.and.list.clipboard").font(.title2).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Storyboard").font(.title2.bold())
                    if let name = styleName {
                        Text(name).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            Divider()

            if acts.isEmpty {
                Spacer()
                // #35: Actionable empty state
                ContentUnavailableView("No acts yet", systemImage: "pencil.and.list.clipboard",
                    description: Text("Add an act to start building your storyboard."))
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(acts.indices, id: \.self) { ai in
                            // #29: Background tint for depth
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
    @Binding var act: ActEntry
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
                Image(systemName: "theatermask.and.paintbrush")
                    .foregroundStyle(.purple).frame(width: 16)
                Text(act.name).font(.subheadline.weight(.semibold))
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(selection == .act(act.name) ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture { selection = .act(act.name) }

            if isExpanded {
                ForEach(act.sequences.indices, id: \.self) { si in
                    SequenceRow(sequence: $act.sequences[si], selection: $selection)
                        .padding(.leading, 16)
                        // #29: Subtle depth tint
                        .background(Color.secondary.opacity(0.02))
                }
            }
        }
    }
}

// MARK: - Sequence row

private struct SequenceRow: View {
    @Binding var sequence: SequenceEntry
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
                Image(systemName: "arrow.triangle.branch")
                    .foregroundStyle(.orange).frame(width: 16)
                Text(sequence.name).font(.subheadline)
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(selection == .sequence(sequence.name) ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture { selection = .sequence(sequence.name) }

            if isExpanded {
                ForEach(sequence.scenes.indices, id: \.self) { sci in
                    SceneRow(scene: $sequence.scenes[sci], selection: $selection)
                        .padding(.leading, 16)
                        // #29: Deeper depth tint
                        .background(Color.secondary.opacity(0.04))
                }
            }
        }
    }
}

// MARK: - Scene row

private struct SceneRow: View {
    @Binding var scene: SceneEntry
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
                Image(systemName: "rectangle.on.rectangle")
                    .foregroundStyle(.teal).frame(width: 16)
                Text(scene.name).font(.subheadline)
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(selection == .scene(scene.name) ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture { selection = .scene(scene.name) }

            if isExpanded {
                ForEach(scene.panels.indices, id: \.self) { pi in
                    PanelRow(panel: $scene.panels[pi], selection: $selection)
                        .padding(.leading, 16)
                        // #29: Deepest depth tint
                        .background(Color.secondary.opacity(0.06))
                }
            }
        }
    }
}

// MARK: - Panel row
/// #17: Panel rows now show a small thumbnail if the panel has a generated image.

private struct PanelRow: View {
    @Binding var panel: PanelEntry
    @Binding var selection: StoryboardSelection?

    var body: some View {
        HStack(spacing: 6) {
            // #17: Show tiny thumbnail if panel has an image
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
    }

    private var panelIcon: some View {
        Image(systemName: "photo")
            .foregroundStyle(.blue).frame(width: 16)
    }
}
