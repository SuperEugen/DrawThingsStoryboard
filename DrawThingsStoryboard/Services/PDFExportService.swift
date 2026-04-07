import AppKit
import CoreGraphics

/// #47: PDF export service for storyboard panels.
/// Default template: 2×3 grid, A4 portrait.
enum PDFExportService {

    // MARK: - Template constants (default 2×3 A4)

    private static let pageWidth: CGFloat = 595    // A4 portrait
    private static let pageHeight: CGFloat = 842
    private static let margin: CGFloat = 40
    private static let columns = 2
    private static let rows = 3
    private static let cellSpacingH: CGFloat = 16
    private static let cellSpacingV: CGFloat = 12
    private static let headerHeight: CGFloat = 36
    private static let titleFontSize: CGFloat = 10
    private static let captionFontSize: CGFloat = 8
    private static let headerFontSize: CGFloat = 12
    private static let pageLabelFontSize: CGFloat = 9
    private static let panelsPerPage = columns * rows

    // MARK: - Public API

    /// Export panels as a PDF to the given URL.
    static func exportPDF(
        panels: [PanelEntry],
        headerTitle: String,
        to url: URL
    ) throws {
        let contentWidth = pageWidth - margin * 2
        let contentHeight = pageHeight - margin * 2 - headerHeight - 20 // 20pt for page number
        let cellWidth = (contentWidth - cellSpacingH * CGFloat(columns - 1)) / CGFloat(columns)
        let cellHeight = (contentHeight - cellSpacingV * CGFloat(rows - 1)) / CGFloat(rows)

        // Image area: 16:9 aspect within cell, leaving room for text
        let textAreaHeight: CGFloat = 36 // space for title + caption
        let imageHeight = min(cellHeight - textAreaHeight - 4, cellWidth * 9.0 / 16.0)
        let imageWidth = cellWidth

        let totalPages = max(1, (panels.count + panelsPerPage - 1) / panelsPerPage)

        // Create PDF context
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            throw PDFExportError.contextCreationFailed
        }

        for pageIndex in 0..<totalPages {
            context.beginPage(mediaBox: &mediaBox)

            // Flip coordinate system (CG is bottom-up, we want top-down)
            context.translateBy(x: 0, y: pageHeight)
            context.scaleBy(x: 1, y: -1)

            // Draw header
            drawHeader(
                context: context,
                title: headerTitle,
                pageNumber: pageIndex + 1,
                totalPages: totalPages
            )

            // Draw panel cells
            let startIndex = pageIndex * panelsPerPage
            for slot in 0..<panelsPerPage {
                let panelIndex = startIndex + slot
                let col = slot % columns
                let row = slot / columns

                let x = margin + CGFloat(col) * (cellWidth + cellSpacingH)
                let y = margin + headerHeight + CGFloat(row) * (cellHeight + cellSpacingV)

                if panelIndex < panels.count {
                    drawPanelCell(
                        context: context,
                        panel: panels[panelIndex],
                        x: x, y: y,
                        cellWidth: cellWidth,
                        imageWidth: imageWidth,
                        imageHeight: imageHeight
                    )
                }
            }

            context.endPage()
        }

        context.closePDF()
    }

    /// Show NSSavePanel and export.
    @MainActor
    static func exportWithSavePanel(
        panels: [PanelEntry],
        headerTitle: String,
        defaultFilename: String
    ) {
        let panel = NSSavePanel()
        panel.title = "Export Storyboard PDF"
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = defaultFilename
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try exportPDF(panels: panels, headerTitle: headerTitle, to: url)
            NSWorkspace.shared.open(url)
        } catch {
            print("[PDFExport] Error: \(error)")
        }
    }

    // MARK: - Drawing helpers

    private static func drawHeader(
        context: CGContext,
        title: String,
        pageNumber: Int,
        totalPages: Int
    ) {
        // Title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: headerFontSize),
            .foregroundColor: NSColor.labelColor
        ]
        let titleStr = NSAttributedString(string: title, attributes: titleAttrs)
        let titleLine = CTLineCreateWithAttributedString(titleStr)
        context.textPosition = CGPoint(x: margin, y: margin + 4)
        CTLineDraw(titleLine, context)

        // Page number (right-aligned)
        let pageAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: pageLabelFontSize),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let pageStr = NSAttributedString(string: "Page \(pageNumber) of \(totalPages)", attributes: pageAttrs)
        let pageLine = CTLineCreateWithAttributedString(pageStr)
        let pageWidth = CTLineGetTypographicBounds(pageLine, nil, nil, nil)
        context.textPosition = CGPoint(x: Self.pageWidth - margin - pageWidth, y: margin + 4)
        CTLineDraw(pageLine, context)

        // Divider line
        context.setStrokeColor(NSColor.separatorColor.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: margin, y: margin + headerHeight - 4))
        context.addLine(to: CGPoint(x: Self.pageWidth - margin, y: margin + headerHeight - 4))
        context.strokePath()
    }

    private static func drawPanelCell(
        context: CGContext,
        panel: PanelEntry,
        x: CGFloat, y: CGFloat,
        cellWidth: CGFloat,
        imageWidth: CGFloat,
        imageHeight: CGFloat
    ) {
        // Image area
        let imageRect = CGRect(x: x, y: y, width: imageWidth, height: imageHeight)

        if let imageID = bestImageID(for: panel),
           let nsImage = StorageService.shared.loadImage(id: imageID),
           let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            // Draw image scaled to fit
            let imgAspect = CGFloat(cgImage.width) / CGFloat(cgImage.height)
            let boxAspect = imageWidth / imageHeight
            var drawRect: CGRect
            if imgAspect > boxAspect {
                // Image wider than box — fit by width
                let h = imageWidth / imgAspect
                drawRect = CGRect(x: x, y: y + (imageHeight - h) / 2, width: imageWidth, height: h)
            } else {
                // Image taller than box — fit by height
                let w = imageHeight * imgAspect
                drawRect = CGRect(x: x + (imageWidth - w) / 2, y: y, width: w, height: imageHeight)
            }
            // CG draws images bottom-up, but we flipped the context, so we need to flip the image
            context.saveGState()
            context.translateBy(x: drawRect.origin.x, y: drawRect.origin.y + drawRect.height)
            context.scaleBy(x: 1, y: -1)
            context.draw(cgImage, in: CGRect(origin: .zero, size: drawRect.size))
            context.restoreGState()
        } else {
            // Placeholder rectangle
            context.setFillColor(NSColor.quaternaryLabelColor.cgColor)
            context.fill(imageRect)
            // Placeholder icon text
            let placeholderAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 20),
                .foregroundColor: NSColor.tertiaryLabelColor
            ]
            let placeholderStr = NSAttributedString(string: "\u{1F3AC}", attributes: placeholderAttrs)
            let placeholderLine = CTLineCreateWithAttributedString(placeholderStr)
            let pw = CTLineGetTypographicBounds(placeholderLine, nil, nil, nil)
            context.textPosition = CGPoint(
                x: x + (imageWidth - pw) / 2,
                y: y + imageHeight / 2 - 10
            )
            CTLineDraw(placeholderLine, context)
        }

        // Panel name (title)
        let titleY = y + imageHeight + 4
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: titleFontSize),
            .foregroundColor: NSColor.labelColor
        ]
        let titleStr = NSAttributedString(string: panel.name, attributes: titleAttrs)
        let titleLine = CTLineCreateWithAttributedString(titleStr)
        context.textPosition = CGPoint(x: x, y: titleY)
        CTLineDraw(titleLine, context)

        // Description (caption, truncated to ~2 lines)
        let captionY = titleY + titleFontSize + 4
        let descText = panel.description.isEmpty ? "" : panel.description
        if !descText.isEmpty {
            let captionAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: captionFontSize),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
            // Truncate to fit roughly 2 lines
            let maxChars = Int(cellWidth / captionFontSize * 2.2) * 2
            let truncated = descText.count > maxChars
                ? String(descText.prefix(maxChars)) + "\u{2026}"
                : descText
            let captionStr = NSAttributedString(string: truncated, attributes: captionAttrs)

            // Use CTFramesetter for multi-line text
            let framesetter = CTFramesetterCreateWithAttributedString(captionStr)
            let framePath = CGPath(rect: CGRect(x: x, y: captionY, width: cellWidth, height: captionFontSize * 2.5), transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), framePath, nil)

            // CTFrame draws in unflipped coords, so we flip locally
            context.saveGState()
            context.translateBy(x: 0, y: captionY * 2 + captionFontSize * 2.5)
            context.scaleBy(x: 1, y: -1)
            CTFrameDraw(frame, context)
            context.restoreGState()
        }

        // Duration badge (top-right of image)
        if panel.duration > 0 {
            let badgeText = "\(panel.duration)s"
            let badgeAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 7, weight: .medium),
                .foregroundColor: NSColor.white
            ]
            let badgeStr = NSAttributedString(string: badgeText, attributes: badgeAttrs)
            let badgeLine = CTLineCreateWithAttributedString(badgeStr)
            let bw = CTLineGetTypographicBounds(badgeLine, nil, nil, nil) + 6
            let bh: CGFloat = 12
            let bx = x + imageWidth - bw - 4
            let by = y + 4

            context.setFillColor(NSColor.black.withAlphaComponent(0.5).cgColor)
            let badgeRect = CGRect(x: bx, y: by, width: bw, height: bh)
            context.fill(badgeRect)
            context.textPosition = CGPoint(x: bx + 3, y: by + 2)
            CTLineDraw(badgeLine, context)
        }
    }

    // MARK: - Helpers

    /// Best image for a panel: large > small
    private static func bestImageID(for panel: PanelEntry) -> String? {
        if panel.hasLargeImage { return panel.largeImageID }
        if panel.hasSmallImage { return panel.smallImageID }
        return nil
    }
}

enum PDFExportError: LocalizedError {
    case contextCreationFailed

    var errorDescription: String? {
        switch self {
        case .contextCreationFailed:
            return "Failed to create PDF context."
        }
    }
}
