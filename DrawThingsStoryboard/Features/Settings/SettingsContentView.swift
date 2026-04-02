import SwiftUI

// MARK: - Settings content (shown as center pane when Settings selected)

struct SettingsContentView: View {
    @Binding var config: AppConfig

    var body: some View {
        Form {
            Section("Draw Things") {
                LabeledContent("Shared Secret") {
                    TextField("Shared Secret", text: $config.sharedSecret)
                        .textFieldStyle(.roundedBorder).frame(maxWidth: 260)
                }
            }
            Section("Image Sizes") {
                LabeledContent("Small Width") {
                    TextField("Width", value: $config.smallImageWidth, format: .number)
                        .textFieldStyle(.roundedBorder).frame(maxWidth: 120)
                }
                LabeledContent("Small Height") {
                    TextField("Height", value: $config.smallImageHeight, format: .number)
                        .textFieldStyle(.roundedBorder).frame(maxWidth: 120)
                }
                LabeledContent("Large Width") {
                    TextField("Width", value: $config.largeImageWidth, format: .number)
                        .textFieldStyle(.roundedBorder).frame(maxWidth: 120)
                }
                LabeledContent("Large Height") {
                    TextField("Height", value: $config.largeImageHeight, format: .number)
                        .textFieldStyle(.roundedBorder).frame(maxWidth: 120)
                }
            }
            Section("Style Preview") {
                LabeledContent("Example Prompt") {
                    TextField("Appended to style description for examples",
                              text: $config.stylePrompt)
                        .textFieldStyle(.roundedBorder)
                }
            }
            Section("Panel Defaults") {
                LabeledContent("Duration") {
                    HStack {
                        TextField("sec", value: $config.defaultPanelDuration, format: .number)
                            .textFieldStyle(.roundedBorder).frame(maxWidth: 80)
                        Text("seconds").foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: config) { _, newConfig in
            StorageLoadService.shared.saveConfig(newConfig)
        }
    }
}
