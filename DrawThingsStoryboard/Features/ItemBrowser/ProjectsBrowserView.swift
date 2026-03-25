import SwiftUI

/// Center pane for the Projects section.
/// Three vertically stacked sub-sections: Studio → Customer → Episode.
/// Selecting a studio filters the customers; selecting a customer filters the episodes.
struct ProjectsBrowserView: View {

    @Binding var studios: [MockStudio]
    @Binding var selectedStudioID: String?
    @Binding var selectedCustomerID: String?
    @Binding var selectedEpisodeID: String?
    @Binding var selectedProjectsLevel: ProjectsLevel

    // MARK: - Derived indices

    private var studioIndex: Int? {
        studios.firstIndex { $0.id == selectedStudioID }
    }

    private var customers: [MockCustomer] {
        guard let si = studioIndex else { return [] }
        return studios[si].customers
    }

    private var customerIndex: Int? {
        guard let si = studioIndex else { return nil }
        return studios[si].customers.firstIndex { $0.id == selectedCustomerID }
    }

    private var episodes: [MockEpisode] {
        guard let si = studioIndex, let ci = customerIndex else { return [] }
        return studios[si].customers[ci].episodes
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // --- Studio ---
                ProjectsSubSection(
                    title: "Studio",
                    icon: "building.columns",
                    items: studios.map { NamedID(id: $0.id, name: $0.name) },
                    selectedID: $selectedStudioID,
                    onAdd: addStudio,
                    onRemove: removeStudio,
                    onSelect: { newStudioID in
                        selectedProjectsLevel = .studio
                        guard let si = studios.firstIndex(where: { $0.id == newStudioID }) else { return }
                        let firstCust = studios[si].customers.first
                        selectedCustomerID = firstCust?.id
                        selectedEpisodeID = firstCust?.episodes.first?.id
                    },
                    onReselect: { selectedProjectsLevel = .studio }
                )

                Divider().padding(.vertical, 4)

                // --- Customer ---
                ProjectsSubSection(
                    title: "Customer",
                    icon: "person.text.rectangle",
                    items: customers.map { NamedID(id: $0.id, name: $0.name) },
                    selectedID: $selectedCustomerID,
                    onAdd: addCustomer,
                    onRemove: removeCustomer,
                    onSelect: { newCustID in
                        selectedProjectsLevel = .customer
                        guard let si = studioIndex,
                              let ci = studios[si].customers.firstIndex(where: { $0.id == newCustID }) else { return }
                        selectedEpisodeID = studios[si].customers[ci].episodes.first?.id
                    },
                    onReselect: { selectedProjectsLevel = .customer }
                )

                Divider().padding(.vertical, 4)

                // --- Episode ---
                ProjectsSubSection(
                    title: "Episode",
                    icon: "film",
                    items: episodes.map { NamedID(id: $0.id, name: $0.name) },
                    selectedID: $selectedEpisodeID,
                    onAdd: addEpisode,
                    onRemove: removeEpisode,
                    onSelect: { _ in selectedProjectsLevel = .episode },
                    onReselect: { selectedProjectsLevel = .episode }
                )
            }
            .padding(.bottom, 16)
        }
    }

    // MARK: - Add / Remove actions

    private func addStudio() {
        selectedProjectsLevel = .studio
        let new = MockStudio(
            id: UUID().uuidString, name: "Your Studio",
            customers: [
                MockCustomer(
                    id: UUID().uuidString, name: "Your Customer",
                    episodes: [
                        MockEpisode(id: UUID().uuidString, name: "First Episode",
                                    characters: [], locations: [])
                    ]
                )
            ],
            characters: [], locations: []
        )
        studios.append(new)
        selectedStudioID = new.id
        selectedCustomerID = new.customers[0].id
        selectedEpisodeID = new.customers[0].episodes[0].id
    }

    private func removeStudio() {
        guard let si = studioIndex, studios.count > 1 else { return }
        studios.remove(at: si)
        let fallback = studios[min(si, studios.count - 1)]
        selectedStudioID = fallback.id
        selectedCustomerID = fallback.customers.first?.id
        selectedEpisodeID = fallback.customers.first?.episodes.first?.id
        ensureMinimum()
    }

    private func addCustomer() {
        selectedProjectsLevel = .customer
        guard let si = studioIndex else { return }
        let ep = MockEpisode(id: UUID().uuidString, name: "First Episode",
                             characters: [], locations: [])
        let new = MockCustomer(id: UUID().uuidString, name: "Your Customer",
                               episodes: [ep])
        studios[si].customers.append(new)
        selectedCustomerID = new.id
        selectedEpisodeID = ep.id
    }

    private func removeCustomer() {
        guard let si = studioIndex, let ci = customerIndex,
              studios[si].customers.count > 1 else { return }
        studios[si].customers.remove(at: ci)
        let fallback = studios[si].customers[min(ci, studios[si].customers.count - 1)]
        selectedCustomerID = fallback.id
        selectedEpisodeID = fallback.episodes.first?.id
        ensureMinimum()
    }

    private func addEpisode() {
        selectedProjectsLevel = .episode
        guard let si = studioIndex, let ci = customerIndex else { return }
        let new = MockEpisode(id: UUID().uuidString, name: "First Episode",
                              characters: [], locations: [])
        studios[si].customers[ci].episodes.append(new)
        selectedEpisodeID = new.id
    }

    private func removeEpisode() {
        guard let si = studioIndex, let ci = customerIndex,
              let ei = episodes.firstIndex(where: { $0.id == selectedEpisodeID }),
              studios[si].customers[ci].episodes.count > 1 else { return }
        studios[si].customers[ci].episodes.remove(at: ei)
        let eps = studios[si].customers[ci].episodes
        selectedEpisodeID = eps[min(ei, eps.count - 1)].id
    }

    private func ensureMinimum() {
        guard let si = studioIndex else { return }
        if studios[si].customers.isEmpty {
            let ep = MockEpisode(id: UUID().uuidString, name: "First Episode",
                                 characters: [], locations: [])
            let cust = MockCustomer(id: UUID().uuidString, name: "Your Customer",
                                    episodes: [ep])
            studios[si].customers.append(cust)
            selectedCustomerID = cust.id
            selectedEpisodeID = ep.id
        }
        guard let ci = studios[si].customers.firstIndex(where: { $0.id == selectedCustomerID }) else { return }
        if studios[si].customers[ci].episodes.isEmpty {
            let ep = MockEpisode(id: UUID().uuidString, name: "First Episode",
                                 characters: [], locations: [])
            studios[si].customers[ci].episodes.append(ep)
            selectedEpisodeID = ep.id
        }
    }
}

// MARK: - Lightweight ID wrapper

struct NamedID: Identifiable {
    let id: String
    let name: String
}

// MARK: - Reusable sub-section

private struct ProjectsSubSection: View {

    let title: String
    let icon: String
    let items: [NamedID]
    @Binding var selectedID: String?
    let onAdd: () -> Void
    let onRemove: () -> Void
    var onSelect: ((String) -> Void)? = nil
    var onReselect: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "minus").frame(width: 22, height: 22)
                }
                .buttonStyle(.bordered).controlSize(.mini)
                .disabled(items.count <= 1)

                Button(action: onAdd) {
                    Image(systemName: "plus").frame(width: 22, height: 22)
                }
                .buttonStyle(.bordered).controlSize(.mini)
            }
            .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 6)

            if items.isEmpty {
                Text("No \(title.lowercased()) yet — tap + to add one.")
                    .font(.caption).foregroundStyle(.tertiary).padding(.vertical, 20)
            } else {
                VStack(spacing: 2) {
                    ForEach(items) { item in
                        ProjectsRow(name: item.name, isSelected: selectedID == item.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                let changed = selectedID != item.id
                                selectedID = item.id
                                if changed { onSelect?(item.id) } else { onReselect?() }
                            }
                    }
                }
                .padding(.horizontal, 14).padding(.bottom, 8)
            }
        }
    }
}

// MARK: - Row

private struct ProjectsRow: View {
    let name: String
    let isSelected: Bool

    var body: some View {
        HStack {
            Text(name).font(.body)
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 6).padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
        )
    }
}

#Preview {
    @Previewable @State var studios: [MockStudio] = []
    @Previewable @State var studioID: String? = nil
    @Previewable @State var customerID: String? = nil
    @Previewable @State var episodeID: String? = nil
    @Previewable @State var level: ProjectsLevel = .episode

    ProjectsBrowserView(
        studios: $studios,
        selectedStudioID: $studioID,
        selectedCustomerID: $customerID,
        selectedEpisodeID: $episodeID,
        selectedProjectsLevel: $level
    )
    .frame(width: 400, height: 600)
}
