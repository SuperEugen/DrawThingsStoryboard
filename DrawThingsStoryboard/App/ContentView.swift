import SwiftUI

/// Root layout: three-pane NavigationSplitView.
/// Left   = phase/section navigation (SidebarView)
/// Center = item browser for the selected phase (ItemBrowserView)
/// Right  = properties of the selected item (ItemDetailView)
struct ContentView: View {

    @State private var selectedSection: AppSection? = .briefing
    @State private var selectedItemID: String? = nil

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedSection: $selectedSection)
        } content: {
            ItemBrowserView(section: selectedSection, selectedItemID: $selectedItemID)
        } detail: {
            ItemDetailView(section: selectedSection, itemID: selectedItemID)
        }
        .frame(minWidth: 1100, minHeight: 680)
    }
}

#Preview {
    ContentView()
}
