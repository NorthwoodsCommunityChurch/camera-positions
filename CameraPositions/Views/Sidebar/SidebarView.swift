import SwiftUI

struct SidebarView: View {
    @Bindable var viewModel: AppViewModel
    @State private var newMemberName = ""
    @State private var showingAddMember = false
    @State private var showingPCOLogin = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // PCO Connection
            pcoConnectionSection

            Divider()

            // Weekends section
            VStack(alignment: .leading, spacing: 4) {
                Text("WEEKENDS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                List(viewModel.weekends, selection: $viewModel.selectedWeekendId) { weekend in
                    WeekendRow(weekend: weekend, isSelected: viewModel.selectedWeekendId == weekend.id)
                        .tag(weekend.id)
                }
                .listStyle(.sidebar)
                .onChange(of: viewModel.selectedWeekendId) { _, newValue in
                    if let id = newValue {
                        viewModel.selectWeekend(id)
                        if viewModel.pcoAuth.isAuthenticated {
                            Task { await viewModel.loadTeamMembersForSelectedWeekend() }
                        }
                    }
                }
            }
            .frame(maxHeight: 200)

            Divider()

            // Team members section
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("TEAM")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        showingAddMember = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("Add team member manually")
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                if viewModel.teamMembers.isEmpty {
                    VStack(spacing: 8) {
                        Text("No team members")
                            .foregroundStyle(.secondary)
                            .font(.caption)

                        Text("Add manually or connect Planning Center")
                            .foregroundStyle(.tertiary)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(viewModel.teamMembers) { member in
                                TeamMemberTileView(member: member, viewModel: viewModel)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .background(.background)
        .alert("Add Team Member", isPresented: $showingAddMember) {
            TextField("Name", text: $newMemberName)
            Button("Add") {
                if !newMemberName.trimmingCharacters(in: .whitespaces).isEmpty {
                    viewModel.teamMembers.append(TeamMember(name: newMemberName.trimmingCharacters(in: .whitespaces)))
                    newMemberName = ""
                }
            }
            Button("Cancel", role: .cancel) {
                newMemberName = ""
            }
        }
    }

    // MARK: - PCO Connection

    @ViewBuilder
    private var pcoConnectionSection: some View {
        Button {
            showingPCOLogin = true
        } label: {
            HStack(spacing: 8) {
                // Status indicator
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            viewModel.pcoAuth.isAuthenticated
                                ? Color(hex: "3B7D5E")
                                : Color.secondary.opacity(0.2)
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: viewModel.pcoAuth.isAuthenticated ? "person.3.fill" : "person.3")
                        .font(.system(size: 14))
                        .foregroundStyle(viewModel.pcoAuth.isAuthenticated ? .white : .secondary)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Planning Center")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if viewModel.pcoAuth.isAuthenticated {
                        Text(viewModel.pcoTeams.first(where: { $0.id == viewModel.selectedTeamId })?.name ?? "Connected")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    } else {
                        Text("Not connected")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary.opacity(0.5))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .sheet(isPresented: $showingPCOLogin) {
            PCOLoginSheet(viewModel: viewModel)
        }
    }
}

struct WeekendRow: View {
    let weekend: WeekendConfig
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(weekend.serviceName)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)

            Text(weekend.serviceDate, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
