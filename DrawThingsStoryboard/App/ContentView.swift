import SwiftUI

/// Root layout: NavigationSplitView with sidebar + detail.
struct ContentView: View {

    @State private var selectedSection: AppSection? = .imageGeneration

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedSection: $selectedSection)
        } detail: {
            DetailRouter(selectedSection: selectedSection)
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
