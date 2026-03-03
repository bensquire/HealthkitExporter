import Foundation
import SwiftUI
import HealthKit

@MainActor
final class AppViewModel: ObservableObject {
    // MARK: - Published State
    @Published var lastExportResult: ExportResult?
    @Published var lastExportDate: Date?
    @Published var isExporting = false
    @Published var isAuthorized = false
    @Published var authorizationError: String?
    @Published var statusMessage = "Not exported yet"

    // MARK: - AppStorage Settings
    @AppStorage("exportMode") var exportMode: String = ExportMode.file.rawValue
    @AppStorage("httpURL") var httpURL: String = ""
    @AppStorage("httpToken") var httpToken: String = ""
    @AppStorage("fileDirectoryPath") var fileDirectoryPath: String = ""
    @AppStorage("exportInterval") var exportIntervalRaw: Int = ExportInterval.hourly.rawValue
    @AppStorage("lookbackDays") var lookbackDays: Int = 365

    // File bookmark stored separately as Data
    var fileBookmarkData: Data? {
        get { UserDefaults.standard.data(forKey: "fileBookmarkData") }
        set { UserDefaults.standard.set(newValue, forKey: "fileBookmarkData") }
    }

    // MARK: - Services
    private let healthKitService = HealthKitService()
    private let exportService = ExportService()
    private let schedulerService = SchedulerService()

    // MARK: - Computed
    var currentMode: ExportMode {
        ExportMode(rawValue: exportMode) ?? .file
    }

    var currentInterval: ExportInterval {
        ExportInterval(rawValue: exportIntervalRaw) ?? .hourly
    }

    var currentConfig: ExportConfiguration {
        ExportConfiguration(
            mode: currentMode,
            httpURL: httpURL,
            httpToken: httpToken,
            fileBookmarkData: fileBookmarkData,
            fileDirectoryPath: fileDirectoryPath,
            interval: currentInterval,
            lookbackDays: lookbackDays
        )
    }

    // MARK: - Init
    init() {
        // Scheduler will be started after authorization
    }

    // MARK: - Authorization
    func requestAuthorization() async {
        guard HealthKitService.isAvailable else {
            authorizationError = "HealthKit is not available on this device."
            return
        }

        do {
            try await healthKitService.requestAuthorization()
            isAuthorized = true
            authorizationError = nil
            restartScheduler()
        } catch {
            authorizationError = error.localizedDescription
            isAuthorized = false
        }
    }

    // MARK: - Export
    func exportNow() async {
        guard !isExporting else { return }
        isExporting = true
        statusMessage = "Exporting…"

        defer { isExporting = false }

        guard HealthKitService.isAvailable else {
            statusMessage = "HealthKit unavailable"
            lastExportResult = .failure(ExportError(message: "HealthKit is not available"))
            return
        }

        let config = currentConfig

        do {
            let data = try await healthKitService.fetchHealthData(lookbackDays: config.lookbackDays)
            let result = await exportService.export(data: data, config: config)

            lastExportResult = result
            switch result {
            case .success(let date, let count):
                lastExportDate = date
                statusMessage = "Exported \(count) days"
            case .failure(let error):
                statusMessage = "Export failed"
                print("Export error: \(error.message)")
            }
        } catch {
            let exportError = ExportError(error)
            lastExportResult = .failure(exportError)
            statusMessage = "Fetch failed"
            print("HealthKit fetch error: \(error.localizedDescription)")
        }
    }

    // MARK: - Test Export
    @Published var isTestExporting = false
    @Published var testExportResult: ExportResult?

    func sendTestExport() async {
        guard !isTestExporting else { return }
        isTestExporting = true
        testExportResult = nil
        defer { isTestExporting = false }

        let today = Date()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        let mockData: [HealthDataPoint] = (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return HealthDataPoint(
                date: formatter.string(from: date),
                stepCount: Int.random(in: 4000...12000),
                flightsClimbed: Int.random(in: 0...20)
            )
        }

        let result = await exportService.export(data: mockData, config: currentConfig)
        testExportResult = result
    }

    // MARK: - Scheduler
    func restartScheduler() {
        let interval = currentInterval.duration
        Task {
            await schedulerService.start(interval: interval) { [weak self] in
                await self?.exportNow()
            }
        }
    }

    func stopScheduler() {
        Task {
            await schedulerService.stop()
        }
    }
}
