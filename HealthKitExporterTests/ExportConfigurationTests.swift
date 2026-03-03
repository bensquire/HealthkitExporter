import Testing

struct ExportModeTests {
    @Test func rawValues() {
        // Assert
        #expect(ExportMode.http.rawValue == "http")
        #expect(ExportMode.file.rawValue == "file")
    }

    @Test func allCasesCount() {
        // Assert
        #expect(ExportMode.allCases.count == 2)
    }

    @Test func roundTripsFromRawValue() {
        // Assert
        #expect(ExportMode(rawValue: "http") == .http)
        #expect(ExportMode(rawValue: "file") == .file)
        #expect(ExportMode(rawValue: "invalid") == nil)
    }
}

struct ExportIntervalTests {
    @Test func rawValues() {
        // Assert
        #expect(ExportInterval.hourly.rawValue == 1)
        #expect(ExportInterval.every6h.rawValue == 6)
        #expect(ExportInterval.daily.rawValue == 24)
    }

    @Test func durations() {
        // Assert
        #expect(ExportInterval.hourly.duration == .seconds(3_600))
        #expect(ExportInterval.every6h.duration == .seconds(21_600))
        #expect(ExportInterval.daily.duration == .seconds(86_400))
    }

    @Test func displayNames() {
        // Assert
        #expect(ExportInterval.hourly.displayName == "Every Hour")
        #expect(ExportInterval.every6h.displayName == "Every 6 Hours")
        #expect(ExportInterval.daily.displayName == "Daily")
    }

    @Test func allCasesCount() {
        // Assert
        #expect(ExportInterval.allCases.count == 3)
    }
}
