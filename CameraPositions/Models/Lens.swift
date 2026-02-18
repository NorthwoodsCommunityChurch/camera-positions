import Foundation

struct Lens: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var photoFilename: String?

    init(id: UUID = UUID(), name: String, photoFilename: String? = nil) {
        self.id = id
        self.name = name
        self.photoFilename = photoFilename
    }
}
