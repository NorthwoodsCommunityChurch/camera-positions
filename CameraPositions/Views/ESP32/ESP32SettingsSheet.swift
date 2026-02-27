import SwiftUI

/// Sheet for configuring which ESP32 devices receive OLED display updates.
/// Each row maps a camera number to an ESP32 IP address.
struct ESP32SettingsSheet: View {
    @Bindable var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newIP = ""
    @State private var newCameraNumber = 1
    @State private var showingAddForm = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ESP32 OLED Displays")
                        .font(.headline)
                    Text("Push camera assignments to ESP32 display boards")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            if viewModel.esp32DisplayService.connections.isEmpty && !showingAddForm {
                VStack(spacing: 12) {
                    Image(systemName: "tv.badge.wifi")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No ESP32 displays configured")
                        .foregroundStyle(.secondary)
                    Text("Add an ESP32 to show the camera operator and lens\non the OLED screen attached to each camera.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(viewModel.esp32DisplayService.connections) { connection in
                        ESP32ConnectionRow(connection: connection, viewModel: viewModel)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let id = viewModel.esp32DisplayService.connections[index].id
                            viewModel.esp32DisplayService.removeConnection(id: id)
                        }
                    }
                }
                .listStyle(.inset)
            }

            Divider()

            // Add new connection form
            if showingAddForm {
                HStack(spacing: 12) {
                    Text("Cam")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Stepper(value: $newCameraNumber, in: 1...20) {
                        Text("\(newCameraNumber)")
                            .monospacedDigit()
                            .frame(width: 24, alignment: .trailing)
                    }
                    Divider().frame(height: 20)
                    Text("IP")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("10.10.11.50", text: $newIP)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 140)
                    Button("Add") {
                        let trimmed = newIP.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        let conn = ESP32Connection(cameraNumber: newCameraNumber, ipAddress: trimmed)
                        viewModel.esp32DisplayService.addConnection(conn)
                        newIP = ""
                        showingAddForm = false
                    }
                    .disabled(newIP.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button("Cancel") {
                        newIP = ""
                        showingAddForm = false
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            } else {
                HStack {
                    Button {
                        showingAddForm = true
                    } label: {
                        Label("Add ESP32", systemImage: "plus.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)

                    Spacer()

                    if !viewModel.esp32DisplayService.connections.isEmpty {
                        Button {
                            viewModel.pushToESP32Displays()
                        } label: {
                            Label("Push Now", systemImage: "paperplane")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .help("Send current assignments to all ESP32 displays")
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 420, height: 320)
    }
}

private struct ESP32ConnectionRow: View {
    let connection: ESP32Connection
    var viewModel: AppViewModel

    @State private var editingIP: String
    @State private var editingCameraNumber: Int

    init(connection: ESP32Connection, viewModel: AppViewModel) {
        self.connection = connection
        self.viewModel = viewModel
        self._editingIP = State(initialValue: connection.ipAddress)
        self._editingCameraNumber = State(initialValue: connection.cameraNumber)
    }

    var body: some View {
        HStack(spacing: 12) {
            Label("Camera \(editingCameraNumber)", systemImage: "video")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)

            Stepper(value: $editingCameraNumber, in: 1...20) {
                Text("\(editingCameraNumber)")
                    .monospacedDigit()
                    .frame(width: 20, alignment: .trailing)
            }
            .onChange(of: editingCameraNumber) { _, newVal in
                var updated = connection
                updated.cameraNumber = newVal
                viewModel.esp32DisplayService.updateConnection(updated)
            }

            TextField("IP address", text: $editingIP)
                .textFieldStyle(.roundedBorder)
                .font(.system(.caption, design: .monospaced))
                .onSubmit {
                    var updated = connection
                    updated.ipAddress = editingIP.trimmingCharacters(in: .whitespaces)
                    viewModel.esp32DisplayService.updateConnection(updated)
                }
        }
    }
}
