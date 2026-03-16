import SwiftUI

/// Center pane — adapts to the selected phase.
/// Briefing: Studio → Customer → Episode hierarchy.
/// Casting:  Cast + Locations sub-sections.
/// Other:    generic single-section grid.
struct ItemBrowserView: View {

    let section: AppSection?

    // Briefing hierarchy
    @Binding var studios: [MockStudio]
    @Binding var selectedStudioID: String?
    @Binding var selectedCustomerID: String?
    @Binding var selectedEpisodeID: String?
    @Binding var selectedBriefingLevel: BriefingLevel

    // Casting
    @Binding var selectedCastingItem: CastingItem?

    // Generic phases
    @Binding var selectedItemID: String?

    var body: some View {
        VStack(spacing: 0) {
            BrowserHeaderView(section: section)
            Divider()

            switch section {
            case .briefing:
                BriefingBrowserView(
                    studios: $studios,
                    selectedStudioID: $selectedStudioID,
                    selectedCustomerID: $selectedCustomerID,
                    selectedEpisodeID: $selectedEpisodeID,
                    selectedBriefingLevel: $selectedBriefingLevel
                )
            case .casting:
                CastingBrowserView(selectedItem: $selectedCastingItem)
            default:
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
                Button {
                    let newID = UUID().uuidString
                    let newItem = CastingItem(
                        id: newID,
                        name: itemType == .character ? "New Character" : "New Location",
                        description: "",
                        type: itemType,
                        gender: itemType == .character ? .male : nil,
                        locationSetting: itemType == .location ? .interior : nil,
                        status: .nothingGenerated,
                        libraryLevel: .episode,
                        variants: CastingItem.emptyVariants(prefix: newID)
                    )
                    items.append(newItem)
                    selectedItem = newItem
                } label: {
                    Label("Add from Library", systemImage: "plus.rectangle.on.folder")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 6)

            if items.isEmpty {
                Text("No \(title.lowercased()) yet — add one from the library.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(items) { item in
                        CastingTileView(
                            item: item,
                            isSelected: selectedItem?.id == item.id,
                            onDelete: {
                                if let idx = items.firstIndex(where: { $0.id == item.id }) {
                                    items.remove(at: idx)
                                    if selectedItem?.id == item.id {
                                        selectedItem = nil
                                    }
                                }
                            }
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
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(tileColor.opacity(0.15))
                    .overlay {
                        Image(systemName: tileIcon)
                            .font(.system(size: 28))
                            .foregroundStyle(tileColor)
                    }
                    .frame(height: 80)

                // Status dot — bottom trailing
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(item.status.color)
                            .frame(width: 8, height: 8)
                            .padding(5)
                    }
                }

                // Delete button — top trailing
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            onDelete?()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .secondary)
                        }
                        .buttonStyle(.plain)
                        .padding(3)
                    }
                    Spacer()
                }
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
        if item.type == .character {
            return item.gender?.icon ?? "person.fill"
        } else {
            return item.locationSetting?.icon ?? "map"
        }
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
    @Previewable @State var studios = MockData.defaultStudios
    @Previewable @State var studioID: String? = MockData.defaultStudios[0].id
    @Previewable @State var customerID: String? = MockData.defaultStudios[0].customers[0].id
    @Previewable @State var episodeID: String? = MockData.defaultStudios[0].customers[0].episodes[0].id
    @Previewable @State var briefingLevel: BriefingLevel = .episode
    @Previewable @State var sel: CastingItem? = nil
    @Previewable @State var selID: String? = nil

    ItemBrowserView(
        section: .briefing,
        studios: $studios,
        selectedStudioID: $studioID,
        selectedCustomerID: $customerID,
        selectedEpisodeID: $episodeID,
        selectedBriefingLevel: $briefingLevel,
        selectedCastingItem: $sel,
        selectedItemID: $selID
    )
    .frame(width: 480, height: 600)
}
