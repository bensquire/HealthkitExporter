import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("HealthKit Exporter")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Status
            StatusSummaryView(viewModel: viewModel)

            Divider()

            // Actions
            VStack(spacing: 2) {
                MenuBarButton(label: "Export Now", icon: "square.and.arrow.up", disabled: viewModel.isExporting) {
                    Task { await viewModel.exportNow() }
                }

                MenuBarButton(label: "Settings…", icon: "gear") {
                    openWindow(id: "settings")
                    NSApp.activate(ignoringOtherApps: true)
                    dismiss()
                }

                Divider()
                    .padding(.vertical, 2)

                MenuBarButton(label: "Quit", icon: "power") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.bottom, 8)
        }
        .frame(width: 260)
    }
}

private struct MenuBarButton: View {
    let label: String
    let icon: String
    var disabled: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(isHovered && !disabled ? Color.accentColor.opacity(0.15) : Color.clear)
        .cornerRadius(6)
        .padding(.horizontal, 4)
        .disabled(disabled)
        .onHover { isHovered = $0 }
    }
}
