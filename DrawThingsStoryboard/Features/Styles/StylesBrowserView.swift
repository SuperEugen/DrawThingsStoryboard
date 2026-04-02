import SwiftUI

// MARK: - Styles browser

struct StylesBrowserView: View {
    @Binding var styles: StylesFile
    @Binding var selectedStyleID: String?
    private let columns = [GridItem(.adaptive(minimum: 288, maximum: 320), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "paintpalette").font(.title2).foregroundStyle(.secondary)
                Text("Styles").font(.title2.bold())
                Spacer()
                Button(action: addStyle) { Image(systemName: "plus").frame(width: 22, height: 22) }
                .buttonStyle(.bordered).controlSize(.mini)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            Divider()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(styles.styles) { style in
                        StyleTile(
                            style: style,
                            isSelected: selectedStyleID == style.styleID,
                            canDelete: styles.styles.count > 1,
                            onDelete: { removeStyle(id: style.styleID) },
                            onTap: { selectedStyleID = style.styleID }
                        )
                    }
                }
                .padding(16)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { ensureSelection() }
        .onChange(of: styles.styles.count) { _, _ in ensureSelection() }
    }

    private func addStyle() {
        let id = UUID().uuidString
        styles.styles.append(StyleEntry(styleID: id, name: "New Style", style: ""))
        selectedStyleID = id
    }

    private func removeStyle(id: String) {
        guard styles.styles.count > 1, let idx = styles.styles.firstIndex(where: { $0.styleID == id }) else { return }
        styles.styles.remove(at: idx)
        if selectedStyleID == id || !styles.styles.contains(where: { $0.styleID == selectedStyleID }) {
            selectedStyleID = styles.styles[min(idx, styles.styles.count - 1)].styleID
        }
    }

    private func ensureSelection() {
        if selectedStyleID == nil || !styles.styles.contains(where: { $0.styleID == selectedStyleID }) {
            selectedStyleID = styles.styles.first?.styleID
        }
    }
}

// MARK: - Style tile

struct StyleTile: View {
    let style: StyleEntry
    let isSelected: Bool
    let canDelete: Bool
    let onDelete: () -> Void
    let onTap: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                UnifiedThumbnailView(
                    itemType: .style, name: "", sizeMode: .standard,
                    badges: ThumbnailBadges(
                        showExampleIndicator: true,
                        exampleAvailable: style.isGenerated
                    )
                )
                Text(style.name).font(.callout.weight(.medium)).lineLimit(1)
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
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? Color.accentColor.opacity(0.07) : Color.clear))
        .onTapGesture { onTap() }
    }
}
