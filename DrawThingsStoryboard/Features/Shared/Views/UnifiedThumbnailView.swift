import SwiftUI

// MARK: - Thumbnail item type

/// Visual category for unified thumbnails.
enum ThumbnailItemType {
    case character(gender: CharacterGender?)
    case location(setting: LocationSetting?)
    case look
    case panel
    case modelConfig

    var backgroundColor: Color {
        switch self {
        case .character:   return .blue
        case .location:    return .green
        case .look:        return .orange
        case .panel:       return .yellow
        case .modelConfig: return Color(red: 0.7, green: 0.5, blue: 0.9)
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
        case .modelConfig:           return "gearshape"
        }
    }

    var iconColor: Color {
        backgroundColor.opacity(0.7)
    }

    /// Human-readable type name for accessibility.
    var accessibilityTypeName: String {
        switch self {
        case .character: return "Character"
        case .location:  return "Location"
        case .look:      return "Look"
        case .panel:     return "Panel"
        case .modelConfig: return "Model Configuration"
        }
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

// MARK: - Asset status flags (V/S/L indicator)

/// Three-flag status indicator for CastingItem thumbnails.
struct AssetStatusFlags {
    var variantsAvailable: Bool
    var smallImageAvailable: Bool
    var largeImageAvailable: Bool

    /// Accessibility description of all three flags.
    var accessibilityDescription: String {
        let v = variantsAvailable ? "Variants available" : "No variants"
        let s = smallImageAvailable ? "small image available" : "no small image"
        let l = largeImageAvailable ? "large image available" : "no large image"
        return "\(v), \(s), \(l)"
    }
}

// MARK: - Badge configuration

struct ThumbnailBadges {
    var showStatusDot: Bool = false
    var statusColor: Color = .gray
    var assetStatus: AssetStatusFlags? = nil
    var panelStatus: PanelStatusFlags? = nil
    var showExampleIndicator: Bool = false
    var exampleAvailable: Bool = false
    var showDeleteButton: Bool = false
    var onDelete: (() -> Void)? = nil
    var showApprovedBadge: Bool = false
    var levelBadgeText: String? = nil
    var levelBadgeColor: Color = .blue
    var showInheritanceArrow: Bool = false
    var showSelectionStroke: Bool = false
}

// MARK: - Unified thumbnail view

struct UnifiedThumbnailView: View {
    let itemType: ThumbnailItemType
    let name: String
    let sizeMode: ThumbnailSizeMode
    var badges: ThumbnailBadges = ThumbnailBadges()

    // MARK: Accessibility helpers

    private var accessibilityLabel: String {
        name.isEmpty ? itemType.accessibilityTypeName : "\(name), \(itemType.accessibilityTypeName)"
    }

    private var accessibilityValue: String {
        if let flags = badges.assetStatus {
            return flags.accessibilityDescription
        } else if let flags = badges.panelStatus {
            let s = flags.smallPanelAvailable ? "small panel available" : "no small panel"
            let l = flags.largePanelAvailable ? "large panel available" : "no large panel"
            return "\(s), \(l)"
        } else if badges.showExampleIndicator {
            return badges.exampleAvailable ? "Example image available" : "No example image"
        }
        return ""
    }

    var body: some View {
        VStack(spacing: sizeMode == .compact ? 2 : 4) {
            ZStack {
                thumbnailBackground

                Image(systemName: itemType.icon)
                    .font(.system(size: sizeMode.iconSize))
                    .foregroundStyle(itemType.iconColor)
                    .accessibilityHidden(true)

                badgeOverlays
            }
            .frame(width: sizeMode.width, height: sizeMode.height)
            .clipped()
            .overlay(selectionStroke)

            if sizeMode != .compact && !name.isEmpty {
                Text(name)
                    .font(sizeMode == .header ? .caption : .caption2)
                    .lineLimit(sizeMode == .header ? 2 : 1)
                    .multilineTextAlignment(.center)
                    .accessibilityHidden(true) // covered by container label
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }

    @ViewBuilder
    private var thumbnailBackground: some View {
        if let w = sizeMode.width {
            RoundedRectangle(cornerRadius: sizeMode.cornerRadius)
                .fill(itemType.backgroundFill)
                .frame(width: w, height: sizeMode.height)
                .accessibilityHidden(true)
        } else {
            RoundedRectangle(cornerRadius: sizeMode.cornerRadius)
                .fill(itemType.backgroundFill)
                .frame(maxWidth: .infinity)
                .frame(height: sizeMode.height)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var badgeOverlays: some View {
        if badges.showApprovedBadge {
            VStack {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: sizeMode == .compact ? 9 : 13))
                        .foregroundStyle(.green)
                        .padding(sizeMode == .compact ? 2 : 4)
                        .accessibilityLabel("Approved")
                    Spacer()
                }
                Spacer()
            }
        }

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
                    .accessibilityLabel("Delete \(name)")
                    .accessibilityHint("Removes this item from the list")
                }
                Spacer()
            }
        }

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
                    .accessibilityHidden(true) // level info covered by container accessibilityValue
                    Spacer()
                }
            }
        }

        if let flags = badges.assetStatus {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    HStack(spacing: sizeMode == .compact ? 1 : 2) {
                        Text("V").foregroundStyle(flags.variantsAvailable ? .green : .gray)
                        Text("S").foregroundStyle(flags.smallImageAvailable ? .green : .gray)
                        Text("L").foregroundStyle(flags.largeImageAvailable ? .green : .gray)
                    }
                    .font(.system(size: sizeMode == .compact ? 6 : 8, weight: .bold, design: .monospaced))
                    .padding(.horizontal, sizeMode == .compact ? 2 : 4)
                    .padding(.vertical, 1)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 3))
                    .padding(sizeMode == .compact ? 2 : 4)
                    .accessibilityHidden(true) // spoken via container accessibilityValue
                }
            }
        } else if let flags = badges.panelStatus {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    HStack(spacing: sizeMode == .compact ? 1 : 2) {
                        Text("S").foregroundStyle(flags.smallPanelAvailable ? .green : .gray)
                        Text("L").foregroundStyle(flags.largePanelAvailable ? .green : .gray)
                    }
                    .font(.system(size: sizeMode == .compact ? 6 : 8, weight: .bold, design: .monospaced))
                    .padding(.horizontal, sizeMode == .compact ? 2 : 4)
                    .padding(.vertical, 1)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 3))
                    .padding(sizeMode == .compact ? 2 : 4)
                    .accessibilityHidden(true)
                }
            }
        } else if badges.showExampleIndicator {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("E")
                        .foregroundStyle(badges.exampleAvailable ? .green : .gray)
                        .font(.system(size: sizeMode == .compact ? 6 : 8, weight: .bold, design: .monospaced))
                        .padding(.horizontal, sizeMode == .compact ? 2 : 4)
                        .padding(.vertical, 1)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 3))
                        .padding(sizeMode == .compact ? 2 : 4)
                        .accessibilityHidden(true)
                }
            }
        } else if badges.showStatusDot {
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
                        .accessibilityHidden(true)
                }
            }
        }
    }

    @ViewBuilder
    private var selectionStroke: some View {
        if badges.showSelectionStroke {
            RoundedRectangle(cornerRadius: sizeMode.cornerRadius)
                .stroke(Color.accentColor, lineWidth: 1.5)
                .accessibilityHidden(true)
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

    var assetStatusFlags: AssetStatusFlags {
        AssetStatusFlags(
            variantsAvailable: variantsAvailable,
            smallImageAvailable: smallImageAvailable,
            largeImageAvailable: largeImageAvailable
        )
    }
}
