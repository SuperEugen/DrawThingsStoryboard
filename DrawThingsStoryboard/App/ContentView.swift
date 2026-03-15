import SwiftUI

/// Root layout: three-pane NavigationSplitView.
/// Left   = phase/section navigation (SidebarView)
/// Center = item browser for the selected phase (ItemBrowserView)
///          — Library section uses its own full LibraryView instead
/// Right  = properties of the selected item (ItemDetailView)
struct ContentView: View {

    @State private var selectedSection: AppSection?    = .casting
    @State private var selectedCastingItem: CastingItem? = nil
    @State private var selectedItemID: String?           = nil

    var body: some View {
        if selectedSection == .library {
            // Library gets its own full-width layout with built-in navigator
            NavigationSplitView {
                SidebarView(selectedSection: $selectedSection)
            } detail: {
                LibraryView()
            }
            .frame(minWidth: 1100, minHeight: 680)
        } else {
            NavigationSplitView {
                SidebarView(selectedSection: $selectedSection)
            } content: {
                ItemBrowserView(
                    section: selectedSection,
                    selectedCastingItem: $selectedCastingItem,
                    selectedItemID: $selectedItemID
                )
            } detail: {
                ItemDetailView(
                    section: selectedSection,
                    selectedCastingItem: $selectedCastingItem,
                    selectedItemID: selectedItemID
                )
            }
            .frame(minWidth: 1100, minHeight: 680)
            .onChange(of: selectedSection) { _, _ in
                selectedCastingItem = nil
                selectedItemID = nil
            }
        }
    }
}

#Preview {
    ContentView()
}
