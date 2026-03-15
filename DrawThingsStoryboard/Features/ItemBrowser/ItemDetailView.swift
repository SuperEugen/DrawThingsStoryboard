import SwiftUI

/// Right pane: properties panel for the selected item.
/// Shows a placeholder when nothing is selected.
struct ItemDetailView: View {

    let section: AppSection?
    let itemID: String?

    private var item: MockItem? {
        guard let itemID else { return nil }
        return MockItems.items(for: section).first { $0.id == itemID }
    }

    var body: some View {
        if let item {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // ── Thumbnail placeholder ────────────────────────
                    RoundedRectangle(cornerRadius: 12)
                        .fill(item.color.opacity(0.15))
                        .overlay {
                            Image(systemName: item.icon)
                                .font(.system(size: 60))
                                .foregroundStyle(item.color)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)

                    // ── Name ─────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Name", systemImage: "textformat")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.name)
                            .font(.title3.bold())
                    }

                    Divider()

                    // ── Meta properties (mock) ────────────────────────
                    PropertyRow(label: "Section", value: section?.title ?? "—")
                    PropertyRow(label: "Status", value: item.status)
                    PropertyRow(label: "Variants", value: "\(item.variantCount)")
                    PropertyRow(label: "ID", value: item.id)

                    Spacer()
                }
                .padding(16)
            }
            .background(Color(NSColor.windowBackgroundColor))
        } else {
            ContentUnavailableView(
                "Nothing selected",
                systemImage: "square.dashed",
                description: Text("Select an item from the browser to see its properties.")
            )
        }
    }
}

// MARK: - Property Row

private struct PropertyRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    ItemDetailView(section: .casting, itemID: "c-01")
        .frame(width: 280, height: 600)
}
