import SwiftUI

struct StatusSummaryView: View {
    @ObservedObject var viewModel: AppViewModel

    private let relativeDateFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    private var lastExportText: String {
        guard let date = viewModel.lastExportDate else { return "Never" }
        return relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }

    private var resultColor: Color {
        switch viewModel.lastExportResult {
        case .success: return .green
        case .failure: return .red
        case nil: return .secondary
        }
    }

    private var resultIcon: String {
        switch viewModel.lastExportResult {
        case .success: return "checkmark.circle.fill"
        case .failure: return "exclamationmark.circle.fill"
        case nil: return "clock.circle"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: resultIcon)
                .foregroundColor(resultColor)
                .font(.system(size: 16))

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.statusMessage)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                Text("Last: \(lastExportText)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if viewModel.isExporting {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 16, height: 16)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
