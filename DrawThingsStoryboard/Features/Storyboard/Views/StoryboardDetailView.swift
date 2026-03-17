import SwiftUI

/// Right pane for the Storyboard section.
/// Shows properties (Name, Description) for the selected Act, Sequence, Scene, or Panel.
struct StoryboardDetailView: View {

    @Binding var acts: [MockAct]
    let selection: StoryboardSelection?

    var body: some View {
        if let selection {
            switch selection {
            case .act(let id):
                if let actIdx = acts.firstIndex(where: { $0.id == id }) {
                    StoryboardNodeDetailView(
                        level: .act,
                        name: $acts[actIdx].name,
                        description: $acts[actIdx].description
                    )
                } else {
                    emptyState
                }

            case .sequence(let id):
                if let (ai, si) = findSequenceIndices(id) {
                    StoryboardNodeDetailView(
                        level: .sequence,
                        name: $acts[ai].sequences[si].name,
                        description: $acts[ai].sequences[si].description
                    )
                } else {
                    emptyState
                }

            case .scene(let id):
                if let (ai, si, sci) = findSceneIndices(id) {
                    StoryboardNodeDetailView(
                        level: .scene,
                        name: $acts[ai].sequences[si].scenes[sci].name,
                        description: $acts[ai].sequences[si].scenes[sci].description
                    )
                } else {
                    emptyState
                }

            case .panel(let id):
                if let (ai, si, sci, pi) = findPanelIndices(id) {
                    StoryboardPanelDetailView(
                        panel: $acts[ai].sequences[si].scenes[sci].panels[pi]
                    )
                } else {
                    emptyState
                }
            }
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nothing selected",
            systemImage: "square.dashed",
            description: Text("Select an act, sequence, scene, or panel to see its properties.")
        )
    }

    // MARK: - Index lookup helpers

    private func findSequenceIndices(_ id: String) -> (Int, Int)? {
        for ai in acts.indices {
            for si in acts[ai].sequences.indices {
                if acts[ai].sequences[si].id == id {
                    return (ai, si)
                }
            }
        }
        return nil
    }

    private func findSceneIndices(_ id: String) -> (Int, Int, Int)? {
        for ai in acts.indices {
            for si in acts[ai].sequences.indices {
                for sci in acts[ai].sequences[si].scenes.indices {
                    if acts[ai].sequences[si].scenes[sci].id == id {
                        return (ai, si, sci)
                    }
                }
            }
        }
        return nil
    }

    private func findPanelIndices(_ id: String) -> (Int, Int, Int, Int)? {
        for ai in acts.indices {
            for si in acts[ai].sequences.indices {
                for sci in acts[ai].sequences[si].scenes.indices {
                    for pi in acts[ai].sequences[si].scenes[sci].panels.indices {
                        if acts[ai].sequences[si].scenes[sci].panels[pi].id == id {
                            return (ai, si, sci, pi)
                        }
                    }
                }
            }
        }
        return nil
    }
}

// MARK: - Node detail (Act / Sequence / Scene)

private struct StoryboardNodeDetailView: View {
    let level: StoryboardLevel
    @Binding var name: String
    @Binding var description: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Type badge header
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(level.color.opacity(0.12))
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .overlay {
                            Image(systemName: level.icon)
                                .font(.system(size: 40))
                                .foregroundStyle(level.color.opacity(0.6))
                        }
                    Text(level.label)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())
                        .foregroundStyle(.secondary)
                        .padding(10)
                }

                Divider().padding(.vertical, 8)

                // Name
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Name")
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.bottom, 16)

                // Description
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Description")
                    TextEditor(text: $description)
                        .font(.callout)
                        .frame(minHeight: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
                        )
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

private struct StoryboardPanelDetailView: View {
    @Binding var panel: MockPanel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Thumbnail header
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(StoryboardLevel.panel.color.opacity(0.12))
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 52))
                                .foregroundStyle(StoryboardLevel.panel.color.opacity(0.6))
                        }
                    Text("Panel")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())
                        .foregroundStyle(.secondary)
                        .padding(10)
                }
                .padding(.bottom, 16)

                // Status
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Status")
                    HStack(spacing: 8) {
                        Circle()
                            .fill(panel.status.color)
                            .frame(width: 8, height: 8)
                        Text(panel.status.label)
                            .font(.callout)
                        Spacer()
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.accentColor.opacity(0.07))
                    )
                }
                .padding(.bottom, 12)

                Divider().padding(.vertical, 8)

                // Name
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Name")
                    TextField("Name", text: $panel.name)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.bottom, 12)

                // Description
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Description")
                    TextEditor(text: $panel.description)
                        .font(.callout)
                        .frame(minHeight: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
                        )
                }
                .padding(.bottom, 12)

                Divider().padding(.vertical, 8)

                // Variants
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Variants")
                    Text("\(panel.generatedCount) of 4 generated")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 12)

                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Shared section label helper

private func sectionLabel(_ title: String) -> some View {
    Text(title)
        .font(.caption)
        .foregroundStyle(.tertiary)
        .textCase(.uppercase)
        .tracking(0.5)
}

#Preview {
    @Previewable @State var acts = MockData.sampleActs
    StoryboardDetailView(acts: $acts, selection: .act("act-01"))
        .frame(width: 300, height: 600)
}
