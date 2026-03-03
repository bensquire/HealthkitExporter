import Foundation

enum FileExporterError: Error, Sendable {
    case noBookmark
    case cannotResolveBookmark(String)
    case encodingFailed(String)
    case writeFailed(String)
}

struct FileExporter: Sendable {
    func export(data: [HealthDataPoint], config: ExportConfiguration) async throws -> Int {
        guard let bookmarkData = config.fileBookmarkData else {
            throw FileExporterError.noBookmark
        }

        var isStale = false
        let directoryURL: URL
        do {
            directoryURL = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        } catch {
            throw FileExporterError.cannotResolveBookmark(error.localizedDescription)
        }

        guard directoryURL.startAccessingSecurityScopedResource() else {
            throw FileExporterError.cannotResolveBookmark("Cannot access security-scoped resource")
        }
        defer { directoryURL.stopAccessingSecurityScopedResource() }

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
