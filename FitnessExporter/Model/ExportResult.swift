import Foundation

/// A Sendable-conforming error wrapper for crossing actor boundaries.
struct ExportError: Error, Sendable {
    let message: String
    var localizedDescription: String { message }

    init(_ error: any Error) {
        self.message = error.localizedDescription
    }

    init(message: String) {
        self.message = message
    }
}

enum ExportResult: Sendable {
    case success(exportedAt: Date, recordCount: Int)
    case failure(ExportError)
}
