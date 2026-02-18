import Foundation

/// The full data structure served to the web display.
/// Includes resolved lens names and camera labels so the web page
/// doesn't need to make multiple API calls.
struct PublishedDisplay: Codable {
    let serviceName: String
    let serviceDate: Date
    let cameras: [DisplayCamera]

    struct DisplayCamera: Codable {
        let number: Int
        let label: String?
        let anglePhotoFilename: String?
        let operatorName: String?
        let operatorPhotoFilename: String?
        let lenses: [DisplayLens]
    }

    struct DisplayLens: Codable {
        let name: String
        let photoFilename: String?
    }
}
