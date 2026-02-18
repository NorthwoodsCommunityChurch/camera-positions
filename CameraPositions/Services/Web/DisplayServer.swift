import Foundation
import Network
import OSLog

private let logger = Logger(subsystem: "com.northwoods.CameraPositions", category: "DisplayServer")

@Observable
final class DisplayServer {
    private(set) var isRunning = false
    private(set) var port: UInt16 = 8080
    private(set) var connectionCount = 0

    private var listener: NWListener?
    private var connections: Set<ObjectIdentifier> = []
    private var connectionMap: [ObjectIdentifier: NWConnection] = [:]
    private let connectionQueue = DispatchQueue(label: "com.northwoods.CameraPositions.connections")

    let persistence: PersistenceService
    let imageStorage: ImageStorage

    init(persistence: PersistenceService, imageStorage: ImageStorage) {
        self.persistence = persistence
        self.imageStorage = imageStorage
    }

    func start(port: UInt16 = 8080) {
        guard !isRunning else { return }
        self.port = port

        do {
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true

            guard let nwPort = NWEndpoint.Port(rawValue: port) else {
                logger.error("Invalid port: \(port)")
                return
            }

            listener = try NWListener(using: params, on: nwPort)

            listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    logger.info("DisplayServer listening on port \(port)")
                    DispatchQueue.main.async { self?.isRunning = true }
                case .failed(let error):
                    logger.error("DisplayServer failed: \(error.localizedDescription)")
                    DispatchQueue.main.async { self?.isRunning = false }
                case .cancelled:
                    DispatchQueue.main.async { self?.isRunning = false }
                default:
                    break
                }
            }

            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }

            listener?.start(queue: .global(qos: .userInitiated))
        } catch {
            logger.error("Failed to start DisplayServer: \(error.localizedDescription)")
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil

        connectionQueue.sync {
            for (_, conn) in connectionMap {
                conn.cancel()
            }
            connectionMap.removeAll()
            connections.removeAll()
        }

        DispatchQueue.main.async {
            self.isRunning = false
            self.connectionCount = 0
        }

        logger.info("DisplayServer stopped")
    }

    /// Get the local network URL for the display
    var displayURL: String? {
        guard isRunning else { return nil }
        if let ip = getLocalIPAddress() {
            return "http://\(ip):\(port)"
        }
        return "http://localhost:\(port)"
    }

    private func handleNewConnection(_ nwConnection: NWConnection) {
        let id = ObjectIdentifier(nwConnection)

        connectionQueue.sync {
            connections.insert(id)
            connectionMap[id] = nwConnection
        }

        DispatchQueue.main.async {
            self.connectionCount = self.connections.count
        }

        nwConnection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.receiveData(from: nwConnection, id: id)
            case .failed, .cancelled:
                self?.removeConnection(id)
            default:
                break
            }
        }

        nwConnection.start(queue: .global(qos: .userInitiated))
    }

    private func receiveData(from connection: NWConnection, id: ObjectIdentifier) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                if let request = HTTPRequest.parse(from: data) {
                    self?.handleRequest(request, connection: connection)
                }
            }

            if isComplete || error != nil {
                self?.removeConnection(id)
            }
        }
    }

    private func handleRequest(_ request: HTTPRequest, connection: NWConnection) {
        logger.info("\(request.method) \(request.path)")

        let response: HTTPResponse

        switch (request.method, request.path) {
        case ("GET", "/"), ("GET", "/index.html"):
            response = serveStaticFile("index.html", contentType: "text/html")

        case ("GET", "/styles.css"):
            response = serveStaticFile("styles.css", contentType: "text/css")

        case ("GET", "/display.js"):
            response = serveStaticFile("display.js", contentType: "application/javascript")

        case ("GET", "/api/config"):
            response = serveConfig()

        case let ("GET", path) where path.hasPrefix("/api/images/"):
            let filename = String(path.dropFirst("/api/images/".count))
            response = serveImage(filename: filename)

        default:
            response = .notFound()
        }

        connection.send(content: response.toData(), completion: .contentProcessed { error in
            if let error = error {
                logger.error("Send error: \(error.localizedDescription)")
            }
            connection.cancel()
        })
    }

    private func serveStaticFile(_ filename: String, contentType: String) -> HTTPResponse {
        let url = Bundle.main.url(forResource: filename, withExtension: nil, subdirectory: "Web")
            ?? Bundle.main.url(forResource: filename, withExtension: nil)

        guard let url else {
            logger.warning("Static file not found: \(filename)")
            return .notFound()
        }

        do {
            let data = try Data(contentsOf: url)
            return .ok(data: data, contentType: contentType)
        } catch {
            logger.error("Failed to read \(filename): \(error.localizedDescription)")
            return .notFound()
        }
    }

    private func serveConfig() -> HTTPResponse {
        if let display = persistence.loadPublishedDisplay() {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(display) {
                return .ok(data: data, contentType: "application/json")
            }
        }

        // No published config yet
        return .ok(body: "{}", contentType: "application/json")
    }

    private func serveImage(filename: String) -> HTTPResponse {
        // Sanitize filename to prevent directory traversal
        let sanitized = filename.components(separatedBy: "/").last ?? filename
        guard !sanitized.isEmpty, !sanitized.starts(with: ".") else {
            return .notFound()
        }

        if let data = imageStorage.loadImage(filename: sanitized) {
            let contentType = sanitized.hasSuffix(".png") ? "image/png" : "image/jpeg"
            return .ok(data: data, contentType: contentType)
        }
        return .notFound()
    }

    private func removeConnection(_ id: ObjectIdentifier) {
        connectionQueue.async { [self] in
            connections.remove(id)
            connectionMap[id]?.cancel()
            connectionMap.removeValue(forKey: id)
            let count = connections.count
            DispatchQueue.main.async {
                self.connectionCount = count
            }
        }
    }

    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        return address
    }
}
