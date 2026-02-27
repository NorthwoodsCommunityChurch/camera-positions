import Foundation
import OSLog

private let logger = Logger(subsystem: "com.northwoods.CameraPositions", category: "ESP32Display")

/// Maps one camera position number to an ESP32 IP address.
/// One record per physical ESP32 device.
struct ESP32Connection: Codable, Identifiable {
    let id: UUID
    var cameraNumber: Int    // matches CameraPosition.number
    var ipAddress: String    // e.g. "10.10.11.50"

    init(id: UUID = UUID(), cameraNumber: Int, ipAddress: String) {
        self.id = id
        self.cameraNumber = cameraNumber
        self.ipAddress = ipAddress
    }
}

/// Manages the list of ESP32 devices and pushes camera assignment data to their
/// OLED displays via POST /api/display whenever assignments change.
@Observable
final class ESP32DisplayService {
    var connections: [ESP32Connection] = []

    private let defaultsKey = "esp32_connections"

    init() {
        load()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let loaded = try? JSONDecoder().decode([ESP32Connection].self, from: data)
        else { return }
        connections = loaded
    }

    func save() {
        if let data = try? JSONEncoder().encode(connections) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    // MARK: - CRUD

    func addConnection(_ connection: ESP32Connection) {
        connections.append(connection)
        save()
    }

    func removeConnection(id: UUID) {
        connections.removeAll { $0.id == id }
        save()
    }

    func updateConnection(_ connection: ESP32Connection) {
        guard let index = connections.firstIndex(where: { $0.id == connection.id }) else { return }
        connections[index] = connection
        save()
    }

    // MARK: - Push

    /// Posts each camera's operator + first lens to the matching ESP32.
    /// Called every time assignments auto-publish. Fires-and-forgets — failures are logged only.
    func push(display: PublishedDisplay) {
        guard !connections.isEmpty else { return }

        for connection in connections {
            guard let camera = display.cameras.first(where: { $0.number == connection.cameraNumber }) else {
                continue
            }
            let operatorName = camera.operatorName ?? ""
            let firstLens = camera.lenses.first?.name ?? ""
            let ip = connection.ipAddress

            Task {
                await sendToESP32(ip: ip, operatorName: operatorName, lens: firstLens)
            }
        }
    }

    private func sendToESP32(ip: String, operatorName: String, lens: String) async {
        guard let url = URL(string: "http://\(ip)/api/display") else {
            logger.warning("Invalid ESP32 IP: \(ip)")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 3.0

        let body: [String: String] = ["operator": operatorName, "lens": lens]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else { return }
        request.httpBody = data

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                logger.info("ESP32 \(ip) cam \(0) updated: op=\"\(operatorName)\" lens=\"\(lens)\"")
            } else {
                logger.warning("ESP32 at \(ip) returned unexpected response")
            }
        } catch {
            logger.warning("Could not reach ESP32 at \(ip): \(error.localizedDescription)")
        }
    }
}
