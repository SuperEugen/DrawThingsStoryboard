import AppKit
import Foundation

// MARK: - StorageService
//
// Manages persisting generated images to the file system.
//
// Structure under ~/Pictures/DrawThings-Storyboard/:
//   library/
//     assets/     ← Variant images  (<assetID>_v<n>.png)
//     examples/   ← Look examples   (<lookName>.png)
//   <EpisodeName>/
//     panels/     ← Panel images    (<panelID>.png)

enum StorageError: LocalizedError {
    case couldNotCreateDirectory(URL)
    case couldNotSaveImage(URL)

    var errorDescription: String? {
        switch self {
        case .couldNotCreateDirectory(let url):
            return "Could not create directory: \(url.path)"
        case .couldNotSaveImage(let url):
            return "Could not save image: \(url.path)"
        }
    }
}

final class StorageService {

    static let shared = StorageService()
    private init() {}

    // MARK: - Root

    /// ~/Pictures/DrawThings-Storyboard
    var rootURL: URL {
        FileManager.default
            .urls(for: .picturesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DrawThings-Storyboard")
    }

    // MARK: - Sub-directories

    var libraryURL: URL   { rootURL.appendingPathComponent("library") }
    var assetsURL: URL    { libraryURL.appendingPathComponent("assets") }
    var examplesURL: URL  { libraryURL.appendingPathComponent("examples") }

    func panelsURL(episodeName: String) -> URL {
        rootURL
            .appendingPathComponent(sanitize(episodeName))
            .appendingPathComponent("panels")
    }

    // MARK: - Save helpers

    /// Save a variant image.
    /// Returns the file URL on success.
    @discardableResult
    func saveVariantImage(
        _ image: NSImage,
        assetID: String,
        variantIndex: Int
    ) throws -> URL {
        let dir = assetsURL
        try makeDirectory(dir)
        let url = dir.appendingPathComponent("\(sanitize(assetID))_v\(variantIndex).png")
        try writePNG(image, to: url)
        return url
    }

    /// Save a Look example image.
    @discardableResult
    func saveLookExample(
        _ image: NSImage,
        lookName: String
    ) throws -> URL {
        let dir = examplesURL
        try makeDirectory(dir)
        let url = dir.appendingPathComponent("\(sanitize(lookName)).png")
        try writePNG(image, to: url)
        return url
    }

    /// Save a storyboard panel image.
    @discardableResult
    func savePanelImage(
        _ image: NSImage,
        panelID: String,
        episodeName: String
    ) throws -> URL {
        let dir = panelsURL(episodeName: episodeName)
        try makeDirectory(dir)
        let url = dir.appendingPathComponent("\(sanitize(panelID)).png")
        try writePNG(image, to: url)
        return url
    }

    // MARK: - Load helpers

    func loadVariantImage(assetID: String, variantIndex: Int) -> NSImage? {
        let url = assetsURL.appendingPathComponent("\(sanitize(assetID))_v\(variantIndex).png")
        return NSImage(contentsOf: url)
    }

    func loadLookExample(lookName: String) -> NSImage? {
        let url = examplesURL.appendingPathComponent("\(sanitize(lookName)).png")
        return NSImage(contentsOf: url)
    }

    func loadPanelImage(panelID: String, episodeName: String) -> NSImage? {
        let url = panelsURL(episodeName: episodeName)
            .appendingPathComponent("\(sanitize(panelID)).png")
        return NSImage(contentsOf: url)
    }

    // MARK: - Private helpers

    private func makeDirectory(_ url: URL) throws {
        do {
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            throw StorageError.couldNotCreateDirectory(url)
        }
    }

    private func writePNG(_ image: NSImage, to url: URL) throws {
        guard
            let tiff = image.tiffRepresentation,
            let bmp  = NSBitmapImageRep(data: tiff),
            let png  = bmp.representation(using: .png, properties: [:])
        else {
            throw StorageError.couldNotSaveImage(url)
        }
        do {
            try png.write(to: url)
        } catch {
            throw StorageError.couldNotSaveImage(url)
        }
    }

    /// Replaces characters that are unsafe in file/folder names.
    private func sanitize(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "|", with: "-")
    }
}
