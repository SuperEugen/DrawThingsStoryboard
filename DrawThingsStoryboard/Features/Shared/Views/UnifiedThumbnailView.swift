import SwiftUI

// MARK: - Thumbnail item type

enum ThumbnailItemType {
    case character(subType: String)
    case location(subType: String)
    case style
    case panel
    case model

    var backgroundColor: Color {
        switch self {
        case .character: return .blue
        case .location:  return .green
        case .style:     return .orange
        case .panel:     return .yellow
        case .model:     return Color(red: 0.7, green: 0.5, blue: 0.9)
        }
    }

    var backgroundFill: Color { backgroundColor.opacity(0.15) }

    var icon: String {
        switch self {
        case .character(let subType):
            switch subType {
            case "female": return "figure.stand.dress"
            case "male":   return "figure.stand"
            default:        return "dog"
            }
        case .location(let subType):
            return subType == "exterior" ? "tree" : "sofa"
        case .style:  return "paintpalette"
        case .panel:  return "list.and.film"
        case .model:  return "camera"
        }
    }

    var iconColor: Color { backgroundColor.opacity(0.7) }
}

// MARK: - Size mode

enum ThumbnailSizeMode {
    case standard
    case header
    case compact

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
/// #68: showLargeImageIndicator for browser tiles
/// #74: showEyeIndicator for detail variant thumbnails

struct ThumbnailBadges {
    var showExampleIndicator: Bool = false
    var exampleAvailable: Bool = false
    var showDeleteButton: Bool = false
    var onDelete: (() -> Void)? = nil
    var showApprovedBadge: Bool = false
    var showSelectionStroke: Bool = false
    var showLargeImageIndicator: Bool = false
    var showEyeIndicator: Bool = false
}

// MARK: - Unified thumbnail view

struct UnifiedThumbnailView: View {
    let itemType: ThumbnailItemType
    let name: String
    let sizeMode: ThumbnailSizeMode
    var badges: ThumbnailBadges = ThumbnailBadges()
    var imageID: String = ""

    private var loadedImage: NSImage? {
        guard !imageID.isEmpty else { return nil }
        return StorageService.shared.loadImage(id: imageID)
    }

    var body: some View {
        VStack(spacing: sizeMode == .compact ? 2 : 4) {
            ZStack {
                thumbnailBackground

                if let img = loadedImage {
                    Image(nsImage: img)
                        .resizable().scaledToFill()
                        .frame(width: sizeMode.width, height: sizeMode.height)
                        .clipShape(RoundedRectangle(cornerRadius: sizeMode.cornerRadius))
                } else {
                    Image(systemName: itemType.icon)
                        .font(.system(size: sizeMode.iconSize))
                        .foregroundStyle(itemType.iconColor)
                }

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
            }
        }
    }

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

    @ViewBuilder
    private var badgeOverlays: some View {
        // Upper left: approved badge
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

        // Upper right: delete button
        if badges.showDeleteButton, let onDelete = badges.onDelete {
            VStack {
                HStack {
                    Spacer()
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: sizeMode == .compact ? 9 : 12))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .secondary)
                    }.buttonStyle(.plain).padding(sizeMode == .compact ? 1 : 2)
                }
                Spacer()
            }
        }

        // Lower left: large image indicator (#68)
        if badges.showLargeImageIndicator {
            VStack {
                Spacer()
                HStack {
                    Image(systemName: "arrow.up.left.and.arrow.down.right.rectangle")
                        .font(.system(size: sizeMode == .compact ? 7 : 10))
                        .foregroundStyle(.white)
                        .padding(.horizontal, sizeMode == .compact ? 2 : 4)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 3))
                        .padding(sizeMode == .compact ? 2 : 4)
                    Spacer()
                }
            }
        }

        // Lower right: eye indicator (#74)
        if badges.showEyeIndicator {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "eye")
                        .font(.system(size: sizeMode == .compact ? 7 : 10))
                        .foregroundStyle(.white)
                        .padding(.horizontal, sizeMode == .compact ? 2 : 4)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 3))
                        .padding(sizeMode == .compact ? 2 : 4)
                }
            }
        }

        // Lower right: example indicator (for styles, kept for backward compat)
        if badges.showExampleIndicator {
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
                }
            }
        }
    }

    @ViewBuilder
    private var selectionStroke: some View {
        if badges.showSelectionStroke {
            RoundedRectangle(cornerRadius: sizeMode.cornerRadius)
                .stroke(Color.accentColor, lineWidth: 1.5)
        }
    }
}

// MARK: - Shared section label helper

func sectionLabel(_ title: String) -> some View {
    Text(title)
        .font(.caption)
        .foregroundStyle(.tertiary)
        .textCase(.uppercase)
        .tracking(0.5)
}
