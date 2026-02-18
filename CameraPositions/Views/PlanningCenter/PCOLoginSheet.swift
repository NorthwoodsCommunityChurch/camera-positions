import SwiftUI

struct PCOLoginSheet: View {
    @Bindable var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var appId = ""
    @State private var secret = ""
    @State private var isConnecting = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with branding
            header
                .padding(.bottom, 20)

            Divider()

            // Content area
            if viewModel.pcoAuth.isAuthenticated {
                connectedView
            } else {
                credentialsView
            }

            Spacer()

            Divider()

            // Footer
            HStack {
                if viewModel.pcoAuth.isAuthenticated {
                    Button("Disconnect") {
                        viewModel.pcoLogout()
                    }
                    .foregroundStyle(.red)
                }

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 440, height: 520)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "3B7D5E"), Color(hex: "2D6049")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 64, height: 64)

                Image(systemName: "person.3.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }
            .padding(.top, 24)

            Text("Planning Center")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Connect to pull team members and weekends")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Credentials View (not connected)

    private var credentialsView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Personal Access Token")
                    .font(.headline)
                    .padding(.top, 16)

                Text("Create a token at api.planningcenteronline.com/oauth/applications")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Application ID")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Paste your Application ID", text: $appId)
                        .textFieldStyle(.roundedBorder)

                    Text("Secret")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SecureField("Paste your Secret", text: $secret)
                        .textFieldStyle(.roundedBorder)
                }

                if let error = viewModel.pcoError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                HStack {
                    Button("Open PCO Developer") {
                        NSWorkspace.shared.open(URL(string: "https://api.planningcenteronline.com/oauth/applications")!)
                    }
                    .font(.caption)
                    .buttonStyle(.link)

                    Spacer()

                    if isConnecting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button("Connect") {
                            let trimmedId = appId.trimmingCharacters(in: .whitespaces)
                            let trimmedSecret = secret.trimmingCharacters(in: .whitespaces)
                            viewModel.pcoAuth.connect(appId: trimmedId, secret: trimmedSecret)
                            isConnecting = true
                            Task {
                                await viewModel.loadPCOData()
                                isConnecting = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: "3B7D5E"))
                        .disabled(appId.trimmingCharacters(in: .whitespaces).isEmpty ||
                                  secret.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Connected View

    private var connectedView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
                Text("Connected")
                    .font(.headline)
                    .foregroundStyle(.green)
            }
            .padding(.top, 16)

            Divider()
                .padding(.horizontal, 24)

            // Service type picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Service Type")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if viewModel.pcoServiceTypes.isEmpty {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Loading...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Picker("Service Type", selection: Binding(
                        get: { viewModel.selectedServiceTypeId ?? "" },
                        set: { newValue in
                            viewModel.selectedServiceTypeId = newValue.isEmpty ? nil : newValue
                            Task { await viewModel.loadPCOData() }
                        }
                    )) {
                        Text("Select...").tag("")
                        ForEach(viewModel.pcoServiceTypes, id: \.id) { st in
                            Text(st.name).tag(st.id)
                        }
                    }
                    .labelsHidden()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            // Team picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Camera Team")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if viewModel.pcoTeams.isEmpty && viewModel.selectedServiceTypeId != nil {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Loading teams...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Picker("Team", selection: Binding(
                        get: { viewModel.selectedTeamId ?? "" },
                        set: { viewModel.selectedTeamId = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("All Teams").tag("")
                        ForEach(viewModel.pcoTeams) { team in
                            Text(team.name).tag(team.id)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: viewModel.selectedTeamId) { _, _ in
                        Task { await viewModel.loadTeamMembersForSelectedWeekend() }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            if let error = viewModel.pcoError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Color hex init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
