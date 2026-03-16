import SwiftUI

/// Root layout: three-pane NavigationSplitView.
/// Left   = phase/section navigation (SidebarView)
/// Center = item browser for the selected phase (ItemBrowserView)
///          — Library section uses its own full LibraryView instead
/// Right  = properties of the selected item (ItemDetailView)
struct ContentView: View {

    // MARK: - Navigation state

    @State private var selectedSection: AppSection?      = .briefing
    @State private var selectedCastingItem: CastingItem? = nil
    @State private var selectedItemID: String?           = nil

    // MARK: - Hierarchy state (Studio → Customer → Episode)

    @State private var studios: [MockStudio]             = MockData.defaultStudios
    @State private var selectedStudioID: String?         = nil
    @State private var selectedCustomerID: String?       = nil
    @State private var selectedEpisodeID: String?        = nil
    @State private var selectedBriefingLevel: BriefingLevel = .episode

    // MARK: - Derived selection helpers

    private var selectedStudioIndex: Int? {
        studios.firstIndex { $0.id == selectedStudioID }
    }
    private var selectedCustomerIndex: Int? {
        guard let si = selectedStudioIndex else { return nil }
        return studios[si].customers.firstIndex { $0.id == selectedCustomerID }
    }
    private var selectedEpisodeIndex: Int? {
        guard let si = selectedStudioIndex, let ci = selectedCustomerIndex else { return nil }
        return studios[si].customers[ci].episodes.firstIndex { $0.id == selectedEpisodeID }
    }

    private var currentEpisodeName: String {
        guard let si = selectedStudioIndex,
              let ci = selectedCustomerIndex,
              let ei = selectedEpisodeIndex else { return "First Episode" }
        return studios[si].customers[ci].episodes[ei].name
    }

    /// Window title: "Draw Things Storyboard - <Episode Name>"
    private var windowTitle: String {
        "Draw Things Storyboard - \(currentEpisodeName)"
    }

    var body: some View {
        Group {
            if selectedSection == .library {
                NavigationSplitView {
                    SidebarView(selectedSection: $selectedSection)
                } detail: {
                    LibraryView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                NavigationSplitView {
                    SidebarView(selectedSection: $selectedSection)
                } content: {
                    ItemBrowserView(
                        section: selectedSection,
                        studios: $studios,
                        selectedStudioID: $selectedStudioID,
                        selectedCustomerID: $selectedCustomerID,
                        selectedEpisodeID: $selectedEpisodeID,
                        selectedBriefingLevel: $selectedBriefingLevel,
                        selectedCastingItem: $selectedCastingItem,
                        selectedItemID: $selectedItemID
                    )
                } detail: {
                    ItemDetailView(
                        section: selectedSection,
                        studios: $studios,
                        selectedStudioID: selectedStudioID,
                        selectedCustomerID: selectedCustomerID,
                        selectedEpisodeID: selectedEpisodeID,
                        selectedBriefingLevel: selectedBriefingLevel,
                        selectedCastingItem: $selectedCastingItem,
                        selectedItemID: selectedItemID
                    )
                }
                .onChange(of: selectedSection) { _, _ in
                    selectedCastingItem = nil
                    selectedItemID = nil
                }
            }
        }
        .frame(minWidth: 1100, minHeight: 680)
        .navigationTitle(windowTitle)
        .onAppear {
            // Ensure there is always at least one studio → customer → episode selected.
            ensureSelection()
        }
    }

    // MARK: - Guarantee at-least-one selection

    private func ensureSelection() {
        if studios.isEmpty {
            studios.append(MockStudio(
                id: UUID().uuidString, name: "Your Studio",
                customers: [], characters: [], locations: []
            ))
        }
        let studio = studios[0]
        if selectedStudioID == nil { selectedStudioID = studio.id }

        let si = studios.firstIndex { $0.id == selectedStudioID } ?? 0
        if studios[si].customers.isEmpty {
            studios[si].customers.append(MockCustomer(
                id: UUID().uuidString, name: "Your Customer", episodes: []
            ))
        }
        if selectedCustomerID == nil { selectedCustomerID = studios[si].customers[0].id }

        let ci = studios[si].customers.firstIndex { $0.id == selectedCustomerID } ?? 0
        if studios[si].customers[ci].episodes.isEmpty {
            studios[si].customers[ci].episodes.append(MockEpisode(
                id: UUID().uuidString, name: "First Episode",
                characters: [], locations: []
            ))
        }
        if selectedEpisodeID == nil { selectedEpisodeID = studios[si].customers[ci].episodes[0].id }
    }
}

#Preview {
    ContentView()
}
