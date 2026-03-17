import SwiftUI

struct SidebarView: View {

    @Binding var selectedSection: AppSection?

    var body: some View {
        List(selection: $selectedSection) {
            ForEach([AppSection.projects, .assets, .looks, .storyboard, .productionQueue]) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }

            Spacer()

            Label(AppSection.configuration.title, systemImage: AppSection.configuration.icon)
                .tag(AppSection.configuration)
        }
        .listStyle(.sidebar)
    }
}

#Preview {
    SidebarView(selectedSection: .constant(.projects))
}
