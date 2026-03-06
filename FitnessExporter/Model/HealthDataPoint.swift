import Foundation

/// One day's aggregated health data.
struct HealthDataPoint: Codable, Sendable, Equatable {
    /// ISO-8601 date string, format "yyyy-MM-dd"
    let date: String
    let stepCount: Int
    let flightsClimbed: Int

    /// Shared date formatter for "yyyy-MM-dd" health data dates.
    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        return f
    }()
}

/// Root object written to each year's JSON file.
struct YearExport: Codable, Sendable {
    let year: Int
    let exportedAt: Date
    let data: [HealthDataPoint]
}
