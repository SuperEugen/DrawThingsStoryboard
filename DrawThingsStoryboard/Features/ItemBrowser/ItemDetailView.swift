import SwiftUI

/// Right pane — switches between project detail and generic detail.
struct ItemDetailView: View {

    let section: AppSection?

    // Project hierarchy (mutable for editing name/rules)
    @Binding var studios: [MockStudio]
    let selectedStudioID: String?
    let selectedCustomerID: String?
    let selectedEpisodeID: String?
    let selectedBriefingLevel: BriefingLevel

    // Generic
    let selectedItemID: String?

    // Looks (templates) for Preferred Look display
    let templates: [GenerationTemplate]

    var body: some View {
        switch section {
        case .projects:
            BriefingDetailView(
                studios: $studios,
                selectedStudioID: selectedStudioID,
                selectedCustomerID: selectedCustomerID,
                selectedEpisodeID: selectedEpisodeID,
                level: selectedBriefingLevel,
                templates: templates
            )
        default:
            if let itemID = selectedItemID,
               let item = MockData.items(for: section).first(where: { $0.id == itemID }) {
                GenericDetailView(item: item)
            } else {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nothing selected",
            systemImage: "square.dashed",
            description: Text("Select an item to see its properties.")
        )
    }
}

// MARK: - Generic detail

private struct GenericDetailView: View {
    let item: MockItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color.opacity(0.12))
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .overlay {
                        Image(systemName: item.icon)
                            .font(.system(size: 44))
                            .foregroundStyle(item.color)
                    }
                Text(item.name).font(.title3.bold())
                Divider()
                LabeledContent("Status")   { Text(item.status).foregroundStyle(.secondary) }
                LabeledContent("Variants") { Text("\(item.variantCount)").foregroundStyle(.secondary) }
                LabeledContent("ID")       { Text(item.id).font(.caption.monospaced()).foregroundStyle(.tertiary) }
                Spacer()
            }
            .padding(14)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Shared section label helper

/// Styled uppercase label used across all detail views.
func sectionLabel(_ title: String) -> some View {
    Text(title)
        .font(.caption)
        .foregroundStyle(.tertiary)
        .textCase(.uppercase)
        .tracking(0.5)
}

#Preview("Project — Episode") {
    @Previewable @State var studios = MockData.defaultStudios
    ItemDetailView(
        section: .projects,
        studios: $studios,
        selectedStudioID: MockData.defaultStudios[0].id,
        selectedCustomerID: MockData.defaultStudios[0].customers[0].id,
        selectedEpisodeID: MockData.defaultStudios[0].customers[0].episodes[0].id,
        selectedBriefingLevel: .episode,
        selectedItemID: nil,
        templates: MockData.defaultTemplates
    )
    .frame(width: 280, height: 700)
}
#Preview("Project — Studio") {
    @Previewable @State var studios = MockData.defaultStudios
    ItemDetailView(
        section: .projects,
        studios: $studios,
        selectedStudioID: MockData.defaultStudios[0].id,
        selectedCustomerID: MockData.defaultStudios[0].customers[0].id,
        selectedEpisodeID: MockData.defaultStudios[0].customers[0].episodes[0].id,
        selectedBriefingLevel: .studio,
        selectedItemID: nil,
        templates: MockData.defaultTemplates
    )
    .frame(width: 280, height: 700)
}
