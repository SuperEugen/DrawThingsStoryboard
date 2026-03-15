import SwiftUI

/// Center pane: header + scrollable item grid for the selected phase.
/// Uses mock data — no real filesystem access yet.
struct ItemBrowserView: View {

    let section: AppSection?
    @Binding var selectedItemID: String?

    private let columns = [
        GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ──────────────────────────────────────────────
            BrowserHeaderView(section: section)

            Divider()

            // ── Item Grid ────────────────────────────────────────────
            if MockItems.items(for: section).isEmpty {
                ContentUnavailableView(
                    "No items yet",
                    systemImage: section?.icon ?? "tray",
                    description: Text("Items created in this phase will appear here.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(MockItems.items(for: section)) { item in
                            ItemTileView(item: item, isSelected: selectedItemID == item.id)
                                .onTapGesture { selectedItemID = item.id }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onChange(of: section) { _, _ in selectedItemID = nil }
    }
}

// MARK: - Header

private struct BrowserHeaderView: View {

    let section: AppSection?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if let section {
                Image(systemName: section.icon)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(section.title)
                    .font(.title2.bold())
                Spacer()
                Text("\(MockItems.items(for: section).count) items")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Item Tile

private struct ItemTileView: View {

    let item: MockItem
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 10)
                .fill(item.color.opacity(0.18))
                .overlay {
                    Image(systemName: item.icon)
                        .font(.system(size: 36))
                        .foregroundStyle(item.color)
                }
                .frame(height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )

            Text(item.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
        )
    }
}

#Preview {
    ItemBrowserView(section: .casting, selectedItemID: .constant(nil))
        .frame(width: 500, height: 600)
}
