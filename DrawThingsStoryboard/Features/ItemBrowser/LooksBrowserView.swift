import SwiftUI

// MARK: - Looks browser

struct LooksBrowserView: View {
    @Binding var templates: [GenerationTemplate]
    @Binding var selectedTemplateID: String?
    private let columns = [GridItem(.adaptive(minimum: 288, maximum: 320), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "paintpalette").font(.title2).foregroundStyle(.secondary)
                Text("Looks").font(.title2.bold())
                Spacer()
                Button(action: addLook) { Image(systemName: "plus").frame(width: 22, height: 22) }
                .buttonStyle(.bordered).controlSize(.mini)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            Divider()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(templates) { template in
                        LookTile(
                            template: template,
                            isSelected: selectedTemplateID == template.id,
                            canDelete: templates.count > 1,
                            onDelete: { removeLook(id: template.id) },
                            onTap: { selectedTemplateID = template.id }
                        )
                    }
                }
                .padding(16)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { ensureSelection() }
        .onChange(of: templates.count) { _, _ in ensureSelection() }
    }

    private func addLook() {
        let id = UUID().uuidString
        templates.append(GenerationTemplate(id: id, name: "New Look", description: ""))
        selectedTemplateID = id
    }
    private func removeLook(id: String) {
        guard templates.count > 1, let idx = templates.firstIndex(where: { $0.id == id }) else { return }
        templates.remove(at: idx)
        if selectedTemplateID == id || !templates.contains(where: { $0.id == selectedTemplateID }) {
            selectedTemplateID = templates[min(idx, templates.count - 1)].id
        }
    }
    private func ensureSelection() {
        if selectedTemplateID == nil || !templates.contains(where: { $0.id == selectedTemplateID }) {
            selectedTemplateID = templates.first?.id
        }
    }
}

// MARK: - Look tile

struct LookTile: View {
    let template: GenerationTemplate
    let isSelected: Bool
    let canDelete: Bool
    let onDelete: () -> Void
    let onTap: () -> Void
    @State private var exampleImage: NSImage? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                ZStack {
                    if let img = exampleImage {
                        Image(nsImage: img).resizable().scaledToFill().frame(height: 140).clipped()
                    } else {
                        UnifiedThumbnailView(
                            itemType: .look, name: template.name, sizeMode: .standard,
                            badges: ThumbnailBadges(
                                showExampleIndicator: true,
                                exampleAvailable: template.lookStatus == .exampleAvailable,
                                showDeleteButton: false, onDelete: {}, showSelectionStroke: false
                            )
                        )
                    }
                }
                .frame(height: 140).clipShape(RoundedRectangle(cornerRadius: 10))
                Text(template.name).font(.callout.weight(.medium)).lineLimit(1)
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(NSColor.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2),
                        lineWidth: isSelected ? 2 : 0.5))

            if canDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary).font(.system(size: 16))
                }.buttonStyle(.plain).padding(6)
            }
            VStack {
                Spacer()
                HStack {
                    Text("E").font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(template.lookStatus == .exampleAvailable ? .green : .gray)
                        .padding(4)
                        .background(Circle().fill(Color(NSColor.windowBackgroundColor).opacity(0.8)))
                        .padding(6)
                    Spacer()
                }
            }.frame(height: 140)
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? Color.accentColor.opacity(0.07) : Color.clear))
        .onTapGesture { onTap() }
        .onAppear { loadExampleImage() }
        .onChange(of: template.lookStatus) { _, _ in loadExampleImage() }
    }

    private func loadExampleImage() {
        exampleImage = StorageService.shared.loadLookExample(lookName: template.name)
    }
}
