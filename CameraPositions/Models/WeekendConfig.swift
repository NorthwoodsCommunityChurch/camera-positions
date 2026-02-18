import Foundation

struct WeekendConfig: Codable, Identifiable {
    let id: UUID
    var pcoServicePlanId: String?
    var serviceDate: Date
    var serviceName: String
    var assignments: [CameraAssignment]

    init(
        id: UUID = UUID(),
        pcoServicePlanId: String? = nil,
        serviceDate: Date,
        serviceName: String,
        assignments: [CameraAssignment] = []
    ) {
        self.id = id
        self.pcoServicePlanId = pcoServicePlanId
        self.serviceDate = serviceDate
        self.serviceName = serviceName
        self.assignments = assignments
    }
}
