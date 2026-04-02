import SwiftUI

struct SidebarView: View {

    @Binding var selectedSection: AppSection?

    var body: some View {
        List(selection: $selectedSection) {
            ForEach([AppSection.storyboard, .assets, .styles, .models, .productionQueue]) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }

            Spacer()

            Label(AppSection.settings.title, systemImage: AppSection.settings.icon)
                .tag(AppSection.settings)
        }
        .listStyle(.sidebar)
    }
}

#Preview {
    SidebarView(selectedSection: .constant(.storyboard))
}
