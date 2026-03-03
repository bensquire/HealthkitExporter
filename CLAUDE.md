# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

A `Makefile` wraps the common commands:

```bash
make build    # debug build → build/HealthKitExporter.app
make test     # run unit tests
make dmg      # release build + create DMG → build/HealthKitExporter-vX.Y.Z.dmg
make clean    # remove build/ and clean Xcode build products
```

`make dmg` signs the app and DMG when `DEVELOPMENT_TEAM=<team-id>` is set; otherwise produces an unsigned DMG for local testing. Requires `brew install create-dmg`.

Raw xcodebuild equivalents:
```bash
xcodegen generate  # regenerate .xcodeproj after changing project.yml
xcodebuild -scheme HealthKitExporter -destination "generic/platform=macOS" build CODE_SIGNING_ALLOWED=NO
open build/HealthKitExporter.app
```

## Tests

```bash
make test
# or directly:
xcodebuild -scheme HealthKitExporter -destination "platform=macOS,arch=arm64" test CODE_SIGNING_ALLOWED=NO
```

Tests live in `HealthKitExporterTests/` and use the **Swift Testing** framework (`import Testing`, `@Test`, `#expect()`). The test target compiles the app's source files directly (excluding `App/HealthKitExporterApp.swift`) so there is no `@testable import` — all types are in scope directly.

What is tested: `ExportMode`, `ExportInterval`, `ExportError`, `ExportResult`, `HealthDataPoint`, `YearExport`, `ExportService.makeEncoder()`, and `HTTPExporter` URL validation.

What is not tested: `HealthKitService` (requires HealthKit hardware), `SchedulerService` (timer-based), `FileExporter` (requires security-scoped bookmarks), UI views.

## Architecture

This is a Swift 6 macOS menu-bar app using strict concurrency throughout.

**Data flow:**
1. `SchedulerService` fires on an interval, calling back into `AppViewModel.exportNow()`
2. `AppViewModel` asks `HealthKitService` to fetch data, then passes it to `ExportService`
3. `ExportService` routes to either `HTTPExporter` (POST JSON) or `FileExporter` (write per-year JSON files)

**Concurrency model:**
- All services are `actor` types — isolate their own state
- `AppViewModel` is `@MainActor ObservableObject` — all `@Published` mutations are automatically on main
- `ExportConfiguration` is a `Sendable` value type used to snapshot settings before crossing actor boundaries
- `HKStatisticsCollectionQuery` is not async — bridged via `withCheckedThrowingContinuation`

**Key types:**
- `HealthDataPoint` — one day's steps + flights climbed, date as `"yyyy-MM-dd"` string
- `YearExport` — root JSON object written per year file, wraps `[HealthDataPoint]`
- `ExportResult` — `.success(exportedAt:recordCount:)` or `.failure(ExportError)`, used across actor boundaries
- `ExportConfiguration` — snapshot of all user settings passed to exporters
- `ExportMode` — `.http` or `.file`
- `ExportInterval` — `.hourly`, `.every6h`, `.daily`

**Settings persistence:**
- User settings stored via `@AppStorage` (UserDefaults)
- File directory stored as a security-scoped bookmark under key `"fileBookmarkData"` in UserDefaults (not `@AppStorage`)

**Shared utilities:**
- `ExportService.makeEncoder()` — single source for `JSONEncoder` config (iso8601, prettyPrinted, sortedKeys); used by both exporters
- Date formatting uses `DateFormatter` with `dateFormat = "yyyy-MM-dd"`, `locale = en_US_POSIX`, `timeZone = .current` — match this exactly whenever formatting health data dates

**File output:** One JSON file per year (e.g. `2026.json`) written atomically. `FileExporter` groups data by year, sorts ascending by date, and wraps in `YearExport`.

**HTTP output:** POSTs `[HealthDataPoint]` array as JSON body. Bearer token is optional.

## Project Config

- `project.yml` is the XcodeGen spec — edit this instead of `.xcodeproj` directly, then run `xcodegen generate`
- Bundle ID: `com.bengsfort.HealthKitExporter`
- Deployment target: macOS 13.0, Swift 6.0
- HealthKit is unavailable on CI (macOS VMs) — `HealthKitService.isAvailable` guards all HealthKit calls

## CI / Release

Releases trigger on `v*` tags. The workflow: signs with Developer ID → archives → exports → creates DMG with `create-dmg` → notarizes DMG via `notarytool` → staples → uploads `.dmg` to GitHub Release.

Required secrets: `APPLE_DEVELOPER_CERTIFICATE_P12`, `APPLE_DEVELOPER_CERTIFICATE_PASSWORD`, `APPLE_TEAM_ID`, `KEYCHAIN_PASSWORD`, `ASC_API_KEY_ID`, `ASC_API_ISSUER_ID`, `ASC_API_KEY_P8`
