import SwiftUI

/// Center pane — adapts to the selected phase.
/// Casting phase: two sub-sections (Cast + Locations) with independent +/- controls.
/// Other phases: generic single-section grid.
struct ItemBrowserView: View {

    let section: AppSection?
    @Binding var selectedCastingItem: CastingItem?

    // Generic phases
    @Binding var selectedItemID: String?

    var body: some View {
        VStack(spacing: 0) {
            BrowserHeaderView(section: section)
            Divider()

            if section == .casting {
                CastingBrowserView(selectedItem: $selectedCastingItem)
            } else {
                GenericBrowserView(section: section, selectedItemID: $selectedItemID)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onChange(of: section) { _, _ in
            selectedCastingItem = nil
            selectedItemID = nil
        }
    }
}

// MARK: - Header

private struct BrowserHeaderView: View {
    let section: AppSection?
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if let section {
                Image(systemName: section.icon)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(section.title)
                    .font(.title2.bold())
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Casting browser (Cast + Locations split)

struct CastingBrowserView: View {

    @Binding var selectedItem: CastingItem?
    @State private var characters: [CastingItem] = MockData.castingCharacters
    @State private var locations: [CastingItem]  = MockData.castingLocations

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                CastingSubSectionView(
                    title: "Cast",
                    items: $characters,
                    selectedItem: $selectedItem,
                    itemType: .character
                )
                Divider().padding(.vertical, 4)
                CastingSubSectionView(
                    title: "Locations",
                    items: $locations,
                    selectedItem: $selectedItem,
                    itemType: .location
                )
            }
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Sub-section (Cast or Locations)

private struct CastingSubSectionView: View {

    let title: String
    @Binding var items: [CastingItem]
    @Binding var selectedItem: CastingItem?
    let itemType: CastingItemType

    private let columns = [GridItem(.adaptive(minimum: 110, maximum: 150), spacing: 10)]

    var body: some View {
        VStack(spacing: 0) {
            // Section header row
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                // − button
                Button {
                    guard let sel = selectedItem,
                          let idx = items.firstIndex(where: { $0.id == sel.id }) else { return }
                    items.remove(at: idx)
                    selectedItem = nil
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .disabled(selectedItem == nil || !items.contains(where: { $0.id == selectedItem?.id }))
                // + button
                Button {
                    let newItem = CastingItem(
                        id: UUID().uuidString,
                        name: itemType == .character ? "New Character" : "New Location",
                        description: "",
                        type: itemType,
                        status: .notYetGenerated,
                        libraryLevel: .episode,
                        variantCount: 0,
                        approvedVariant: nil
                    )
                    items.append(newItem)
                    selectedItem = newItem
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 6)

            if items.isEmpty {
                Text("No \(title.lowercased()) yet — tap + to add one.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(items) { item in
                        CastingTileView(
                            item: item,
                            isSelected: selectedItem?.id == item.id
                        )
                        .onTapGesture { selectedItem = item }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }
        }
    }
}

// MARK: - Tile

private struct CastingTileView: View {

    let item: CastingItem
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(tileColor.opacity(0.15))
                    .overlay {
                        Image(systemName: tileIcon)
                            .font(.system(size: 28))
                            .foregroundStyle(tileColor)
                    }
                    .frame(height: 80)

                // Status dot
                Circle()
                    .fill(item.status.color)
                    .frame(width: 8, height: 8)
                    .padding(5)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )

            Text(item.name)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor.opacity(0.07) : Color.clear)
        )
    }

    private var tileColor: Color {
        item.type == .character ? .blue : .teal
    }

    private var tileIcon: String {
        item.type == .character ? "person.fill" : "map"
    }
}

// MARK: - Generic browser (non-casting phases)

private struct GenericBrowserView: View {

    let section: AppSection?
    @Binding var selectedItemID: String?
    private let columns = [GridItem(.adaptive(minimum: 130, maximum: 170), spacing: 12)]

    var body: some View {
        let items = MockData.items(for: section)
        if items.isEmpty {
            ContentUnavailableView(
                "No items yet",
                systemImage: section?.icon ?? "tray",
                description: Text("Items will appear here once created.")
            )
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items) { item in
                        GenericTileView(item: item, isSelected: selectedItemID == item.id)
                            .onTapGesture { selectedItemID = item.id }
                    }
                }
                .padding(16)
            }
        }
    }
}

private struct GenericTileView: View {
    let item: MockItem
    let isSelected: Bool
    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 10)
                .fill(item.color.opacity(0.15))
                .overlay {
                    Image(systemName: item.icon)
                        .font(.system(size: 32))
                        .foregroundStyle(item.color)
                }
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                )
            Text(item.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.07) : Color.clear)
        )
    }
}

#Preview {
    @Previewable @State var sel: CastingItem? = nil
    @Previewable @State var selID: String? = nil
    ItemBrowserView(section: .casting, selectedCastingItem: $sel, selectedItemID: $selID)
        .frame(width: 480, height: 600)
}
