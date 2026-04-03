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
            ModelEditorView(model: $models.models[idx])
        } else {
            ContentUnavailableView(
                "No model selected",
                systemImage: "gearshape",
                description: Text("Select a model configuration to edit.")
            )
        }
    }
}

// MARK: - Model editor (extracted to avoid type-checker timeout)

private struct ModelEditorView: View {
    @Binding var model: ModelEntry

    // #30: Validation errors
    private var modelError: String? {
        model.model.isEmpty ? nil :
            (ValidationHelper.isValidModelFilename(model.model) ? nil : "Must end in .ckpt or .safetensors")
    }
    private var guidanceError: String? {
        ValidationHelper.isValidGuidanceScale(model.guidanceScale) ? nil : "Must be 0\u{2013}30"
    }
    private var stepsError: String? {
        model.steps > 0 ? nil : "Must be at least 1"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                UnifiedThumbnailView(itemType: .model, name: "", sizeMode: .header)
                    .padding(.bottom, 16)

                // Name
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Name")
                    TextField("Config name", text: $model.name)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.bottom, 12)

                Divider().padding(.vertical, 8)

                // Model file
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Model")
                    Text("Filename exactly as shown in Draw Things")
                        .font(.caption).foregroundStyle(.secondary)
                    TextField("model filename", text: $model.model)
                        .textFieldStyle(.roundedBorder).font(.callout.monospaced())
                    // #30: Inline validation
                    if let err = modelError {
                        Text(err).font(.caption2).foregroundStyle(.red)
                    }
                }
                .padding(.bottom, 12)

                // Steps
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Steps")
                    HStack(spacing: 6) {
                        TextField("Steps", value: $model.steps, format: .number)
                            .textFieldStyle(.roundedBorder).frame(width: 80)
                        Text("steps").font(.callout).foregroundStyle(.secondary)
                    }
                    if let err = stepsError {
                        Text(err).font(.caption2).foregroundStyle(.red)
                    }
                }
                .padding(.bottom, 12)

                // Guidance Scale
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Guidance Scale")
                    HStack(spacing: 6) {
                        TextField("CFG", value: $model.guidanceScale, format: .number)
                            .textFieldStyle(.roundedBorder).frame(width: 80)
                        Text("CFG scale").font(.callout).foregroundStyle(.secondary)
                    }
                    // #30: Inline validation
                    if let err = guidanceError {
                        Text(err).font(.caption2).foregroundStyle(.red)
                    }
                }
                .padding(.bottom, 12)

                // Gen times
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Default Generation Times")
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text("Small:").font(.callout)
                            TextField("sec", value: $model.defaultGenTimeSmall, format: .number)
                                .textFieldStyle(.roundedBorder).frame(width: 60)
                            Text("s").font(.callout).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 4) {
                            Text("Large:").font(.callout)
                            TextField("sec", value: $model.defaultGenTimeLarge, format: .number)
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
    }
}
