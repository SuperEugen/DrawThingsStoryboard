import SwiftUI

// MARK: - Thumbnail item type

/// Visual category for unified thumbnails.
enum ThumbnailItemType {
    case character(gender: CharacterGender?)
    case location(setting: LocationSetting?)
    case look
    case panel

    var backgroundColor: Color {
        switch self {
        case .character: return .blue
        case .location:  return .green
        case .look:      return .orange
        case .panel:     return .yellow
        }
    }

    var backgroundFill: Color {
        backgroundColor.opacity(0.15)
    }

    var icon: String {
        switch self {
        case .character(let gender): return gender?.icon ?? "person.fill"
        case .location(let setting): return setting?.icon ?? "map"
        case .look:                  return "paintpalette"
        case .panel:                 return "video.fill"
        }
    }

    var iconColor: Color {
        backgroundColor.opacity(0.7)
    }
}

// MARK: - Size mode

enum ThumbnailSizeMode {
    case standard       // 288 x 160 — grids, browsers, pickers
    case header         // full width x 160 — detail view headers
    case compact        // 80 x 45 — production queue rows

    var width: CGFloat? {
        switch self {
        case .standard: return 288
        case .header:   return nil
        case .compact:  return 80
        }
    }

    var height: CGFloat {
        switch self {
        case .standard: return 160
        case .header:   return 160
        case .compact:  return 45
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .standard: return 40
        case .header:   return 52
        case .compact:  return 18
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .standard: return 10
        case .header:   return 10
        case .compact:  return 6
        }
    }
}

// MARK: - Badge configuration

struct ThumbnailBadges {
    var showStatusDot: Bool = false
    var statusColor: Color = .gray

    var showDeleteButton: Bool = false
    var onDelete: (() -> Void)? = nil

    var showApprovedBadge: Bool = false

    /// Bottom-left badge text (e.g. "ST", "CU", "EP", "CH", "LO").
    var levelBadgeText: String? = nil
    var levelBadgeColor: Color = .blue

    /// Inheritance arrow shown next to the level badge (for Preferred Look).
    var showInheritanceArrow: Bool = false

    var showSelectionStroke: Bool = false
}

// MARK: - Unified thumbnail view

struct UnifiedThumbnailView: View {
    let itemType: ThumbnailItemType
    let name: String
    let sizeMode: ThumbnailSizeMode
    var badges: ThumbnailBadges = ThumbnailBadges()

    var body: some View {
        VStack(spacing: sizeMode == .compact ? 2 : 4) {
            ZStack {
                thumbnailBackground

                Image(systemName: itemType.icon)
                    .font(.system(size: sizeMode.iconSize))
                    .foregroundStyle(itemType.iconColor)

                badgeOverlays
            }
            .overlay(selectionStroke)

            if sizeMode != .compact && !name.isEmpty {
                Text(name)
                    .font(sizeMode == .header ? .caption : .caption2)
                    .lineLimit(sizeMode == .header ? 2 : 1)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var thumbnailBackground: some View {
        if let w = sizeMode.width {
            RoundedRectangle(cornerRadius: sizeMode.cornerRadius)
                .fill(itemType.backgroundFill)
                .frame(width: w, height: sizeMode.height)
        } else {
            RoundedRectangle(cornerRadius: sizeMode.cornerRadius)
                .fill(itemType.backgroundFill)
                .frame(maxWidth: .infinity)
                .frame(height: sizeMode.height)
        }
    }

    // MARK: - Badge overlays

    @ViewBuilder
    private var badgeOverlays: some View {
        // Top-left: Approved badge
        if badges.showApprovedBadge {
            VStack {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: sizeMode == .compact ? 9 : 13))
                        .foregroundStyle(.green)
                        .padding(sizeMode == .compact ? 2 : 4)
                    Spacer()
                }
                Spacer()
            }
        }

        // Top-right: Delete button
        if badges.showDeleteButton, let onDelete = badges.onDelete {
            VStack {
                HStack {
                    Spacer()
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: sizeMode == .compact ? 9 : 12))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(sizeMode == .compact ? 1 : 2)
                }
                Spacer()
            }
        }

        // Bottom-left: Level/type badge
        if let text = badges.levelBadgeText {
            VStack {
                Spacer()
                HStack {
                    HStack(spacing: 1) {
                        Text(text)
                            .font(.system(size: sizeMode == .compact ? 6 : 8, weight: .bold))
                        if badges.showInheritanceArrow {
                            Image(systemName: "arrow.right")
                                .font(.system(size: sizeMode == .compact ? 5 : 6, weight: .bold))
                        }
                    }
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(badges.levelBadgeColor.opacity(0.2), in: RoundedRectangle(cornerRadius: 3))
                    .foregroundStyle(badges.levelBadgeColor)
                    .padding(sizeMode == .compact ? 2 : 3)
                    Spacer()
                }
            }
        }

        // Bottom-right: Status dot
        if badges.showStatusDot {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Circle()
                        .fill(badges.statusColor)
                        .frame(
                            width: sizeMode == .compact ? 4 : 6,
                            height: sizeMode == .compact ? 4 : 6
                        )
                        .padding(sizeMode == .compact ? 2 : 4)
                }
            }
        }
    }

    // MARK: - Selection stroke

    @ViewBuilder
    private var selectionStroke: some View {
        if badges.showSelectionStroke {
            RoundedRectangle(cornerRadius: sizeMode.cornerRadius)
                .stroke(Color.accentColor, lineWidth: 1.5)
        }
    }
}

// MARK: - CastingItem convenience

extension CastingItem {
    var thumbnailType: ThumbnailItemType {
        switch type {
        case .character: return .character(gender: gender)
        case .location:  return .location(setting: locationSetting)
        }
    }
}

#Preview("Standard — All Types") {
    HStack(spacing: 16) {
        UnifiedThumbnailView(
            itemType: .character(gender: .female),
            name: "Detective Rose",
            sizeMode: .standard,
            badges: ThumbnailBadges(
                showStatusDot: true, statusColor: .orange,
                levelBadgeText: "EP", levelBadgeColor: .blue
            )
        )
        UnifiedThumbnailView(
            itemType: .location(setting: .exterior),
            name: "City Park",
            sizeMode: .standard,
            badges: ThumbnailBadges(
                showStatusDot: true, statusColor: .green,
                showApprovedBadge: true,
                levelBadgeText: "ST", levelBadgeColor: .purple
            )
        )
        UnifiedThumbnailView(
            itemType: .look,
            name: "Noir Style",
            sizeMode: .standard,
            badges: ThumbnailBadges(
                showStatusDot: true, statusColor: .purple
            )
        )
        UnifiedThumbnailView(
            itemType: .panel,
            name: "Panel 01",
            sizeMode: .standard,
            badges: ThumbnailBadges(
                showStatusDot: true, statusColor: .gray,
                showSelectionStroke: true
            )
        )
    }
    .padding()
}

#Preview("Compact — Queue Row") {
    HStack(spacing: 8) {
        UnifiedThumbnailView(
            itemType: .character(gender: .male),
            name: "",
            sizeMode: .compact
        )
        UnifiedThumbnailView(
            itemType: .look,
            name: "",
            sizeMode: .compact
        )
        UnifiedThumbnailView(
            itemType: .location(setting: .interior),
            name: "",
            sizeMode: .compact
        )
        Spacer()
        Text("2m ago")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
    .padding()
}
