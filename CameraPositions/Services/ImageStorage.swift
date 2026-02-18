import Foundation
import AppKit
import OSLog

private let logger = Logger(subsystem: "com.northwoods.CameraPositions", category: "ImageStorage")

final class ImageStorage {
    private let imagesDir: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        imagesDir = appSupport
            .appendingPathComponent("CameraPositions", isDirectory: true)
            .appendingPathComponent("images", isDirectory: true)

        createDirectory()
    }

    private func createDirectory() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: imagesDir.path) {
            do {
                try fm.createDirectory(at: imagesDir, withIntermediateDirectories: true)
                logger.info("Created images directory")
            } catch {
                logger.error("Failed to create images directory: \(error.localizedDescription)")
            }
        }
    }

    /// Save image data and return the filename
    func saveImage(_ data: Data, filename: String? = nil) -> String? {
        let name = filename ?? "\(UUID().uuidString).png"
        let url = imagesDir.appendingPathComponent(name)
        do {
            // Resize to max 1024px wide to keep storage reasonable
            if let resized = resizeImageData(data, maxWidth: 1024) {
                try resized.write(to: url, options: .atomic)
            } else {
                try data.write(to: url, options: .atomic)
            }
            logger.info("Saved image: \(name)")
            return name
        } catch {
            logger.error("Failed to save image: \(error.localizedDescription)")
            return nil
        }
    }

    /// Load image data by filename
    func loadImage(filename: String) -> Data? {
        let url = imagesDir.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? Data(contentsOf: url)
    }

    /// Get the file URL for an image (used by the web server)
    func imageURL(filename: String) -> URL {
        imagesDir.appendingPathComponent(filename)
    }

    /// Delete an image
    func deleteImage(filename: String) {
        let url = imagesDir.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
        logger.info("Deleted image: \(filename)")
    }

    /// Resize image data to a maximum width, preserving aspect ratio
    private func resizeImageData(_ data: Data, maxWidth: CGFloat) -> Data? {
        guard let image = NSImage(data: data) else { return nil }
        let size = image.size
        guard size.width > maxWidth else { return nil }

        let scale = maxWidth / size.width
        let newSize = NSSize(width: maxWidth, height: size.height * scale)

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: size),
                   operation: .copy,
                   fraction: 1.0)
        newImage.unlockFocus()

        guard let tiff = newImage.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return nil }

        return png
    }
}
