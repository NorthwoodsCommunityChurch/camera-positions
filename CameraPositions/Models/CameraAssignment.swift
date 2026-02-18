import Foundation

struct CameraAssignment: Codable, Identifiable {
    let id: UUID
    var cameraPositionId: UUID
    var operatorName: String?
    var operatorPcoId: String?
    var operatorPhotoURL: String?
    var lensIds: [UUID]

    init(
        id: UUID = UUID(),
        cameraPositionId: UUID,
        operatorName: String? = nil,
        operatorPcoId: String? = nil,
        operatorPhotoURL: String? = nil,
        lensIds: [UUID] = []
    ) {
        self.id = id
        self.cameraPositionId = cameraPositionId
        self.operatorName = operatorName
        self.operatorPcoId = operatorPcoId
        self.operatorPhotoURL = operatorPhotoURL
        self.lensIds = lensIds
    }
}
