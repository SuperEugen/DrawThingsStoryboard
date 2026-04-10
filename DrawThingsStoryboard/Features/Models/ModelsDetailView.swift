import SwiftUI

// MARK: - Models detail editor
/// #76: Default gen times now show calculated averages (auto-updated by #85)

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

    private func formattedTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m > 0 && s > 0 { return "\(m)m \(s)s" }
        if m > 0 { return "\(m)m" }
        return "\(s)s"
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
                    if let err = guidanceError {
                        Text(err).font(.caption2).foregroundStyle(.red)
                    }
                }
                .padding(.bottom, 12)

                // Sampler
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Sampler")
                    TextField("e.g. UniPC Trailing", text: $model.sampler)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.bottom, 12)

                // Img2Img Capable
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Img2Img")
                    Toggle("Img2Img Capable", isOn: $model.isImg2ImgCapable)
                        .toggleStyle(.switch)
                }
                .padding(.bottom, 12)

                Divider().padding(.vertical, 8)

                // #76: Gen times — display formatted + editable
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("Average Generation Times")
                    Text("Auto-updated after each completed job. Can also be edited manually.")
                        .font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Small Image").font(.caption).foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                TextField("sec", value: $model.defaultGenTimeSmall, format: .number)
                                    .textFieldStyle(.roundedBorder).frame(width: 70)
                                Text("s").font(.callout).foregroundStyle(.secondary)
                            }
                            Text(formattedTime(model.defaultGenTimeSmall))
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Large Image").font(.caption).foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                TextField("sec", value: $model.defaultGenTimeLarge, format: .number)
                                    .textFieldStyle(.roundedBorder).frame(width: 70)
                                Text("s").font(.callout).foregroundStyle(.secondary)
                            }
                            Text(formattedTime(model.defaultGenTimeLarge))
                                .font(.caption2).foregroundStyle(.tertiary)
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
