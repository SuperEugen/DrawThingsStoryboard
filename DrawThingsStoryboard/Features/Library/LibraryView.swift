import SwiftUI

/// Center pane for the Library section.
/// Three vertically stacked areas — Studio, Customer, Episodes —
/// each showing their characters + locations as thumbnail grids.
/// Studio and Customer selection uses left/right arrow buttons in the header.
struct LibraryBrowserView: View {

    @Binding var studios: [MockStudio]
    @Binding var selectedItem: CastingItem?

    // MARK: - Local navigation state

    @State private var studioIndex: Int = 0
    @State private var customerIndex: Int = 0

    // MARK: - Derived data

    private var studio: MockStudio? {
        guard studios.indices.contains(studioIndex) else { return nil }
        return studios[studioIndex]
    }

    private var customers: [MockCustomer] {
        studio?.customers ?? []
    }

    private var customer: MockCustomer? {
        guard customers.indices.contains(customerIndex) else { return nil }
        return customers[customerIndex]
    }

    private var episodes: [MockEpisode] {
        customer?.episodes ?? []
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "photo.stack")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Library")
                    .font(.title2.bold())
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                VStack(spacing: 0) {

                    // ── Studio section ──────────────────────────
                    if let studio {
                        LibraryLevelHeader(
                            icon: "building.columns",
                            iconColor: .purple,
                            name: studio.name,
                            canGoBack: studioIndex > 0,
                            canGoForward: studioIndex < studios.count - 1,
                            onBack: {
                                studioIndex -= 1
                                customerIndex = 0
                                selectedItem = nil
                            },
                            onForward: {
                                studioIndex += 1
                                customerIndex = 0
                                selectedItem = nil
                            }
                        )

                        LibraryCastGrid(
                            characters: studio.characters,
                            locations: studio.locations,
                            selectedItem: $selectedItem,
                            emptyText: "No studio-level assets."
                        )
                    }

                    Divider().padding(.vertical, 6)

                    // ── Customer section ────────────────────────
                    if let customer {
                        LibraryLevelHeader(
                            icon: "person.text.rectangle",
                            iconColor: .teal,
                            name: customer.name,
                            canGoBack: customerIndex > 0,
                            canGoForward: customerIndex < customers.count - 1,
                            onBack: {
                                customerIndex -= 1
                                selectedItem = nil
                            },
                            onForward: {
                                customerIndex += 1
                                selectedItem = nil
                            }
                        )

                        // Customer-level assets: aggregate from all episodes
                        let custChars = customer.episodes.flatMap(\.characters)
                            .filter { $0.libraryLevel == .customer }
                        let custLocs = customer.episodes.flatMap(\.locations)
                            .filter { $0.libraryLevel == .customer }

                        LibraryCastGrid(
                            characters: custChars,
                            locations: custLocs,
                            selectedItem: $selectedItem,
                            emptyText: "No customer-level assets."
                        )
                    } else {
                        Text("No customers in this studio.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 12)
                    }

                    Divider().padding(.vertical, 6)

                    // ── Episodes section ────────────────────────
                    if episodes.isEmpty {
                        HStack {
                            Label("Episodes", systemImage: "film")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 10)
                        Text("No episodes for this customer.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 12)
                    } else {
                        ForEach(Array(episodes.enumerated()), id: \.element.id) { idx, episode in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "film")
                                        .foregroundStyle(.blue)
                                        .frame(width: 16)
                                    Text(episode.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.top, idx == 0 ? 10 : 6)

                                LibraryCastGrid(
                                    characters: episode.characters.filter { $0.libraryLevel == .episode },
                                    locations: episode.locations.filter { $0.libraryLevel == .episode },
                                    selectedItem: $selectedItem,
                                    emptyText: "No assets in this episode."
                                )
                            }

                            if idx < episodes.count - 1 {
                                Divider().padding(.vertical, 4).padding(.horizontal, 14)
                            }
                        }
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onChange(of: studioIndex) { _, _ in
            // Clamp customer index when studio changes
            if customerIndex >= customers.count {
                customerIndex = max(0, customers.count - 1)
            }
        }
    }
}

// MARK: - Level header with left/right arrows

private struct LibraryLevelHeader: View {
    let icon: String
    let iconColor: Color
    let name: String
    let canGoBack: Bool
    let canGoForward: Bool
    let onBack: () -> Void
    let onForward: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 16)
            Text(name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.medium))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
            .disabled(!canGoBack)

            Button(action: onForward) {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.medium))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
            .disabled(!canGoForward)
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }
}

// MARK: - Compact cast grid (characters + locations in one section)

private struct LibraryCastGrid: View {
    let characters: [CastingItem]
    let locations: [CastingItem]
    @Binding var selectedItem: CastingItem?
    let emptyText: String
    var onDelete: ((String) -> Void)? = nil

    private let columns = [GridItem(.adaptive(minimum: 288, maximum: 320), spacing: 12)]

    var body: some View {
        if characters.isEmpty && locations.isEmpty {
            Text(emptyText)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(locations) { item in
                    libraryTile(item: item)
                        .onTapGesture { selectedItem = item }
                }
                ForEach(characters) { item in
                    libraryTile(item: item)
                        .onTapGesture { selectedItem = item }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
        }
    }

    private func levelBadgeColor(for level: LibraryLevel) -> Color {
        switch level {
        case .studio:   return .purple
        case .customer: return .teal
        case .episode:  return .blue
        }
    }

    private func libraryTile(item: CastingItem) -> some View {
        let isSelected = selectedItem?.id == item.id
        let deleteAction: (() -> Void)? = { onDelete?(item.id) }
        return UnifiedThumbnailView(
            itemType: item.thumbnailType,
            name: item.name,
            sizeMode: .standard,
            badges: ThumbnailBadges(
                assetStatus: item.assetStatusFlags,
                showDeleteButton: deleteAction != nil,
                onDelete: deleteAction,
                levelBadgeText: String(item.libraryLevel.rawValue.prefix(2)).uppercased(),
                levelBadgeColor: levelBadgeColor(for: item.libraryLevel),
                showSelectionStroke: isSelected
            )
        )
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.07) : Color.clear)
        )
    }
}

#Preview {
    @Previewable @State var studios = MockData.defaultStudios
    @Previewable @State var sel: CastingItem? = nil
    LibraryBrowserView(studios: $studios, selectedItem: $sel)
        .frame(width: 400, height: 700)
}
