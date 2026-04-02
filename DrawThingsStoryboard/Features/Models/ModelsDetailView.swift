import SwiftUI

// MARK: - Models detail editor

struct ModelsDetailView: View {
    @Binding var models: ModelsFile
    @Binding var selectedModelID: String?

    private var selectedIndex: Int? {
        guard let id = selectedModelID else { return nil }
        return models.models.firstIndex { $0.modelID == id }
    }

    var body: some View {
        if let idx = selectedIndex {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    UnifiedThumbnailView(itemType: .model, name: "", sizeMode: .header)
                        .padding(.bottom, 16)

                    // Name
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Name")
                        TextField("Config name", text: $models.models[idx].name)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.bottom, 12)

                    Divider().padding(.vertical, 8)

                    // Model file
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Model")
                        Text("Filename exactly as shown in Draw Things")
                            .font(.caption).foregroundStyle(.secondary)
                        TextField("model filename", text: $models.models[idx].model)
                            .textFieldStyle(.roundedBorder).font(.callout.monospaced())
                    }
                    .padding(.bottom, 12)

                    // Steps
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Steps")
                        HStack(spacing: 6) {
                            TextField("Steps", value: $models.models[idx].steps, format: .number)
                                .textFieldStyle(.roundedBorder).frame(width: 80)
                            Text("steps").font(.callout).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 12)

                    // Guidance Scale
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Guidance Scale")
                        HStack(spacing: 6) {
                            TextField("CFG", value: $models.models[idx].guidanceScale, format: .number)
                                .textFieldStyle(.roundedBorder).frame(width: 80)
                            Text("CFG scale").font(.callout).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 12)

                    // Gen times
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Default Generation Times")
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Text("Small:").font(.callout)
                                TextField("sec", value: $models.models[idx].defaultGenTimeSmall, format: .number)
                                    .textFieldStyle(.roundedBorder).frame(width: 60)
                                Text("s").font(.callout).foregroundStyle(.secondary)
                            }
                            HStack(spacing: 4) {
                                Text("Large:").font(.callout)
                                TextField("sec", value: $models.models[idx].defaultGenTimeLarge, format: .number)
                                    .textFieldStyle(.roundedBorder).frame(width: 60)
                                Text("s").font(.callout).foregroundStyle(.secondary)
                            }
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
                "No model selected",
                systemImage: "gearshape",
                description: Text("Select a model configuration to edit.")
            )
        }
    }
}
