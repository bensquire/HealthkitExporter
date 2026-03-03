import Foundation

enum ExportMode: String, CaseIterable, Codable, Sendable {
    case http = "http"
    case file = "file"
}

enum ExportInterval: Int, CaseIterable, Codable, Sendable {
    case hourly = 1
    case every6h = 6
    case daily = 24

    var displayName: String {
        switch self {
        case .hourly: return "Every Hour"
        case .every6h: return "Every 6 Hours"
        case .daily: return "Daily"
        }
    }

    var duration: Duration {
        .seconds(rawValue * 3600)
    }
}

/// All user-configurable settings as a Sendable value type.
struct ExportConfiguration: Sendable {
    var mode: ExportMode
    var httpURL: String
    var httpToken: String
    var fileBookmarkData: Data?
    var fileDirectoryPath: String
    var interval: ExportInterval
    var lookbackDays: Int
}
