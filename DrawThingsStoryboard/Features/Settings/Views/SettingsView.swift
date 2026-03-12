import SwiftUI

/// Settings window — opened via Cmd+, or the menu.
struct SettingsView: View {

    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        Form {
            Section("Draw Things Connection") {
                TextField("Base URL", text: $viewModel.baseURL)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(minWidth: 400)
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}
