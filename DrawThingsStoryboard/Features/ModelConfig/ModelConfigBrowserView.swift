import SwiftUI

// MARK: - Model Config browser (list of model configurations)

struct ModelConfigBrowserView: View {
    @Binding var configs: [ModelConfig]
    @Binding var selectedConfigID: String?

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Model Config")
                    .font(.headline)
                Spacer()
                Button(action: addConfig) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Add model configuration")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            List(configs, selection: $selectedConfigID) { config in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.purple.opacity(0.7))
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(config.name)
                            .font(.callout.weight(.medium))
                        Text(config.model.isEmpty ? "No model set" : config.model)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .tag(config.id)
                .contextMenu {
                    Button(role: .destructive) {
                        removeConfig(id: config.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }

    private func addConfig() {
        let new = ModelConfig(
            id: UUID().uuidString,
            name: "New Config",
            model: "",
            steps: 20,
            guidanceScale: 7.0
        )
        configs.append(new)
        selectedConfigID = new.id
    }

    private func removeConfig(id: String) {
        configs.removeAll { $0.id == id }
        if selectedConfigID == id { selectedConfigID = configs.first?.id }
    }
}
