import SwiftUI

struct LensTrayView: View {
    @Bindable var viewModel: AppViewModel
    @State private var showingLensEditor = false
    @State private var editingLens: Lens?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("LENSES")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    editingLens = nil
                    showingLensEditor = true
                } label: {
                    Label("Add Lens", systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // Lens cards
            if viewModel.lenses.isEmpty {
                HStack {
                    Spacer()
                    Text("No lenses in inventory. Click + to add.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Spacer()
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.lenses) { lens in
                            LensCardView(lens: lens, imageStorage: viewModel.imageStorage)
                                .contextMenu {
                                    Button("Edit") {
                                        editingLens = lens
                                        showingLensEditor = true
                                    }
                                    Button("Duplicate") {
                                        viewModel.duplicateLens(lens.id)
                                    }
                                    Divider()
                                    Button("Delete", role: .destructive) {
                                        viewModel.deleteLens(lens.id)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
            }
        }
        .background(.background)
        .sheet(isPresented: $showingLensEditor) {
            LensEditorSheet(viewModel: viewModel, editingLens: editingLens)
        }
    }
}
