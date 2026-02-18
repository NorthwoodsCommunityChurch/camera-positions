import Foundation
import OSLog

private let logger = Logger(subsystem: "com.northwoods.CameraPositions", category: "PCOAPI")

final class PCOAPIClient {
    private let authService: PCOAuthService

    init(authService: PCOAuthService) {
        self.authService = authService
    }

    // MARK: - Service Types

    struct ServiceType: Identifiable {
        let id: String
        let name: String
    }

    func fetchServiceTypes() async throws -> [ServiceType] {
        let json = try await get("/service_types")
        guard let data = json["data"] as? [[String: Any]] else { return [] }

        return data.compactMap { item in
            guard let id = item["id"] as? String,
                  let attrs = item["attributes"] as? [String: Any],
                  let name = attrs["name"] as? String else { return nil }
            return ServiceType(id: id, name: name)
        }
    }

    // MARK: - Plans (Weekends)

    struct ServicePlan: Identifiable {
        let id: String
        let serviceTypeId: String
        let title: String?
        let dates: String
        let sortDate: Date
    }

    func fetchUpcomingPlans(serviceTypeId: String, count: Int = 8) async throws -> [ServicePlan] {
        let json = try await get("/service_types/\(serviceTypeId)/plans?filter=future&per_page=\(count)&order=sort_date")
        guard let data = json["data"] as? [[String: Any]] else { return [] }

        let isoWithFrac = ISO8601DateFormatter()
        isoWithFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoPlain = ISO8601DateFormatter()
        isoPlain.formatOptions = [.withInternetDateTime]

        // Fallback: parse the human-readable "dates" field (e.g., "February 22, 2026")
        let humanDateFormatter = DateFormatter()
        humanDateFormatter.locale = Locale(identifier: "en_US")
        humanDateFormatter.dateFormat = "MMMM d, yyyy"

        return data.compactMap { item in
            guard let id = item["id"] as? String,
                  let attrs = item["attributes"] as? [String: Any],
                  let dates = attrs["dates"] as? String else { return nil }

            let title = attrs["title"] as? String
            let sortDateStr = attrs["sort_date"] as? String ?? ""

            logger.info("PCO plan \(id): sort_date='\(sortDateStr)', dates='\(dates)'")

            let sortDate = isoWithFrac.date(from: sortDateStr)
                ?? isoPlain.date(from: sortDateStr)
                ?? humanDateFormatter.date(from: dates)
                ?? Date()

            return ServicePlan(id: id, serviceTypeId: serviceTypeId, title: title, dates: dates, sortDate: sortDate)
        }
    }

    // MARK: - Team Members

    struct PlanTeamMember: Identifiable {
        let id: String
        let personName: String
        let teamId: String?
        let teamPositionName: String
        let status: String  // "C" confirmed, "U" unconfirmed, "D" declined
        let photoThumbnailURL: String?
    }

    func fetchTeamMembers(serviceTypeId: String, planId: String) async throws -> [PlanTeamMember] {
        let json = try await get("/service_types/\(serviceTypeId)/plans/\(planId)/team_members?per_page=100")
        guard let data = json["data"] as? [[String: Any]] else { return [] }

        return data.compactMap { item in
            guard let id = item["id"] as? String,
                  let attrs = item["attributes"] as? [String: Any],
                  let name = attrs["name"] as? String else { return nil }

            let teamPositionName = attrs["team_position_name"] as? String ?? ""
            let status = attrs["status"] as? String ?? "U"
            let photoURL = attrs["photo_thumbnail"] as? String

            // Get team ID from relationships
            let teamId: String?
            if let relationships = item["relationships"] as? [String: Any],
               let team = relationships["team"] as? [String: Any],
               let teamData = team["data"] as? [String: Any],
               let tid = teamData["id"] as? String {
                teamId = tid
            } else {
                teamId = nil
            }

            return PlanTeamMember(
                id: id,
                personName: name,
                teamId: teamId,
                teamPositionName: teamPositionName,
                status: status,
                photoThumbnailURL: photoURL
            )
        }
    }

    // MARK: - Teams

    struct Team: Identifiable {
        let id: String
        let name: String
    }

    func fetchTeams(serviceTypeId: String) async throws -> [Team] {
        let json = try await get("/service_types/\(serviceTypeId)/teams")
        guard let data = json["data"] as? [[String: Any]] else { return [] }

        return data.compactMap { item in
            guard let id = item["id"] as? String,
                  let attrs = item["attributes"] as? [String: Any],
                  let name = attrs["name"] as? String else { return nil }
            return Team(id: id, name: name)
        }
    }

    // MARK: - HTTP (Basic Auth)

    private func get(_ path: String) async throws -> [String: Any] {
        let authHeader = try authService.getAuthHeader()
        let url = URL(string: "\(PCOConfig.apiBaseURL)\(path)")!

        var request = URLRequest(url: url)
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PCOError.unknownError
        }

        if httpResponse.statusCode == 401 {
            throw PCOError.apiError("Invalid credentials. Check your App ID and Secret.")
        }

        guard httpResponse.statusCode == 200 else {
            throw PCOError.apiError("API returned status \(httpResponse.statusCode)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PCOError.apiError("Invalid JSON response")
        }

        return json
    }
}
