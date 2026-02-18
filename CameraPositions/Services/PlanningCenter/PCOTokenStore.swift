import Foundation
import Security
import OSLog

private let logger = Logger(subsystem: "com.northwoods.CameraPositions", category: "PCOTokenStore")

struct PCOCredentials: Codable {
    let appId: String
    let secret: String

    /// HTTP Basic auth header value: Base64("appId:secret")
    var basicAuthHeader: String {
        let combined = "\(appId):\(secret)"
        return "Basic \(Data(combined.utf8).base64EncodedString())"
    }
}

final class PCOTokenStore {
    private static let serviceName = "com.northwoods.CameraPositions.pco"
    private static let accountName = "pat_credentials"

    static func saveCredentials(_ credentials: PCOCredentials) {
        guard let data = try? JSONEncoder().encode(credentials) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]

        // Delete any existing item first
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status == errSecSuccess {
            logger.info("Saved PCO credentials to Keychain")
        } else {
            logger.error("Failed to save PCO credentials: \(status)")
        }
    }

    static func loadCredentials() -> PCOCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let credentials = try? JSONDecoder().decode(PCOCredentials.self, from: data) else {
            return nil
        }

        return credentials
    }

    static func clearCredentials() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]
        SecItemDelete(query as CFDictionary)
        logger.info("Cleared PCO credentials from Keychain")
    }
}
