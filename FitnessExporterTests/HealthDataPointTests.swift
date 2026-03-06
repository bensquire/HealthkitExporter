import Testing
import Foundation

struct HealthDataPointTests {
    @Test func codableRoundTrip() throws {
        // Arrange
        let point = HealthDataPoint(date: "2026-03-03", stepCount: 8_000, flightsClimbed: 5)

        // Act
        let data = try JSONEncoder().encode(point)
        let decoded = try JSONDecoder().decode(HealthDataPoint.self, from: data)

        // Assert
        #expect(decoded == point)
    }

    @Test func encodesToExpectedJSONKeys() throws {
        // Arrange
        let point = HealthDataPoint(date: "2026-03-03", stepCount: 8_000, flightsClimbed: 5)

        // Act
        let data = try JSONEncoder().encode(point)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        // Assert
        #expect(json["date"] as? String == "2026-03-03")
        #expect(json["stepCount"] as? Int == 8_000)
        #expect(json["flightsClimbed"] as? Int == 5)
    }

    @Test func equalityByAllFields() {
        // Arrange
        let a = HealthDataPoint(date: "2026-01-01", stepCount: 100, flightsClimbed: 2)
        let b = HealthDataPoint(date: "2026-01-01", stepCount: 100, flightsClimbed: 2)
        let c = HealthDataPoint(date: "2026-01-01", stepCount: 999, flightsClimbed: 2)

        // Assert
        #expect(a == b)
        #expect(a != c)
    }
}

struct YearExportTests {
    @Test func codableRoundTrip() throws {
        // Arrange
        let points = [
            HealthDataPoint(date: "2026-01-01", stepCount: 5_000, flightsClimbed: 3),
            HealthDataPoint(date: "2026-01-02", stepCount: 7_500, flightsClimbed: 8),
        ]
        let export = YearExport(year: 2026, exportedAt: Date(timeIntervalSince1970: 0), data: points)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Act
        let data = try ExportService.makeEncoder().encode(export)
        let decoded = try decoder.decode(YearExport.self, from: data)

        // Assert
        #expect(decoded.year == 2026)
        #expect(decoded.data.count == 2)
        #expect(decoded.data[0] == points[0])
        #expect(decoded.data[1] == points[1])
    }
}
