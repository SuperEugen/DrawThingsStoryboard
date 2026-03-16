import SwiftUI

/// Library view — lets the user navigate the asset hierarchy:
/// Studio  →  Customer  →  Episode
/// At each level, Cast and Locations sub-sections are shown.
struct LibraryView: View {

    // Navigation state
    @State private var selectedCustomerID: String? = nil
    @State private var selectedEpisodeID:  String? = nil
    @State private var selectedItem: CastingItem? = nil

    private var studio: MockStudio { MockData.libraryTree }

    private var selectedCustomer: MockCustomer? {
        guard let id = selectedCustomerID else { return nil }
        return studio.customers.first { $0.id == id }
    }

    private var selectedEpisode: MockEpisode? {
        guard let id = selectedEpisodeID else { return nil }
        return selectedCustomer?.episodes.first { $0.id == id }
    }

    // Derived: which characters/locations to show in center pane
    private var visibleCharacters: [CastingItem] {
        if let ep = selectedEpisode  { return ep.characters }
        if let cu = selectedCustomer { return cu.episodes.flatMap(\.characters) }
        return studio.customers.flatMap { $0.episodes.flatMap(\.characters) } + studio.characters
    }

    private var visibleLocations: [CastingItem] {
        if let ep = selectedEpisode  { return ep.locations }
        if let cu = selectedCustomer { return cu.episodes.flatMap(\.locations) }
        return studio.customers.flatMap { $0.episodes.flatMap(\.locations) } + studio.locations
    }

    var body: some View {
        HSplitView {
            // ── Left: level navigator ────────────────────────────────
            LibraryLevelNavigator(
                studio: studio,
                selectedCustomerID: $selectedCustomerID,
                selectedEpisodeID: $selectedEpisodeID
            )
            .frame(minWidth: 180, idealWidth: 210, maxWidth: 240)

            // ── Center: item grid ────────────────────────────────────
            LibraryItemBrowser(
                characters: visibleCharacters,
                locations: visibleLocations,
                selectedItem: $selectedItem,
                levelLabel: currentLevelLabel
            )
            .frame(minWidth: 280, maxHeight: .infinity)

            // ── Right: detail ────────────────────────────────────────
            Group {
                if var item = selectedItem {
                    CastingItemDetailView(item: Binding(
                        get: { item },
                        set: { selectedItem = $0; item = $0 }
                    ))
                } else {
                    ContentUnavailableView(
                        "Nothing selected",
                        systemImage: "square.dashed",
                        description: Text("Select an asset to see its properties.")
                    )
                }
            }
            .frame(minWidth: 260, idealWidth: 280, maxWidth: 320, maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
        .onChange(of: selectedCustomerID) { _, _ in
            selectedEpisodeID = nil
            selectedItem = nil
        }
        .onChange(of: selectedEpisodeID) { _, _ in
            selectedItem = nil
        }
    }

    private var currentLevelLabel: String {
        if let ep = selectedEpisode   { return ep.name }
        if let cu = selectedCustomer  { return cu.name }
        return studio.name
    }
}

// MARK: - Level navigator (left panel inside Library)

private struct LibraryLevelNavigator: View {

    let studio: MockStudio
    @Binding var selectedCustomerID: String?
    @Binding var selectedEpisodeID: String?

    var body: some View {
        List(selection: $selectedCustomerID) {

            // Studio level row
            HStack(spacing: 6) {
                Image(systemName: "building.columns")
                    .foregroundStyle(.purple)
                    .frame(width: 16)
                Text(studio.name)
                    .font(.callout.weight(.medium))
            }
            .padding(.vertical, 2)
            .tag(Optional<String>.none as String?)
            .onTapGesture {
                selectedCustomerID = nil
                selectedEpisodeID = nil
            }

            Divider()

            // Customers + episodes
            ForEach(studio.customers) { customer in
                Section {
                    ForEach(customer.episodes) { episode in
                        HStack(spacing: 6) {
                            Image(systemName: "film")
                                .foregroundStyle(.blue)
                                .font(.caption)
                                .frame(width: 16)
                            Text(episode.name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 1)
                        .tag(episode.id)
                        .onTapGesture {
                            selectedCustomerID = customer.id
                            selectedEpisodeID = episode.id
                        }
                    }
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.text.rectangle")
                            .foregroundStyle(.teal)
                            .frame(width: 16)
                        Text(customer.name)
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedCustomerID = customer.id
                        selectedEpisodeID = nil
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Library")
    }
}

// MARK: - Item browser inside Library

private struct LibraryItemBrowser: View {

    let characters: [CastingItem]
    let locations: [CastingItem]
    @Binding var selectedItem: CastingItem?
    let levelLabel: String

    private let columns = [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 10)]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "photo.stack")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(levelLabel)
                    .font(.title2.bold())
                    .lineLimit(1)
                Spacer()
                Text("\(characters.count + locations.count) assets")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    LibrarySubGrid(
                        title: "Characters",
                        items: characters,
                        selectedItem: $selectedItem,
                        columns: columns
                    )

                    Divider().padding(.vertical, 6)

                    LibrarySubGrid(
                        title: "Locations",
                        items: locations,
                        selectedItem: $selectedItem,
                        columns: columns
                    )
                }
                .padding(.bottom, 16)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Sub-grid (Characters or Locations) inside Library

private struct LibrarySubGrid: View {

    let title: String
    let items: [CastingItem]
    @Binding var selectedItem: CastingItem?
    let columns: [GridItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                // Library level badge legend
                LibraryLevelBadgeLegend()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 6)

            if items.isEmpty {
                Text("No \(title.lowercased()) at this level.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(items) { item in
                        LibraryTileView(item: item, isSelected: selectedItem?.id == item.id)
                            .onTapGesture { selectedItem = item }
                    }
                }
                .padding(.horizontal, 14)
            }
        }
    }
}

// MARK: - Library tile (shows library level badge)

private struct LibraryTileView: View {

    let item: CastingItem
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(tileColor.opacity(0.13))
                    .frame(height: 76)
                    .overlay {
                        Image(systemName: tileIcon)
                            .font(.system(size: 26))
                            .foregroundStyle(tileColor.opacity(0.7))
                    }

                // Library level badge
                Text(item.libraryLevel.rawValue.prefix(2).uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(levelBadgeColor.opacity(0.2), in: RoundedRectangle(cornerRadius: 3))
                    .foregroundStyle(levelBadgeColor)
                    .padding(4)

                // Status dot bottom-left
                Circle()
                    .fill(item.status.color)
                    .frame(width: 7, height: 7)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(5)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )

            Text(item.name)
                .font(.caption2)
                .lineLimit(1)
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
        }
        .padding(4)
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

    private var levelBadgeColor: Color {
        switch item.libraryLevel {
        case .studio:   return .purple
        case .customer: return .teal
        case .episode:  return .blue
        }
    }
}

// MARK: - Badge legend

private struct LibraryLevelBadgeLegend: View {
    var body: some View {
        HStack(spacing: 6) {
            ForEach([("ST", Color.purple), ("CU", .teal), ("EP", .blue)], id: \.0) { abbr, color in
                Text(abbr)
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 3))
                    .foregroundStyle(color)
            }
        }
    }
}

#Preview {
    LibraryView()
        .frame(width: 900, height: 600)
}
