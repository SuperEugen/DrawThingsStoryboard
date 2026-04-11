import AppKit
import CoreGraphics
import UniformTypeIdentifiers

/// #47: PDF export service for storyboard panels.
/// Default template: 2x3 grid, A4 portrait.
enum PDFExportService {

    // MARK: - Template constants (default 2x3 A4)

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
        let contentHeight = pageHeight - margin * 2 - headerHeight - 20
        let cellWidth = (contentWidth - cellSpacingH * CGFloat(columns - 1)) / CGFloat(columns)
        let cellHeight = (contentHeight - cellSpacingV * CGFloat(rows - 1)) / CGFloat(rows)

        let textAreaHeight: CGFloat = 36
        let imageHeight = min(cellHeight - textAreaHeight - 4, cellWidth * 9.0 / 16.0)
        let imageWidth = cellWidth

        let totalPages = max(1, (panels.count + panelsPerPage - 1) / panelsPerPage)

        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            throw PDFExportError.contextCreationFailed
        }

        for pageIndex in 0..<totalPages {
            context.beginPage(mediaBox: &mediaBox)
            context.translateBy(x: 0, y: pageHeight)
            context.scaleBy(x: 1, y: -1)

            drawHeader(
                context: context,
                title: headerTitle,
                pageNumber: pageIndex + 1,
                totalPages: totalPages
            )

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

    // MARK: - Character Sheet Export

    /// Export one page per character (large image + name caption).
    static func exportCharacterSheets(
        characters: [(name: String, imageID: String)],
        to url: URL
    ) throws {
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            throw PDFExportError.contextCreationFailed
        }

        let captionHeight: CGFloat = 28
        let imageAreaHeight = pageHeight - margin * 2 - captionHeight - 8

        for character in characters {
            context.beginPage(mediaBox: &mediaBox)
            context.translateBy(x: 0, y: pageHeight)
            context.scaleBy(x: 1, y: -1)

            let imageRect = CGRect(x: margin, y: margin, width: pageWidth - margin * 2, height: imageAreaHeight)

            if let nsImage = StorageService.shared.loadImage(id: character.imageID),
               let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                let imgAspect = CGFloat(cgImage.width) / CGFloat(cgImage.height)
                let boxAspect = imageRect.width / imageRect.height
                var drawRect: CGRect
                if imgAspect > boxAspect {
                    let h = imageRect.width / imgAspect
                    drawRect = CGRect(x: imageRect.minX, y: imageRect.minY + (imageRect.height - h) / 2,
                                     width: imageRect.width, height: h)
                } else {
                    let w = imageRect.height * imgAspect
                    drawRect = CGRect(x: imageRect.minX + (imageRect.width - w) / 2, y: imageRect.minY,
                                     width: w, height: imageRect.height)
                }
                context.saveGState()
                context.translateBy(x: drawRect.origin.x, y: drawRect.origin.y + drawRect.height)
                context.scaleBy(x: 1, y: -1)
                context.draw(cgImage, in: CGRect(origin: .zero, size: drawRect.size))
                context.restoreGState()
            } else {
                context.setFillColor(NSColor.quaternaryLabelColor.cgColor)
                context.fill(imageRect)
            }

            let captionFont = NSFont.boldSystemFont(ofSize: 14)
            let nameWidth = measureText(character.name, font: captionFont)
            let captionX = margin + (pageWidth - margin * 2 - nameWidth) / 2
            let captionY = margin + imageAreaHeight + 10
            drawText(character.name, in: context, at: CGPoint(x: captionX, y: captionY),
                     font: captionFont)

            context.endPage()
        }

        context.closePDF()
    }

    /// Show NSSavePanel and export character sheets.
    @MainActor
    static func exportCharacterSheetsWithSavePanel(
        characters: [(name: String, imageID: String)],
        defaultFilename: String
    ) {
        let panel = NSSavePanel()
        panel.title = "Export Character Sheets"
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = defaultFilename
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try exportCharacterSheets(characters: characters, to: url)
            NSWorkspace.shared.open(url)
        } catch {
            print("[PDFExport] Character sheets error: \(error)")
        }
    }

    // MARK: - Drawing helpers

    private static func drawText(
        _ text: String,
        in context: CGContext,
        at point: CGPoint,
        font: NSFont,
        color: NSColor = .labelColor
    ) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let attrStr = NSAttributedString(string: text, attributes: attrs)
        let line = CTLineCreateWithAttributedString(attrStr)
        context.saveGState()
        context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        context.textPosition = CGPoint(x: point.x, y: point.y + font.pointSize)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    private static func measureText(_ text: String, font: NSFont) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let attrStr = NSAttributedString(string: text, attributes: attrs)
        let line = CTLineCreateWithAttributedString(attrStr)
        return CTLineGetTypographicBounds(line, nil, nil, nil)
    }

    private static func drawHeader(
        context: CGContext,
        title: String,
        pageNumber: Int,
        totalPages: Int
    ) {
        drawText(title, in: context, at: CGPoint(x: margin, y: margin + 4),
                 font: .boldSystemFont(ofSize: headerFontSize))

        let pageText = "Page \(pageNumber) of \(totalPages)"
        let pageFont = NSFont.systemFont(ofSize: pageLabelFontSize)
        let pw = measureText(pageText, font: pageFont)
        drawText(pageText, in: context, at: CGPoint(x: Self.pageWidth - margin - pw, y: margin + 4),
                 font: pageFont, color: .secondaryLabelColor)

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
        let imageRect = CGRect(x: x, y: y, width: imageWidth, height: imageHeight)

        if let imageID = bestImageID(for: panel),
           let nsImage = StorageService.shared.loadImage(id: imageID),
           let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let imgAspect = CGFloat(cgImage.width) / CGFloat(cgImage.height)
            let boxAspect = imageWidth / imageHeight
            var drawRect: CGRect
            if imgAspect > boxAspect {
                let h = imageWidth / imgAspect
                drawRect = CGRect(x: x, y: y + (imageHeight - h) / 2, width: imageWidth, height: h)
            } else {
                let w = imageHeight * imgAspect
                drawRect = CGRect(x: x + (imageWidth - w) / 2, y: y, width: w, height: imageHeight)
            }
            context.saveGState()
            context.translateBy(x: drawRect.origin.x, y: drawRect.origin.y + drawRect.height)
            context.scaleBy(x: 1, y: -1)
            context.draw(cgImage, in: CGRect(origin: .zero, size: drawRect.size))
            context.restoreGState()
        } else {
            context.setFillColor(NSColor.quaternaryLabelColor.cgColor)
            context.fill(imageRect)
        }

        // Panel name (title)
        let titleY = y + imageHeight + 4
        drawText(panel.name, in: context, at: CGPoint(x: x, y: titleY),
                 font: .boldSystemFont(ofSize: titleFontSize))

        // Description (caption, truncated)
        let captionY = titleY + titleFontSize + 6
        let descText = panel.description
        if !descText.isEmpty {
            let maxChars = Int(cellWidth / captionFontSize * 2.2) * 2
            let truncated = descText.count > maxChars
                ? String(descText.prefix(maxChars)) + "\u{2026}"
                : descText
            drawText(truncated, in: context, at: CGPoint(x: x, y: captionY),
                     font: .systemFont(ofSize: captionFontSize), color: .secondaryLabelColor)
        }

        // Duration badge (top-right of image)
        if panel.duration > 0 {
            let badgeText = "\(panel.duration)s"
            let badgeFont = NSFont.monospacedDigitSystemFont(ofSize: 7, weight: .medium)
            let bw = measureText(badgeText, font: badgeFont) + 6
            let bh: CGFloat = 12
            let bx = x + imageWidth - bw - 4
            let by = y + 4

            context.setFillColor(NSColor.black.withAlphaComponent(0.5).cgColor)
            context.fill(CGRect(x: bx, y: by, width: bw, height: bh))
            drawText(badgeText, in: context, at: CGPoint(x: bx + 3, y: by + 1),
                     font: badgeFont, color: .white)
        }
    }

    // MARK: - Helpers

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
