import SwiftUI
import AppKit

struct TeamMemberTileView: View {
    let member: TeamMember
    let viewModel: AppViewModel
    @State private var showingPhotoPicker = false

    private var isAssigned: Bool {
        viewModel.workingAssignments.contains { $0.operatorName == member.name }
    }

    var body: some View {
        HStack(spacing: 8) {
            // Person photo or placeholder icon
            if let filename = member.photoFilename,
               let imageData = viewModel.imageStorage.loadImage(filename: filename),
               let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                    .foregroundStyle(isAssigned ? Color.secondary : Color.accentColor)
            }

            Text(member.name)
                .font(.subheadline)
                .foregroundStyle(isAssigned ? .secondary : .primary)

            Spacer()

            if isAssigned {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isAssigned ? Color.clear : Color.accentColor.opacity(0.08))
        )
        .contextMenu {
            Button {
                showingPhotoPicker = true
            } label: {
                Label(member.photoFilename != nil ? "Change Photo" : "Add Photo", systemImage: "photo")
            }

            if member.photoFilename != nil {
                Button(role: .destructive) {
                    viewModel.removePersonPhoto(name: member.name)
                } label: {
                    Label("Remove Photo", systemImage: "trash")
                }
            }
        }
        .draggable(member.name) {
            HStack(spacing: 6) {
                if let filename = member.photoFilename,
                   let imageData = viewModel.imageStorage.loadImage(filename: filename),
                   let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
                Text(member.name)
                    .fontWeight(.medium)
            }
            .padding(8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .opacity(isAssigned ? 0.6 : 1.0)
        .fileImporter(
            isPresented: $showingPhotoPicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url) {
                        viewModel.setPersonPhoto(name: member.name, imageData: data)
                    }
                }
            }
        }
    }
}
