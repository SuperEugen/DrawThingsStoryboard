import SwiftUI

/// Routes the selected sidebar section to the correct feature view.
/// Add new cases here as features are built.
struct DetailRouter: View {

    let selectedSection: AppSection?

    var body: some View {
        switch selectedSection {
        case .imageGeneration:
            ImageGenerationView()
        case .none:
            ContentUnavailableView(
                "Nothing selected",
                systemImage: "sidebar.left",
                description: Text("Choose a section from the sidebar.")
            )
        }
    }
}
