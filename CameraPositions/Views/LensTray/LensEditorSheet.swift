import SwiftUI

struct LensEditorSheet: View {
    @Bindable var viewModel: AppViewModel
    let editingLens: Lens?
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedImageData: Data?
    @State private var showingImagePicker = false

    private var isEditing: Bool { editingLens != nil }

    var body: some View {
        VStack(spacing: 16) {
            Text(isEditing ? "Edit Lens" : "Add Lens")
                .font(.headline)

            TextField("Lens name (e.g. 70-200mm f/2.8)", text: $name)
                .textFieldStyle(.roundedBorder)

            HStack {
                if let data = selectedImageData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else if let lens = editingLens,
                          let filename = lens.photoFilename,
                          let data = viewModel.imageStorage.loadImage(filename: filename),
                          let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlColor))
                        .frame(width: 80, height: 60)
                        .overlay {
                            Image(systemName: "camera.aperture")
                                .foregroundStyle(.secondary)
                        }
                }

                Button("Choose Photo...") {
                    showingImagePicker = true
                }
            }

            Spacer()

            HStack {
                if isEditing {
                    Button("Delete", role: .destructive) {
                        if let lens = editingLens {
                            viewModel.deleteLens(lens.id)
                        }
                        dismiss()
                    }
                }

                Spacer()

                Button("Cancel") {
                    dismiss()
                }

                Button(isEditing ? "Update" : "Add") {
                    let trimmedName = name.trimmingCharacters(in: .whitespaces)
                    guard !trimmedName.isEmpty else { return }

                    if let lens = editingLens {
                        viewModel.updateLens(lens.id, name: trimmedName, imageData: selectedImageData)
                    } else {
                        _ = viewModel.addLens(name: trimmedName, imageData: selectedImageData)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 350, height: 250)
        .onAppear {
            if let lens = editingLens {
                name = lens.name
            }
        }
        .fileImporter(isPresented: $showingImagePicker, allowedContentTypes: [.image]) { result in
            if case .success(let url) = result {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    selectedImageData = try? Data(contentsOf: url)
                }
            }
        }
    }
}
