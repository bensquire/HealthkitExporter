import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            // MARK: Export Mode
            Section("Export Mode") {
                Picker("Mode", selection: $viewModel.exportMode) {
                    ForEach(ExportMode.allCases, id: \.rawValue) { mode in
                        Text(mode == .http ? "HTTP Endpoint" : "Local File")
                            .tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            // MARK: HTTP Settings
            if viewModel.currentMode == .http {
                Section("HTTP Settings") {
                    TextField("Endpoint URL", text: $viewModel.httpURL)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Bearer Token (optional)", text: $viewModel.httpToken)
                        .textFieldStyle(.roundedBorder)
                }
            }

            // MARK: File Settings
            if viewModel.currentMode == .file {
                Section("File Settings") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Output Directory")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if viewModel.fileDirectoryPath.isEmpty {
                                Text("No directory selected")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 13))
                            } else {
                                Text(viewModel.fileDirectoryPath)
                                    .font(.system(size: 12, design: .monospaced))
                                    .lineLimit(2)
                                    .truncationMode(.middle)

                                let year = Calendar.current.component(.year, from: Date())
                                Text("Output: \(year).json")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Button("Choose…") {
                            chooseDirectory()
                        }
                    }
                }
            }

            // MARK: Schedule Settings
            Section("Schedule") {
                Picker("Export Interval", selection: $viewModel.exportIntervalRaw) {
                    ForEach(ExportInterval.allCases, id: \.rawValue) { interval in
                        Text(interval.displayName).tag(interval.rawValue)
                    }
                }

                Stepper(
                    "Lookback: \(viewModel.lookbackDays) days",
                    value: $viewModel.lookbackDays,
                    in: 1...3650,
                    step: 1
                )
            }

            // MARK: HealthKit Authorization
            Section("HealthKit") {
                if viewModel.isAuthorized {
                    Label("Authorized", systemImage: "checkmark.shield.fill")
                        .foregroundColor(.green)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        if let error = viewModel.authorizationError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        Button("Authorize HealthKit Access") {
                            Task { await viewModel.requestAuthorization() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }

            // MARK: Test Export
            Section("Test Export") {
                HStack {
                    Button(viewModel.isTestExporting ? "Sending…" : "Send Mock Data") {
                        Task { await viewModel.sendTestExport() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isTestExporting)

                    Spacer()

                    if let result = viewModel.testExportResult {
                        switch result {
                        case .success(_, let count):
                            Label("\(count) records sent", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        case .failure(let error):
                            Label(error.message, systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                                .lineLimit(2)
                        }
                    }
                }

                Text("Sends 7 days of randomized mock data using your current export settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // MARK: Apply
            Section {
                HStack {
                    Spacer()
                    Button("Apply & Restart Scheduler") {
                        viewModel.restartScheduler()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 440, height: 520)
        .navigationTitle("Settings")
    }

    @MainActor
    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose the directory where health data JSON files will be saved."
        panel.prompt = "Select"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            viewModel.fileBookmarkData = bookmarkData
            viewModel.fileDirectoryPath = url.path
        } catch {
            print("Failed to create bookmark: \(error.localizedDescription)")
        }
    }
}
