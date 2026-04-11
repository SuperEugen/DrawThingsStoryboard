import SwiftUI
import UniformTypeIdentifiers

// MARK: - Settings content (shown as center pane when Settings selected)
/// #49: Assets section with Character Turn-Around setting
/// #59: Pushover notification settings

struct SettingsContentView: View {
    @Binding var config: AppConfig
    @State private var showSavedFlash: Bool = false
    @State private var showImportError = false

    // #30: Validation errors
    private var smallWidthError: String? {
        ValidationHelper.isValidDimension(config.smallImageWidth) ? nil : "Must be a multiple of 64"
    }
    private var smallHeightError: String? {
        ValidationHelper.isValidDimension(config.smallImageHeight) ? nil : "Must be a multiple of 64"
    }
    private var largeWidthError: String? {
        ValidationHelper.isValidDimension(config.largeImageWidth) ? nil : "Must be a multiple of 64"
    }
    private var largeHeightError: String? {
        ValidationHelper.isValidDimension(config.largeImageHeight) ? nil : "Must be a multiple of 64"
    }
    private var portError: String? {
        ValidationHelper.isValidPort(config.grpcPort) ? nil : "Must be 1\u{2013}65535"
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            settingsForm
        }
        .alert("Invalid File", isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The selected file is not a valid DrawThingsStoryboard config file (DTSB-Config).")
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "gearshape").font(.title2).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Settings").font(.title2.bold())
                    Text("App configuration, image sizes, and service credentials.")
                        .font(.caption).foregroundStyle(.tertiary)
                }
                Spacer()
            }
            .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 8)

            HStack(spacing: 16) {
                // GROUP 1: Import
                GroupBox {
                    Button { importConfigFile() } label: {
                        Image(systemName: "slider.horizontal.3").font(.callout)
                    }
                    .buttonStyle(.bordered).controlSize(.regular)
                    .help("Import settings from a DTSB-Config JSON file")
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                        .font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 14).padding(.bottom, 10)
        }
    }

    // MARK: - Settings form

    @ViewBuilder
    private var settingsForm: some View {
        ZStack(alignment: .top) {
            Form {
                // #19: Draw Things connection settings
                Section("Draw Things") {
                    LabeledContent("Server Address") {
                        TextField("Address", text: $config.grpcAddress)
                            .textFieldStyle(.roundedBorder).frame(maxWidth: 200)
                    }
                    LabeledContent("Port") {
                        VStack(alignment: .leading, spacing: 2) {
                            TextField("Port", value: $config.grpcPort, format: .number)
                                .textFieldStyle(.roundedBorder).frame(maxWidth: 100)
                            if let err = portError {
                                Text(err).font(.caption2).foregroundStyle(.red)
                            }
                        }
                    }
                    LabeledContent("Shared Secret") {
                        TextField("Shared Secret", text: $config.sharedSecret)
                            .textFieldStyle(.roundedBorder).frame(maxWidth: 260)
                    }
                }
                // #30: Image sizes with validation
                Section("Image Sizes") {
                    LabeledContent("Small Width") {
                        VStack(alignment: .leading, spacing: 2) {
                            TextField("Width", value: $config.smallImageWidth, format: .number)
                                .textFieldStyle(.roundedBorder).frame(maxWidth: 120)
                            if let err = smallWidthError {
                                Text(err).font(.caption2).foregroundStyle(.red)
                            }
                        }
                    }
                    LabeledContent("Small Height") {
                        VStack(alignment: .leading, spacing: 2) {
                            TextField("Height", value: $config.smallImageHeight, format: .number)
                                .textFieldStyle(.roundedBorder).frame(maxWidth: 120)
                            if let err = smallHeightError {
                                Text(err).font(.caption2).foregroundStyle(.red)
                            }
                        }
                    }
                    LabeledContent("Large Width") {
                        VStack(alignment: .leading, spacing: 2) {
                            TextField("Width", value: $config.largeImageWidth, format: .number)
                                .textFieldStyle(.roundedBorder).frame(maxWidth: 120)
                            if let err = largeWidthError {
                                Text(err).font(.caption2).foregroundStyle(.red)
                            }
                        }
                    }
                    LabeledContent("Large Height") {
                        VStack(alignment: .leading, spacing: 2) {
                            TextField("Height", value: $config.largeImageHeight, format: .number)
                                .textFieldStyle(.roundedBorder).frame(maxWidth: 120)
                            if let err = largeHeightError {
                                Text(err).font(.caption2).foregroundStyle(.red)
                            }
                        }
                    }
                }
                // #49: Assets settings
                Section("Assets") {
                    LabeledContent("Character Turn-Around") {
                        TextEditor(text: $config.characterTurnAround)
                            .font(.callout)
                            .frame(minHeight: 60, maxHeight: 100)
                            .overlay(RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5))
                    }
                    Text("Prepended to character asset descriptions when generating images.")
                        .font(.caption2).foregroundStyle(.secondary)
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
                // #59: Pushover notification settings
                Section("Pushover Notifications") {
                    LabeledContent("API Token") {
                        SecureField("Application Token", text: $config.pushoverToken)
                            .textFieldStyle(.roundedBorder).frame(maxWidth: 300)
                    }
                    LabeledContent("User Key") {
                        SecureField("User/Group Key", text: $config.pushoverUser)
                            .textFieldStyle(.roundedBorder).frame(maxWidth: 300)
                    }
                    Text("Get your token and key at pushover.net. Enable notifications in the Production Queue.")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .onChange(of: config) { _, newConfig in
                StorageLoadService.shared.saveConfig(newConfig)
                showSavedFlash = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { showSavedFlash = false }
                }
            }

            if showSavedFlash {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Saved").font(.caption.weight(.medium))
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .transition(.opacity)
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Import

    private func importConfigFile() {
        let panel = NSOpenPanel()
        panel.title = "Import Settings"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [UTType.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try Data(contentsOf: url)
            let imported = try JSONDecoder().decode(AppConfig.self, from: data)
            guard imported.type == "DTSB-Config" else {
                showImportError = true
                return
            }
            config = imported
            StorageLoadService.shared.saveConfig(config)
        } catch {
            showImportError = true
            print("[SettingsImport] Error: \(error)")
        }
    }
}
