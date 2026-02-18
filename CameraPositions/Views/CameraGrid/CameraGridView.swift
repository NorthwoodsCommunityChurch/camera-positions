import SwiftUI

struct CameraGridView: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header with add button
            HStack {
                Text("Camera Positions")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    viewModel.addCameraPosition()
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
                .font(.title3)
                .help("Add camera position")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Camera columns
            if viewModel.cameraPositions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "camera")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No camera positions")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Click + to add camera positions")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(viewModel.cameraPositions) { position in
                            CameraColumnView(
                                position: position,
                                assignment: viewModel.workingAssignments.first { $0.cameraPositionId == position.id },
                                viewModel: viewModel
                            )
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
}
