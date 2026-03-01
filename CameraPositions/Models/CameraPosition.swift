import Foundation

struct CameraPosition: Codable, Identifiable {
    let id: UUID
    var number: Int
    var label: String?
    var anglePhotoFilename: String?
    var isDisabled: Bool

    init(id: UUID = UUID(), number: Int, label: String? = nil, anglePhotoFilename: String? = nil, isDisabled: Bool = false) {
        self.id = id
        self.number = number
        self.label = label
        self.anglePhotoFilename = anglePhotoFilename
        self.isDisabled = isDisabled
    }
}
