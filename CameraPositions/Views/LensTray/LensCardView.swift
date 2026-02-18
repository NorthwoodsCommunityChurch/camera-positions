import SwiftUI

struct LensCardView: View {
    let lens: Lens
    let imageStorage: ImageStorage

    var body: some View {
        VStack(spacing: 4) {
            if let filename = lens.photoFilename,
               let data = imageStorage.loadImage(filename: filename),
               let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "camera.aperture")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, height: 40)
            }

            Text(lens.name)
                .font(.caption2)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 70)
        }
        .padding(6)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
        .draggable(lens.id.uuidString) {
            HStack(spacing: 6) {
                Image(systemName: "camera.aperture")
                    .foregroundStyle(Color.accentColor)
                Text(lens.name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}
