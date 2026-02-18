import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            HSplitView {
                // Left sidebar: weekends + team members
                SidebarView(viewModel: viewModel)
                    .frame(minWidth: 200, idealWidth: 240, maxWidth: 300)

                // Center: camera columns
                CameraGridView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            // Bottom: lens tray
            LensTrayView(viewModel: viewModel)
                .frame(height: 120)
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // Server status
                if let url = viewModel.displayServer.displayURL {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text(url)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}
