import SwiftUI

// MARK: - Models browser

struct ModelsBrowserView: View {
    @Binding var models: ModelsFile
    @Binding var selectedModelID: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "gearshape").font(.title2).foregroundStyle(.secondary)
                Text("Models").font(.title2.bold())
                Spacer()
                Button(action: addModel) {
                    Image(systemName: "plus").frame(width: 22, height: 22)
                }
                .buttonStyle(.bordered).controlSize(.mini)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            Divider()

            List(models.models, selection: $selectedModelID) { model in
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
                        Text(model.name).font(.callout.weight(.medium))
                        Text(model.model.isEmpty ? "No model set" : model.model)
                            .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer()
                }
                .tag(model.modelID)
                .contextMenu {
                    Button(role: .destructive) { removeModel(id: model.modelID) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .listStyle(.sidebar)
        }
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
