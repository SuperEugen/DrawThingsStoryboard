import SwiftUI

/// Right pane for the Storyboard section.
struct StoryboardDetailView: View {

    @Binding var acts: [ActEntry]
    let selection: StoryboardSelection?
    @Binding var generationQueue: [GenerationJob]
    let assets: AssetsFile
    var resolvedStyleName: String? = nil
    var styleDescription: String = ""
    var config: AppConfig = AppConfig()

    var body: some View {
        if let selection {
            switch selection {
            case .act(let name):
                if let idx = acts.firstIndex(where: { $0.name == name }) {
                    NodeDetailView(level: "Act", name: $acts[idx].name, color: .purple, icon: "theatermask.and.paintbrush")
                } else { emptyState }

            case .sequence(let name):
                if let (ai, si) = findSequence(name) {
                    NodeDetailView(level: "Sequence", name: $acts[ai].sequences[si].name, color: .orange, icon: "arrow.triangle.branch")
                } else { emptyState }

            case .scene(let name):
                if let (ai, si, sci) = findScene(name) {
                    NodeDetailView(level: "Scene", name: $acts[ai].sequences[si].scenes[sci].name, color: .teal, icon: "rectangle.on.rectangle")
                } else { emptyState }

            case .panel(let id):
                if let (ai, si, sci, pi) = findPanel(id) {
                    PanelDetailView(
                        panel: $acts[ai].sequences[si].scenes[sci].panels[pi],
                        generationQueue: $generationQueue,
                        assets: assets,
                        resolvedStyleName: resolvedStyleName,
                        styleDescription: styleDescription,
                        config: config
                    )
                } else { emptyState }
            }
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nothing selected", systemImage: "square.dashed",
            description: Text("Select an act, sequence, scene, or panel."))
    }

    private func findSequence(_ name: String) -> (Int, Int)? {
        for ai in acts.indices {
            for si in acts[ai].sequences.indices {
                if acts[ai].sequences[si].name == name { return (ai, si) }
            }
        }
        return nil
    }

    private func findScene(_ name: String) -> (Int, Int, Int)? {
        for ai in acts.indices {
            for si in acts[ai].sequences.indices {
                for sci in acts[ai].sequences[si].scenes.indices {
                    if acts[ai].sequences[si].scenes[sci].name == name { return (ai, si, sci) }
                }
            }
        }
        return nil
    }

    private func findPanel(_ id: String) -> (Int, Int, Int, Int)? {
        for ai in acts.indices {
            for si in acts[ai].sequences.indices {
                for sci in acts[ai].sequences[si].scenes.indices {
                    for pi in acts[ai].sequences[si].scenes[sci].panels.indices {
                        if acts[ai].sequences[si].scenes[sci].panels[pi].panelID == id { return (ai, si, sci, pi) }
                    }
                }
            }
        }
        return nil
    }
}

// MARK: - Node detail (Act / Sequence / Scene)

private struct NodeDetailView: View {
    let level: String
    @Binding var name: String
    let color: Color
    let icon: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.12))
                        .frame(maxWidth: .infinity).frame(height: 100)
                        .overlay {
                            Image(systemName: icon).font(.system(size: 40))
                                .foregroundStyle(color.opacity(0.6))
                        }
                    Text(level).font(.caption.weight(.medium))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())
                        .foregroundStyle(.secondary).padding(10)
                }

                Divider().padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Name")
                    TextField("Name", text: $name).textFieldStyle(.roundedBorder)
                }
                .padding(.bottom, 16)

                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Panel detail

private struct PanelDetailView: View {
    @Binding var panel: PanelEntry
    @Binding var generationQueue: [GenerationJob]
    let assets: AssetsFile
    var resolvedStyleName: String? = nil
    var styleDescription: String = ""
    var config: AppConfig = AppConfig()

    private var attachedAssets: [AssetEntry] {
        panel.refIDs.compactMap { refID in
            assets.assets.first { $0.assetID == refID }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                UnifiedThumbnailView(itemType: .panel, name: "", sizeMode: .header)
                    .padding(.bottom, 16)

                // Status
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Status")
                    statusRow(label: "Small Image", available: panel.hasSmallImage, letter: "S")
                    statusRow(label: "Large Image", available: panel.hasLargeImage, letter: "L")
                }
                .padding(.bottom, 12)

                Divider().padding(.vertical, 8)

                // Name
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Name")
                    TextField("Name", text: $panel.name).textFieldStyle(.roundedBorder)
                }
                .padding(.bottom, 12)

                // Description
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Description")
                    TextEditor(text: $panel.description).font(.callout).frame(minHeight: 80)
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5))
                }
                .padding(.bottom, 12)

                // Camera Movement
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Camera Movement")
                    TextField("e.g. Pan left, Zoom in", text: $panel.cameraMovement)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.bottom, 12)

                // Dialogue
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Dialogue")
                    TextEditor(text: $panel.dialogue).font(.callout).frame(minHeight: 60)
                        .overlay(RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5))
                }
                .padding(.bottom, 12)

                // Duration
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Duration")
                    HStack {
                        TextField("Seconds", value: $panel.duration, format: .number)
                            .textFieldStyle(.roundedBorder).frame(width: 80)
                        Text("seconds").font(.callout).foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 12)

                Divider().padding(.vertical, 8)

                // Referenced Assets
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Referenced Assets (\(attachedAssets.count)/4)")
                    if attachedAssets.isEmpty {
                        Text("No assets referenced.").font(.caption).foregroundStyle(.tertiary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(attachedAssets) { asset in
                            HStack(spacing: 8) {
                                Image(systemName: asset.isCharacter ? "person.fill" : "map")
                                    .foregroundStyle(asset.isCharacter ? .blue : .teal)
                                Text(asset.name).font(.callout)
                                Spacer()
                                Text(asset.subType).font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4).padding(.horizontal, 8)
                            .background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.05)))
                        }
                    }
                }
                .padding(.bottom, 12)

                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    @ViewBuilder
    private func statusRow(label: String, available: Bool, letter: String) -> some View {
        HStack(spacing: 8) {
            Text(letter).font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(available ? .green : .gray)
            Text("\(label):").font(.callout)
            Text(available ? "available" : "not yet").font(.callout)
                .foregroundStyle(available ? .green : .secondary)
            Spacer()
        }
        .padding(.vertical, 5).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 7).fill(Color.accentColor.opacity(0.07)))
    }
}
