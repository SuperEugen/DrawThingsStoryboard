import SwiftUI

// MARK: - Model Config detail editor

struct ModelConfigDetailView: View {
    @Binding var configs: [ModelConfig]
    @Binding var selectedConfigID: String?

    private var selectedIndex: Int? {
        guard let id = selectedConfigID else { return nil }
        return configs.firstIndex { $0.id == id }
    }

    var body: some View {
        if let idx = selectedIndex {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Header thumbnail — hell-lila mit Zahnrad
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.12))
                            .frame(maxWidth: .infinity)
                            .frame(height: 90)
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.purple.opacity(0.5))
                    }
                    .padding(.bottom, 16)

                    // Name
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Name")
                        TextField("Config name", text: $configs[idx].name)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.bottom, 12)

                    Divider().padding(.vertical, 8)

                    // Model
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Model")
                        Text("Filename exactly as shown in Draw Things, e.g. \"sd_xl_base_1.0.safetensors\"")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 2)
                        TextField("model filename", text: $configs[idx].model)
                            .textFieldStyle(.roundedBorder)
                            .font(.callout.monospaced())
                    }
                    .padding(.bottom, 12)

                    // Steps
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Steps")
                        HStack(spacing: 6) {
                            TextField("Steps", value: $configs[idx].steps, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            Text("steps")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 12)

                    // Guidance Scale
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Guidance Scale")
                        HStack(spacing: 6) {
                            TextField("CFG", value: $configs[idx].guidanceScale, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            Text("CFG scale")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 12)

                    Spacer(minLength: 20)
                }
                .padding(14)
            }
            .background(Color(NSColor.windowBackgroundColor))
        } else {
            ContentUnavailableView(
                "No config selected",
                systemImage: "gearshape",
                description: Text("Select a model configuration from the list to edit it.")
            )
        }
    }
}
