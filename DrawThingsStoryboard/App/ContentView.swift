import SwiftUI

/// Root layout: three-pane NavigationSplitView.
/// Left   = phase/section navigation (SidebarView)
/// Center = item browser for the selected phase (ItemBrowserView)
///          — Library section uses its own full LibraryView instead
/// Right  = properties of the selected item (ItemDetailView)
struct ContentView: View {

    // MARK: - Navigation state

    @State private var selectedSection: AppSection?      = .projects
    @State private var selectedItemID: String?           = nil

    // MARK: - Hierarchy state (Studio → Customer → Episode)

    @State private var studios: [MockStudio]             = MockData.defaultStudios
    @State private var selectedStudioID: String?         = nil
    @State private var selectedCustomerID: String?       = nil
    @State private var selectedEpisodeID: String?        = nil
    @State private var selectedBriefingLevel: BriefingLevel = .episode

    // MARK: - Assets state (formerly Library)
    @State private var selectedAssetItem: CastingItem? = nil
    /// Bumped whenever the asset pane mutates studios, so the library view refreshes.
    @State private var libraryRefreshToken: UUID = UUID()

    // MARK: - Looks state (templates)
    @State private var templates: [GenerationTemplate] = MockData.defaultTemplates
    @State private var selectedTemplateID: String? = nil

    // MARK: - Storyboard state
    @State private var storyboardSelection: StoryboardSelection? = nil

    // MARK: - Production Queue state
    @State private var generationQueue: [GenerationJob] = MockData.sampleQueue
    @State private var selectedJobID: String? = nil

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

    /// Binding to the acts array of the currently selected episode.
    private var currentEpisodeActsBinding: Binding<[MockAct]> {
        guard let si = selectedStudioIndex,
              let ci = selectedCustomerIndex,
              let ei = selectedEpisodeIndex else {
            return .constant([])
        }
        return $studios[si].customers[ci].episodes[ei].acts
    }

    /// Window title: "Draw Things Storyboard - <Episode Name>"
    private var windowTitle: String {
        "Draw Things Storyboard - \(currentEpisodeName)"
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedSection: $selectedSection)
        } content: {
            switch selectedSection {
            case .configuration:
                ConfigurationView()
            case .assets:
                // Assets: center = detail view, right = library browser (swapped)
                AssetDetailPane(
                    studios: $studios,
                    selectedItem: $selectedAssetItem,
                    libraryRefreshToken: $libraryRefreshToken,
                    studioIndex: selectedStudioIndex ?? 0,
                    customerIndex: selectedCustomerIndex ?? 0,
                    episodeIndex: selectedEpisodeIndex ?? 0
                )
            case .productionQueue:
                ProductionBrowserView(
                    queue: $generationQueue,
                    selectedJobID: $selectedJobID
                )
            case .looks:
                LooksBrowserView(
                    templates: $templates,
                    selectedTemplateID: $selectedTemplateID
                )
            case .storyboard:
                StoryboardBrowserView(
                    acts: currentEpisodeActsBinding,
                    selection: $storyboardSelection
                )
            default:
                ItemBrowserView(
                    section: selectedSection,
                    studios: $studios,
                    selectedStudioID: $selectedStudioID,
                    selectedCustomerID: $selectedCustomerID,
                    selectedEpisodeID: $selectedEpisodeID,
                    selectedBriefingLevel: $selectedBriefingLevel,
                    selectedItemID: $selectedItemID
                )
            }
        } detail: {
            switch selectedSection {
            case .configuration:
                // Configuration is single-pane, so detail is empty
                EmptyView()
            case .assets:
                // Assets: right pane = library browser
                LibraryBrowserView(
                    studios: $studios,
                    selectedItem: $selectedAssetItem
                )
                .id(libraryRefreshToken)
            case .productionQueue:
                ProductionJobDetailView(
                    queue: generationQueue,
                    selectedJobID: selectedJobID
                )
            case .looks:
                LooksDetailView(
                    templates: $templates,
                    selectedTemplateID: $selectedTemplateID,
                    generationQueue: $generationQueue
                )
            case .storyboard:
                StoryboardDetailView(
                    acts: currentEpisodeActsBinding,
                    selection: storyboardSelection
                )
            case .projects:
                ItemDetailView(
                    section: selectedSection,
                    studios: $studios,
                    selectedStudioID: selectedStudioID,
                    selectedCustomerID: selectedCustomerID,
                    selectedEpisodeID: selectedEpisodeID,
                    selectedBriefingLevel: selectedBriefingLevel,
                    selectedItemID: selectedItemID,
                    templates: templates
                )
            default:
                ItemDetailView(
                    section: selectedSection,
                    studios: $studios,
                    selectedStudioID: selectedStudioID,
                    selectedCustomerID: selectedCustomerID,
                    selectedEpisodeID: selectedEpisodeID,
                    selectedBriefingLevel: selectedBriefingLevel,
                    selectedItemID: selectedItemID,
                    templates: templates
                )
            }
        }
        .onChange(of: selectedSection) { _, _ in
            selectedItemID = nil
            selectedAssetItem = nil
            selectedTemplateID = nil
            selectedJobID = nil
            storyboardSelection = nil
        }
        .frame(minWidth: 1100, minHeight: 680)
        .navigationTitle(windowTitle)
        .onAppear {
            // Ensure there is always at least one studio → customer → episode selected.
            ensureSelection()
        }
    }

    private var emptyDetail: some View {
        ContentUnavailableView(
            "Nothing selected",
            systemImage: "square.dashed",
            description: Text("Select an item to see its properties.")
        )
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
