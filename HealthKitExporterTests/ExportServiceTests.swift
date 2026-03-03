import Testing
import Foundation

struct ExportServiceEncoderTests {
    @Test func outputFormattingIsPrettyPrintedAndSortedKeys() {
        // Act
        let encoder = ExportService.makeEncoder()

        // Assert
        #expect(encoder.outputFormatting.contains(.prettyPrinted))
        #expect(encoder.outputFormatting.contains(.sortedKeys))
    }

    @Test func dateEncodingStrategyIsISO8601() throws {
        // Arrange
        struct Wrapper: Encodable { let d: Date }
        let encoder = ExportService.makeEncoder()

        // Act
        let data = try encoder.encode(Wrapper(d: Date(timeIntervalSince1970: 0)))
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        // Assert — Unix epoch must encode to a known ISO8601 string
        #expect(json["d"] as? String == "1970-01-01T00:00:00Z")
    }

    @Test func keysAreSortedAlphabeticallyInOutput() throws {
        // Arrange
        let points = [HealthDataPoint(date: "2026-01-01", stepCount: 100, flightsClimbed: 2)]

        // Act
        let data = try ExportService.makeEncoder().encode(points)
        let jsonString = try #require(String(data: data, encoding: .utf8))

        // Assert — "date" < "flightsClimbed" < "stepCount" alphabetically
        let dateIdx = try #require(jsonString.range(of: "\"date\""))
        let flightsIdx = try #require(jsonString.range(of: "\"flightsClimbed\""))
        let stepsIdx = try #require(jsonString.range(of: "\"stepCount\""))
        #expect(dateIdx.lowerBound < flightsIdx.lowerBound)
        #expect(flightsIdx.lowerBound < stepsIdx.lowerBound)
    }
}

struct HTTPExporterTests {
    private func makeConfig(url: String) -> ExportConfiguration {
        ExportConfiguration(
            mode: .http,
            httpURL: url,
            httpToken: "",
            fileBookmarkData: nil,
            fileDirectoryPath: "",
            interval: .hourly,
            lookbackDays: 7
        )
    }

    @Test func throwsOnEmptyURL() async {
        // Arrange
        let exporter = HTTPExporter()
        let config = makeConfig(url: "")

        // Act
        do {
            _ = try await exporter.export(data: [], config: config)
            Issue.record("Expected export to throw for empty URL")
        } catch let error as URLError {
            // Assert
            #expect(error.code == .badURL)
        } catch {
            Issue.record("Expected URLError, got \(error)")
        }
    }

    @Test func throwsOnInvalidURL() async {
        // Arrange
        let exporter = HTTPExporter()
        let config = makeConfig(url: "not a url !!!")

        // Act
        do {
            _ = try await exporter.export(data: [], config: config)
            Issue.record("Expected export to throw for invalid URL")
        } catch is URLError {
            // Assert — any URLError is acceptable; the URL loading system rejects non-http(s) schemes
        } catch {
            Issue.record("Expected URLError, got \(error)")
        }
    }
}
