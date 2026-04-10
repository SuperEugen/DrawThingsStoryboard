import SwiftUI

// MARK: - Models browser
/// #58: White background
/// #59: x-button for deletion

struct ModelsBrowserView: View {
    @Binding var models: ModelsFile
    @Binding var selectedModelID: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "camera").font(.title2).foregroundStyle(.secondary)
                Text("Models").font(.title2.bold())
                Spacer()
                Button(action: addModel) {
                    Image(systemName: "plus").frame(width: 22, height: 22)
                }
                .buttonStyle(.bordered).controlSize(.mini)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            Divider()

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(models.models) { model in
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.purple.opacity(0.15))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.purple.opacity(0.7))
                                }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(model.name).font(.callout.weight(.medium))
                                Text(model.model.isEmpty ? "No model set" : model.model)
                                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            // #59: x-button for deletion
                            Button { removeModel(id: model.modelID) } label: {
                                Image(systemName: "x.circle.fill")
                                    .font(.system(size: 14))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 8)
                            .fill(selectedModelID == model.modelID ? Color.accentColor.opacity(0.1) : Color.clear))
                        .contentShape(Rectangle())
                        .onTapGesture { selectedModelID = model.modelID }
                    }
                }
                .padding(8)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { ensureSelection() }
    }

    private func addModel() {
        let id = UUID().uuidString
        let new = ModelEntry(modelID: id, name: "New Model", guidanceScale: 7.0, model: "", steps: 20)
        models.models.append(new)
        selectedModelID = id
    }

    private func removeModel(id: String) {
        models.models.removeAll { $0.modelID == id }
        if selectedModelID == id { selectedModelID = models.models.first?.modelID }
    }

    private func ensureSelection() {
        if selectedModelID == nil || !models.models.contains(where: { $0.modelID == selectedModelID }) {
            selectedModelID = models.models.first?.modelID
        }
    }
}
