import Foundation

/// One day's aggregated health data.
struct HealthDataPoint: Codable, Sendable, Equatable {
    /// ISO-8601 date string, format "yyyy-MM-dd"
    let date: String
    let stepCount: Int
    let flightsClimbed: Int
}

/// Root object written to each year's JSON file.
struct YearExport: Codable, Sendable {
    let year: Int
    let exportedAt: Date
    let data: [HealthDataPoint]
}
