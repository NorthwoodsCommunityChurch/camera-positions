import Foundation
import OSLog

private let logger = Logger(subsystem: "com.northwoods.CameraPositions", category: "PCOAuth")

@Observable
final class PCOAuthService {
    private(set) var isAuthenticated = false
    private var credentials: PCOCredentials?

    init() {
        if let saved = PCOTokenStore.loadCredentials() {
            self.credentials = saved
            self.isAuthenticated = true
            logger.info("Loaded existing PCO credentials")
        }
    }

    /// Get the Basic auth header for API requests
    func getAuthHeader() throws -> String {
        guard let credentials = credentials else {
            throw PCOError.notAuthenticated
        }
        return credentials.basicAuthHeader
    }

    /// Save credentials and mark as authenticated
    func connect(appId: String, secret: String) {
        let creds = PCOCredentials(appId: appId, secret: secret)
        self.credentials = creds
        PCOTokenStore.saveCredentials(creds)
        self.isAuthenticated = true
        logger.info("PCO credentials saved")
    }

    /// Clear credentials and disconnect
    func logout() {
        credentials = nil
        isAuthenticated = false
        PCOTokenStore.clearCredentials()
        logger.info("PCO disconnected")
    }
}

enum PCOError: LocalizedError {
    case notAuthenticated
    case apiError(String)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not connected to Planning Center."
        case .apiError(let msg): return msg
        case .unknownError: return "An unknown error occurred."
        }
    }
}
