import SwiftUI

// MARK: - Model Config detail

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

                    UnifiedThumbnailView(
                        itemType: .modelConfig,
                        name: "",
                        sizeMode: .header
                    )
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
                        Text("Filename as shown in Draw Things, e.g. flux_1_schnell_q5p.ckpt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Model filename", text: $configs[idx].model)
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
                            TextField("Guidance", value: $configs[idx].guidanceScale, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            Text("CFG")
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
                description: Text("Select a model configuration to edit its parameters.")
            )
        }
    }
}
