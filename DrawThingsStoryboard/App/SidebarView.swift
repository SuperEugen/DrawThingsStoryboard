import SwiftUI

struct SidebarView: View {

    @Binding var selectedSection: AppSection?

    var body: some View {
        List(selection: $selectedSection) {

            Section("Project") {
                ForEach([AppSection.briefing, .casting, .writing, .production]) { section in
                    Label(section.title, systemImage: section.icon)
                        .tag(section)
                }
            }

            Section("Assets") {
                Label(AppSection.library.title, systemImage: AppSection.library.icon)
                    .tag(AppSection.library)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("DrawThingsStoryboard")
    }
}

#Preview {
    SidebarView(selectedSection: .constant(.briefing))
}
