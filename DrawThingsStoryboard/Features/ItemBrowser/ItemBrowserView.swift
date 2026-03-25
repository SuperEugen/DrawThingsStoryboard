import SwiftUI

/// Center pane — adapts to the selected phase.
struct ItemBrowserView: View {

    let section: AppSection?

    @Binding var studios: [MockStudio]
    @Binding var selectedStudioID: String?
    @Binding var selectedCustomerID: String?
    @Binding var selectedEpisodeID: String?
    @Binding var selectedProjectsLevel: ProjectsLevel
    @Binding var selectedItemID: String?

    var body: some View {
        VStack(spacing: 0) {
            BrowserHeaderView(section: section)
            Divider()
            switch section {
            case .projects:
                ProjectsBrowserView(
                    studios: $studios,
                    selectedStudioID: $selectedStudioID,
                    selectedCustomerID: $selectedCustomerID,
                    selectedEpisodeID: $selectedEpisodeID,
                    selectedProjectsLevel: $selectedProjectsLevel
                )
            default:
                GenericBrowserView(section: section, selectedItemID: $selectedItemID)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onChange(of: section) { _, _ in selectedItemID = nil }
    }
}

// MARK: - Header

private struct BrowserHeaderView: View {
    let section: AppSection?
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if let section {
                Image(systemName: section.icon).font(.title2).foregroundStyle(.secondary)
                Text(section.title).font(.title2.bold())
                Spacer()
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

// MARK: - Generic browser

private struct GenericBrowserView: View {
    let section: AppSection?
    @Binding var selectedItemID: String?
    var body: some View {
        ContentUnavailableView("No items yet", systemImage: section?.icon ?? "tray",
            description: Text("Items will appear here once created."))
    }
}
