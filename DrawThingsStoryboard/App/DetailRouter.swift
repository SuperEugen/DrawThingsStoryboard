import SwiftUI

/// DetailRouter is superseded by the three-pane NavigationSplitView in ContentView.
/// Kept as a stub to avoid Xcode "missing reference" issues until old ImageGenerationView
/// scaffolding is cleaned up in a follow-up.
struct DetailRouter: View {
    let selectedSection: AppSection?
    var body: some View { EmptyView() }
}
