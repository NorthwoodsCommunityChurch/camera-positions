import Foundation
import OSLog

private let logger = Logger(subsystem: "com.northwoods.CameraPositions", category: "Persistence")

@Observable
final class PersistenceService {
    private let supportDir: URL
    private let weekendsDir: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        supportDir = appSupport.appendingPathComponent("CameraPositions", isDirectory: true)
        weekendsDir = supportDir.appendingPathComponent("weekends", isDirectory: true)

        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        createDirectories()
    }

    private func createDirectories() {
        let fm = FileManager.default
        for dir in [supportDir, weekendsDir] {
            if !fm.fileExists(atPath: dir.path) {
                do {
                    try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                    logger.info("Created directory: \(dir.path)")
                } catch {
                    logger.error("Failed to create directory \(dir.path): \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Camera Positions

    func loadCameraPositions() -> [CameraPosition] {
        load(from: supportDir.appendingPathComponent("cameras.json")) ?? []
    }

    func saveCameraPositions(_ positions: [CameraPosition]) {
        save(positions, to: supportDir.appendingPathComponent("cameras.json"))
    }

    // MARK: - Lenses

    func loadLenses() -> [Lens] {
        load(from: supportDir.appendingPathComponent("lenses.json")) ?? []
    }

    func saveLenses(_ lenses: [Lens]) {
        save(lenses, to: supportDir.appendingPathComponent("lenses.json"))
    }

    // MARK: - Weekend Configs

    func loadWeekendConfig(id: UUID) -> WeekendConfig? {
        load(from: weekendsDir.appendingPathComponent("\(id.uuidString).json"))
    }

    func saveWeekendConfig(_ config: WeekendConfig) {
        save(config, to: weekendsDir.appendingPathComponent("\(config.id.uuidString).json"))
    }

    func loadAllWeekendConfigs() -> [WeekendConfig] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: weekendsDir, includingPropertiesForKeys: nil) else {
            return []
        }
        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> WeekendConfig? in
                load(from: url)
            }
            .sorted { $0.serviceDate < $1.serviceDate }
    }

    // MARK: - Published Config (what the web display shows)

    func loadPublishedConfig() -> WeekendConfig? {
        load(from: supportDir.appendingPathComponent("published.json"))
    }

    func savePublishedConfig(_ config: WeekendConfig) {
        save(config, to: supportDir.appendingPathComponent("published.json"))
    }

    // MARK: - Published data for web display (includes lens details)

    func loadPublishedDisplay() -> PublishedDisplay? {
        load(from: supportDir.appendingPathComponent("published-display.json"))
    }

    func savePublishedDisplay(_ display: PublishedDisplay) {
        save(display, to: supportDir.appendingPathComponent("published-display.json"))
    }

    // MARK: - Person Photos (maps person name → photo filename)

    func loadPersonPhotos() -> [String: String] {
        load(from: supportDir.appendingPathComponent("person-photos.json")) ?? [:]
    }

    func savePersonPhotos(_ photos: [String: String]) {
        save(photos, to: supportDir.appendingPathComponent("person-photos.json"))
    }

    // MARK: - Generic Helpers

    private func load<T: Decodable>(from url: URL) -> T? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.error("Failed to load \(url.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
    }

    private func save<T: Encodable>(_ value: T, to url: URL) {
        do {
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
            logger.info("Saved \(url.lastPathComponent)")
        } catch {
            logger.error("Failed to save \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }
}
