import SwiftUI

// MARK: - Configuration view

struct ConfigurationView: View {

    @State private var appConfig: AppConfig = AppConfig(modelConfigs: [])

    var body: some View {
        Form {
            Section("Draw Things") {
                LabeledContent("Shared Secret") {
                    TextField("Shared Secret", text: $appConfig.sharedSecret)
                        .textFieldStyle(.roundedBorder).frame(maxWidth: 260)
                }
            }
            Section("Image Sizes") {
                LabeledContent("Small Width") {
                    TextField("Width", value: $appConfig.previewVariantWidth, format: .number)
                        .textFieldStyle(.roundedBorder).frame(maxWidth: 120)
                }
                LabeledContent("Small Height") {
                    TextField("Height", value: $appConfig.previewVariantHeight, format: .number)
                        .textFieldStyle(.roundedBorder).frame(maxWidth: 120)
                }
                LabeledContent("Large Width") {
                    TextField("Width", value: $appConfig.finalWidth, format: .number)
                        .textFieldStyle(.roundedBorder).frame(maxWidth: 120)
                }
                LabeledContent("Large Height") {
                    TextField("Height", value: $appConfig.finalHeight, format: .number)
                        .textFieldStyle(.roundedBorder).frame(maxWidth: 120)
                }
            }
            Section("Look Prompts") {
                LabeledContent("Example Prompt") {
                    TextField("Appended to look description for example images",
                              text: $appConfig.lookExamplePrompt)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { loadConfig() }
        .onChange(of: appConfig.sharedSecret)         { _, _ in saveConfig() }
        .onChange(of: appConfig.previewVariantWidth)  { _, _ in saveConfig() }
        .onChange(of: appConfig.previewVariantHeight) { _, _ in saveConfig() }
        .onChange(of: appConfig.finalWidth)           { _, _ in saveConfig() }
        .onChange(of: appConfig.finalHeight)          { _, _ in saveConfig() }
        .onChange(of: appConfig.lookExamplePrompt)    { _, _ in saveConfig() }
    }

    private func loadConfig() {
        let root = StorageService.shared.rootURL
        if let loaded = StorageLoadService.shared.loadAppConfig(from: root) {
            appConfig = loaded
        }
    }
    private func saveConfig() {
        StorageLoadService.shared.saveAppConfig(appConfig)
    }
}
