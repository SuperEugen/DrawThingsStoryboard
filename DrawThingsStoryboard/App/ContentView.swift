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

    /// Resolved preferred look name for the current episode (own → customer → studio).
    private var resolvedLookName: String? {
        guard let si = selectedStudioIndex else { return nil }
        let studio = studios[si]

        // Episode's own look
        if let ci = selectedCustomerIndex, let ei = selectedEpisodeIndex {
            let episode = studio.customers[ci].episodes[ei]
            if let id = episode.preferredLookID,
               let t = templates.first(where: { $0.id == id }) {
                return t.name
            }
        }
        // Customer's look
        if let ci = selectedCustomerIndex {
            let customer = studio.customers[ci]
            if let id = customer.preferredLookID,
               let t = templates.first(where: { $0.id == id }) {
                return t.name
            }
        }
        // Studio's look
        if let id = studio.preferredLookID,
           let t = templates.first(where: { $0.id == id }) {
            return t.name
        }
        return nil
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
                    generationQueue: $generationQueue,
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
                    selection: $storyboardSelection,
                    lookName: resolvedLookName
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
                    selection: storyboardSelection,
                    generationQueue: $generationQueue,
                    studios: studios,
                    studioIndex: selectedStudioIndex ?? 0,
                    customerIndex: selectedCustomerIndex ?? 0,
                    episodeIndex: selectedEpisodeIndex ?? 0
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
        .onChange(of: selectedEpisodeID) { _, _ in
            // Ensure the newly selected episode has a minimal storyboard
            guard let si = selectedStudioIndex,
                  let ci = selectedCustomerIndex,
                  let ei = selectedEpisodeIndex else { return }
            ensureMinimalStoryboard(studioIndex: si, customerIndex: ci, episodeIndex: ei)
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

        // Ensure the selected episode has a minimal storyboard structure
        let ei = studios[si].customers[ci].episodes.firstIndex { $0.id == selectedEpisodeID } ?? 0
        ensureMinimalStoryboard(studioIndex: si, customerIndex: ci, episodeIndex: ei)
    }

    /// Guarantees the episode at the given indices has at least
    /// 1 Act > 1 Sequence > 1 Scene > 1 Panel.
    private func ensureMinimalStoryboard(studioIndex si: Int, customerIndex ci: Int, episodeIndex ei: Int) {
        if studios[si].customers[ci].episodes[ei].acts.isEmpty {
            studios[si].customers[ci].episodes[ei].acts.append(
                MockAct(
                    id: UUID().uuidString,
                    name: "Act 1",
                    description: "",
                    sequences: []
                )
            )
        }
        for ai in studios[si].customers[ci].episodes[ei].acts.indices {
            if studios[si].customers[ci].episodes[ei].acts[ai].sequences.isEmpty {
                studios[si].customers[ci].episodes[ei].acts[ai].sequences.append(
                    MockSequence(
                        id: UUID().uuidString,
                        name: "Sequence 1",
                        description: "",
                        scenes: []
                    )
                )
            }
            for seqi in studios[si].customers[ci].episodes[ei].acts[ai].sequences.indices {
                if studios[si].customers[ci].episodes[ei].acts[ai].sequences[seqi].scenes.isEmpty {
                    studios[si].customers[ci].episodes[ei].acts[ai].sequences[seqi].scenes.append(
                        MockScene(
                            id: UUID().uuidString,
                            name: "Scene 1",
                            description: "",
                            panels: []
                        )
                    )
                }
                for sci in studios[si].customers[ci].episodes[ei].acts[ai].sequences[seqi].scenes.indices {
                    if studios[si].customers[ci].episodes[ei].acts[ai].sequences[seqi].scenes[sci].panels.isEmpty {
                        studios[si].customers[ci].episodes[ei].acts[ai].sequences[seqi].scenes[sci].panels.append(
                            MockPanel(
                                id: UUID().uuidString,
                                name: "Panel 1",
                                description: ""
                            )
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
