import Foundation

enum FileExporterError: Error, Sendable {
    case noDirectory
    case encodingFailed(String)
    case writeFailed(String)
}

struct FileExporter: Sendable {
    /// Returns the app's Documents directory URL.
    static let documentsDirectory: URL =
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    func export(data: [HealthDataPoint], config: ExportConfiguration) async throws -> Int {
        let directoryURL = Self.documentsDirectory

        // Group data by year
        let byYear = Dictionary(grouping: data) { point -> Int in
            let parts = point.date.split(separator: "-")
            return Int(parts.first ?? "0") ?? 0
        }

        let now = Date()
        let encoder = ExportService.makeEncoder()

        var writtenCount = 0
        for (year, points) in byYear {
            let export = YearExport(
                year: year,
                exportedAt: now,
                data: points.sorted { $0.date < $1.date }
            )

            let jsonData: Data
            do {
                jsonData = try encoder.encode(export)
            } catch {
                throw FileExporterError.encodingFailed(error.localizedDescription)
            }

            let fileURL = directoryURL.appendingPathComponent("\(year).json")
            do {
                try jsonData.write(to: fileURL, options: .atomic)
            } catch {
                throw FileExporterError.writeFailed(error.localizedDescription)
            }

            writtenCount += points.count
        }

        return writtenCount
    }
}
