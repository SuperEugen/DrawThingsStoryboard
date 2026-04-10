import AppKit
import Foundation

// MARK: - StorageService
/// #69: Added deleteImage method

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

    var rootURL: URL {
        FileManager.default
            .urls(for: .picturesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DrawThings-Storyboard")
    }

    // MARK: - JSON file URLs

    var configURL: URL        { rootURL.appendingPathComponent("config.json") }
    var modelsURL: URL        { rootURL.appendingPathComponent("models.json") }
    var stylesURL: URL        { rootURL.appendingPathComponent("styles.json") }
    var storyboardsURL: URL   { rootURL.appendingPathComponent("storyboards.json") }
    var assetsURL: URL        { rootURL.appendingPathComponent("assets.json") }
    var productionLogURL: URL { rootURL.appendingPathComponent("production-log.json") }

    // MARK: - Image URLs

    func imageURL(for imageID: String) -> URL {
        rootURL.appendingPathComponent("\(imageID).png")
    }

    // MARK: - Save image

    @discardableResult
    func saveImage(_ image: NSImage) throws -> String {
        let id = UUID().uuidString
        let url = imageURL(for: id)
        try ensureRootExists()
        try writePNG(image, to: url)
        return id
    }

    // MARK: - Load image

    func loadImage(id: String) -> NSImage? {
        guard !id.isEmpty else { return nil }
        return NSImage(contentsOf: imageURL(for: id))
    }

    // MARK: - Delete image (#69)

    func deleteImage(id: String) {
        guard !id.isEmpty else { return }
        let url = imageURL(for: id)
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - JSON read/write helpers

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private let decoder = JSONDecoder()

    func read<T: Decodable>(_ url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    func write<T: Encodable>(_ value: T, to url: URL) {
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }

    // MARK: - Private helpers

    func ensureRootExists() throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: rootURL.path) {
            do {
                try fm.createDirectory(at: rootURL, withIntermediateDirectories: true)
            } catch {
                throw StorageError.couldNotCreateDirectory(rootURL)
            }
        }
    }

    private func writePNG(_ image: NSImage, to url: URL) throws {
        guard
            let tiff = image.tiffRepresentation,
            let bmp  = NSBitmapImageRep(data: tiff),
            let png  = bmp.representation(using: .png, properties: [:])
        else { throw StorageError.couldNotSaveImage(url) }
        do {
            try png.write(to: url)
        } catch {
            throw StorageError.couldNotSaveImage(url)
        }
    }
}
