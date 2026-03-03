import Testing
import Foundation

struct ExportErrorTests {
    @Test func messageFromString() {
        // Arrange
        let error = ExportError(message: "Something went wrong")

        // Assert
        #expect(error.message == "Something went wrong")
        #expect(error.localizedDescription == "Something went wrong")
    }

    @Test func messageFromUnderlyingError() {
        // Arrange
        let underlying = URLError(.badURL)

        // Act
        let error = ExportError(underlying)

        // Assert
        #expect(error.message == underlying.localizedDescription)
    }

    @Test func wrapsAnyError() {
        // Arrange
        struct CustomError: Error, LocalizedError {
            var errorDescription: String? { "custom error" }
        }

        // Act
        let error = ExportError(CustomError())

        // Assert
        #expect(error.message == "custom error")
    }
}

struct ExportResultTests {
    @Test func successStoresExportedAtAndCount() {
        // Arrange
        let date = Date()

        // Act
        let result = ExportResult.success(exportedAt: date, recordCount: 42)

        // Assert
        if case .success(let exportedAt, let count) = result {
            #expect(exportedAt == date)
            #expect(count == 42)
        } else {
            Issue.record("Expected .success")
        }
    }

    @Test func failureStoresMessage() {
        // Arrange
        let error = ExportError(message: "disk full")

        // Act
        let result = ExportResult.failure(error)

        // Assert
        if case .failure(let e) = result {
            #expect(e.message == "disk full")
        } else {
            Issue.record("Expected .failure")
        }
    }
}
