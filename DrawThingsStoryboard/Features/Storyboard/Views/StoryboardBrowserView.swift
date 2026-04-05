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

struct StoryboardBrowserView: View {

    @Binding var acts: [ActEntry]
    @Binding var selection: StoryboardSelection?
    @Binding var styleName: String?
    /// Style picker: all available styles + binding to current storyboard's styleID
    let styles: StylesFile
    @Binding var currentStyleID: String
    /// #41: Callback to replace entire storyboard from Fountain import.
    var onFountainImport: (([ActEntry], String) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "pencil.and.list.clipboard").font(.title2).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Storyboard").font(.title2.bold())
                }
                Spacer()
                // Style selector
                Picker("Style", selection: $currentStyleID) {
                    ForEach(styles.styles) { s in
                        Text(s.name).tag(s.styleID)
                    }
                }
                .pickerStyle(.menu).labelsHidden().frame(maxWidth: 160)
                // Import Fountain file
                Button {
                    importFountainFile()
                } label: {
                    Image(systemName: "doc.badge.arrow.up")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .help("Import Fountain screenplay (.fountain)")
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            Divider()

            if acts.isEmpty {
                Spacer()
                ContentUnavailableView("No acts yet", systemImage: "pencil.and.list.clipboard",
                    description: Text("Import a Fountain file or add an act to start building your storyboard."))
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
            guard !importedActs.isEmpty else {
                print("[FountainImport] No acts found in file.")
                return
            }
            let name = FountainParser.storyboardName(from: url)
            onFountainImport?(importedActs, name)
        } catch {
            print("[FountainImport] Error reading file: \(error)")
        }
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
                        .background(Color.secondary.opacity(0.06))
                }
            }
        }
    }
}

// MARK: - Panel row

private struct PanelRow: View {
    @Binding var panel: PanelEntry
    @Binding var selection: StoryboardSelection?

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
    }

    private var panelIcon: some View {
        Image(systemName: "photo")
            .foregroundStyle(.blue).frame(width: 16)
    }
}
