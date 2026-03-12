import SwiftUI

struct SidebarView: View {

    @Binding var selectedSection: AppSection?

    var body: some View {
        List(selection: $selectedSection) {
            Section("Generate") {
                Label(AppSection.imageGeneration.title, systemImage: AppSection.imageGeneration.icon)
                    .tag(AppSection.imageGeneration)
            }
            // New sections added here as features are built
        }
        .listStyle(.sidebar)
        .navigationTitle("DrawThingsStoryboard")
    }
}

#Preview {
    SidebarView(selectedSection: .constant(.imageGeneration))
}
