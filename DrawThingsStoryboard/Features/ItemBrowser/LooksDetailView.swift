import SwiftUI

// MARK: - Looks detail (style/prompt editor)

struct LooksDetailView: View {
    @Binding var templates: [GenerationTemplate]
    @Binding var selectedTemplateID: String?
    @Binding var generationQueue: [GenerationJob]

    private var selectedIndex: Int? {
        guard let id = selectedTemplateID else { return nil }
        return templates.firstIndex { $0.id == id }
    }

    var body: some View {
        if let idx = selectedIndex {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    UnifiedThumbnailView(
                        itemType: .look,
                        name: "",
                        sizeMode: .header
                    )
                    .padding(.bottom, 16)

                    // Name
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Name")
                        TextField("Look name", text: $templates[idx].name)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.bottom, 12)

                    Divider().padding(.vertical, 8)

                    // Description / Prompt
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Description")
                        Text("Describe the visual style — this text is appended to every prompt.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 2)
                        TextEditor(text: $templates[idx].description)
                            .font(.callout)
                            .frame(minHeight: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
                            )
                    }
                    .padding(.bottom, 12)

                    Spacer(minLength: 20)
                }
                .padding(14)
            }
            .background(Color(NSColor.windowBackgroundColor))
        } else {
            ContentUnavailableView(
                "No look selected",
                systemImage: "paintpalette",
                description: Text("Select a look from the list to edit its style prompt.")
            )
        }
    }
}
