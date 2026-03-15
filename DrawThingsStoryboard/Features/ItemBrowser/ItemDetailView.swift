import SwiftUI

/// Right pane — switches between casting detail and generic detail.
struct ItemDetailView: View {

    let section: AppSection?
    @Binding var selectedCastingItem: CastingItem?
    let selectedItemID: String?

    var body: some View {
        if section == .casting {
            if let item = selectedCastingItem {
                CastingItemDetailView(item: Binding(
                    get: { item },
                    set: { selectedCastingItem = $0 }
                ))
            } else {
                emptyState
            }
        } else {
            if let itemID = selectedItemID,
               let item = MockData.items(for: section).first(where: { $0.id == itemID }) {
                GenericDetailView(item: item)
            } else {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nothing selected",
            systemImage: "square.dashed",
            description: Text("Select an item to see its properties.")
        )
    }
}

// MARK: - Casting detail

struct CastingItemDetailView: View {
    @Binding var item: CastingItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ThumbnailSection(item: item)
                StatusSection(item: $item)
                Divider().padding(.vertical, 8)
                LibraryLevelSection(item: $item)
                Divider().padding(.vertical, 8)
                NameSection(item: $item)
                DescriptionSection(item: $item)
                Divider().padding(.vertical, 8)
                ProductionSection(item: $item)
                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - ThumbnailSection

private struct ThumbnailSection: View {
    let item: CastingItem
    private var typeLabel: String     { item.type == .character ? "Character" : "Location" }
    private var thumbnailColor: Color { item.type == .character ? .blue : .teal }
    private var thumbnailIcon: String { item.type == .character ? "person.fill" : "map" }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(thumbnailColor.opacity(0.12))
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .overlay {
                    Image(systemName: thumbnailIcon)
                        .font(.system(size: 52))
                        .foregroundStyle(thumbnailColor.opacity(0.6))
                }
            Text(typeLabel)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial, in: Capsule())
                .foregroundStyle(.secondary)
                .padding(10)
        }
        .padding(.bottom, 16)
    }
}

// MARK: - StatusSection

private struct StatusSection: View {
    @Binding var item: CastingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Status")
            VStack(spacing: 4) {
                statusRow(GenerationStatus.notYetGenerated)
                statusRow(GenerationStatus.previewGenerated)
                statusRow(GenerationStatus.finalGenerated)
            }
        }
        .padding(.bottom, 12)
    }

    private func statusRow(_ s: GenerationStatus) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(s.color)
                .frame(width: 8, height: 8)
            Text(s.label)
                .font(.callout)
            Spacer()
            if item.status == s {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(item.status == s ? Color.accentColor.opacity(0.07) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { item.status = s }
    }
}

// MARK: - LibraryLevelSection

private struct LibraryLevelSection: View {
    @Binding var item: CastingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Library level")
            VStack(spacing: 4) {
                levelRow(LibraryLevel.studio)
                levelRow(LibraryLevel.customer)
                levelRow(LibraryLevel.episode)
            }
        }
        .padding(.bottom, 12)
    }

    private func levelRow(_ level: LibraryLevel) -> some View {
        HStack(spacing: 8) {
            Image(systemName: level.icon)
                .frame(width: 16)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(level.rawValue)
                    .font(.callout)
                Text(level.description)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            if item.libraryLevel == level {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(item.libraryLevel == level ? Color.accentColor.opacity(0.07) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { item.libraryLevel = level }
    }
}

// MARK: - NameSection

private struct NameSection: View {
    @Binding var item: CastingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Name")
            TextField("Name", text: $item.name)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.bottom, 12)
    }
}

// MARK: - DescriptionSection

private struct DescriptionSection: View {
    @Binding var item: CastingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Description")
            TextEditor(text: $item.description)
                .font(.callout)
                .frame(minHeight: 72)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
                )
        }
        .padding(.bottom, 12)
    }
}

// MARK: - ProductionSection

private struct ProductionSection: View {
    @Binding var item: CastingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Production")
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Variants")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(item.variantCount)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                if let approved = item.approvedVariant {
                    HStack {
                        Text("Approved variant")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("#\(approved)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Color.green)
                    }
                }
                Button {
                    // TODO: queue logic
                } label: {
                    Label("Queue for Production", systemImage: "film.stack")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .disabled(item.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Generic detail

private struct GenericDetailView: View {
    let item: MockItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color.opacity(0.12))
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .overlay {
                        Image(systemName: item.icon)
                            .font(.system(size: 44))
                            .foregroundStyle(item.color)
                    }
                Text(item.name).font(.title3.bold())
                Divider()
                LabeledContent("Status")   { Text(item.status).foregroundStyle(.secondary) }
                LabeledContent("Variants") { Text("\(item.variantCount)").foregroundStyle(.secondary) }
                LabeledContent("ID")       { Text(item.id).font(.caption.monospaced()).foregroundStyle(.tertiary) }
                Spacer()
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Shared free function

private func sectionLabel(_ title: String) -> some View {
    Text(title)
        .font(.caption)
        .foregroundStyle(.tertiary)
        .textCase(.uppercase)
        .tracking(0.5)
}

#Preview {
    @Previewable @State var item: CastingItem? = MockData.castingCharacters.first
    ItemDetailView(section: .casting, selectedCastingItem: $item, selectedItemID: nil)
        .frame(width: 280, height: 700)
}
