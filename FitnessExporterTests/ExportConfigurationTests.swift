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
