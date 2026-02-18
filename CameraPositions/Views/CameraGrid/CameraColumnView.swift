import SwiftUI
import UniformTypeIdentifiers

struct CameraColumnView: View {
    let position: CameraPosition
    let assignment: CameraAssignment?
    @Bindable var viewModel: AppViewModel

    @State private var labelText: String = ""
    @State private var isDropTargeted = false
    @State private var showingPhotoImporter = false

    var body: some View {
        VStack(spacing: 0) {
            // Angle photo
            anglePhotoSection
                .frame(height: 140)
                .clipped()

            Divider()

            // Camera number + label
            VStack(spacing: 4) {
                Text("CAM \(position.number)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)

                TextField("Label", text: $labelText)
                    .textFieldStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .onSubmit {
                        viewModel.updateCameraPositionLabel(position.id, label: labelText.isEmpty ? nil : labelText)
                    }
            }
            .padding(.vertical, 8)

            Divider()

            // Operator display
            operatorSection
                .padding(8)

            Divider()

            // Lens display
            lensSection
                .padding(8)

            Spacer(minLength: 0)

            // Remove button
            Button(role: .destructive) {
                viewModel.removeCameraPosition(position.id)
            } label: {
                Image(systemName: "minus.circle")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)
        }
        .frame(width: 180)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isDropTargeted ? Color.accentColor : Color(nsColor: .separatorColor),
                    lineWidth: isDropTargeted ? 2 : 1
                )
        )
        .dropDestination(for: String.self) { items, _ in
            guard let value = items.first else { return false }
            if let lensId = UUID(uuidString: value) {
                // It's a lens UUID
                viewModel.assignLens(to: position.id, lensId: lensId)
            } else {
                // It's an operator name
                viewModel.assignOperator(to: position.id, name: value)
            }
            return true
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
        .onAppear {
            labelText = position.label ?? ""
        }
        .fileImporter(isPresented: $showingPhotoImporter, allowedContentTypes: [.image]) { result in
            if case .success(let url) = result {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url) {
                        viewModel.setCameraAnglePhoto(position.id, imageData: data)
                    }
                }
            }
        }
    }

    // MARK: - Angle Photo

    @ViewBuilder
    private var anglePhotoSection: some View {
        if let filename = position.anglePhotoFilename,
           let data = viewModel.imageStorage.loadImage(filename: filename),
           let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .onTapGesture { showingPhotoImporter = true }
        } else {
            VStack(spacing: 6) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Set Photo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .controlColor))
            .onTapGesture { showingPhotoImporter = true }
        }
    }

    // MARK: - Operator Section

    private var operatorSection: some View {
        VStack(spacing: 4) {
            if let name = assignment?.operatorName {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(Color.accentColor)
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Button {
                        viewModel.removeOperator(from: position.id)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "person.badge.plus")
                        .foregroundStyle(.secondary)
                    Text("Drop Name")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            Color(nsColor: .separatorColor),
                            style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                        )
                )
            }
        }
    }

    // MARK: - Lens Section

    private var lensSection: some View {
        VStack(spacing: 4) {
            if let lensIds = assignment?.lensIds, !lensIds.isEmpty {
                ForEach(lensIds, id: \.self) { lensId in
                    if let lens = viewModel.lenses.first(where: { $0.id == lensId }) {
                        HStack(spacing: 6) {
                            if let photoFilename = lens.photoFilename,
                               let data = viewModel.imageStorage.loadImage(filename: photoFilename),
                               let nsImage = NSImage(data: data) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 24, height: 24)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }

                            Text(lens.name)
                                .font(.caption)
                                .lineLimit(1)

                            Spacer()

                            Button {
                                viewModel.removeLens(from: position.id, lensId: lensId)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(4)
                        .background(Color(nsColor: .controlColor), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "plus.circle.dashed")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text("Drop Lens")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            Color(nsColor: .separatorColor),
                            style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                        )
                )
            }
        }
    }
}
