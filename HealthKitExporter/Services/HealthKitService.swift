import Foundation
import HealthKit

enum HealthKitError: Error, Sendable {
    case notAvailable
    case notAuthorized
    case queryFailed(String)
}

actor HealthKitService {
    private let store = HKHealthStore()

    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let types: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.flightsClimbed)
        ]

        try await store.requestAuthorization(toShare: [], read: types)
    }

    /// Fetches daily totals for a quantity type over the given date range.
    /// Returns a dictionary keyed by "yyyy-MM-dd" date strings.
    func fetchDailyTotals(
        type quantityType: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async throws -> [String: Int] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let type = HKQuantityType(quantityType)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let interval = DateComponents(day: 1)

        let calendar = Calendar.current
        let anchorDate = calendar.startOfDay(for: start)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error.localizedDescription))
                    return
                }

                guard let results else {
                    continuation.resume(throwing: HealthKitError.queryFailed("No results returned"))
                    return
                }

                // Extract Sendable primitives before crossing actor boundary
                var dailyTotals: [String: Int] = [:]
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone.current

                results.enumerateStatistics(from: start, to: end) { statistics, _ in
                    let dateStr = formatter.string(from: statistics.startDate)
                    let value = statistics.sumQuantity()?.doubleValue(for: unit) ?? 0
                    dailyTotals[dateStr] = Int(value)
                }

                continuation.resume(returning: dailyTotals)
            }

            store.execute(query)
        }
    }

    /// Fetches step count and flights climbed for the given number of past days,
    /// merged into an array of HealthDataPoint sorted by date ascending.
    func fetchHealthData(lookbackDays: Int) async throws -> [HealthDataPoint] {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: Date()) // start of today (exclusive upper bound is tomorrow)
        let endInclusive = calendar.date(byAdding: .day, value: 1, to: end)!
        let start = calendar.date(byAdding: .day, value: -lookbackDays, to: end)!

        async let stepsTask = fetchDailyTotals(
            type: .stepCount,
            unit: .count(),
            start: start,
            end: endInclusive
        )
        async let flightsTask = fetchDailyTotals(
            type: .flightsClimbed,
            unit: .count(),
            start: start,
            end: endInclusive
        )

        let (steps, flights) = try await (stepsTask, flightsTask)

        // Merge by date
        var allDates = Set(steps.keys).union(Set(flights.keys))
        // Build sorted date list covering the full lookback window
        var datePoints: [HealthDataPoint] = []

        var current = start
        while current < endInclusive {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone.current
            let dateStr = formatter.string(from: current)
            allDates.insert(dateStr)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }

        let sortedDates = allDates.sorted()
        for dateStr in sortedDates {
            let stepCount = steps[dateStr] ?? 0
            let flightsClimbed = flights[dateStr] ?? 0
            // Skip the end day (today hasn't ended) only if it's in the future
            datePoints.append(HealthDataPoint(
                date: dateStr,
                stepCount: stepCount,
                flightsClimbed: flightsClimbed
            ))
        }

        return datePoints
    }
}
