# HealthKit Exporter

A macOS menu-bar app that reads step count and flights climbed from HealthKit (synced from iPhone via iCloud) and exports the data to an HTTP endpoint or local JSON files on a configurable schedule.

## Features

- Exports step count and flights climbed as daily totals
- Two export modes: HTTP POST or local JSON files (one file per year, e.g. `2026.json`)
- Configurable export interval: hourly, every 6 hours, or daily
- Configurable lookback window (default 365 days)
- Test export with mock data to verify your configuration
- Lives in the menu bar — no Dock icon

## Requirements

- macOS 13.0+
- iPhone with Health app syncing to iCloud

## Development

### Prerequisites

```bash
brew install xcodegen create-dmg
```

### Setup

```bash
git clone git@github.com:bensquire/HealthkitExporter.git
cd HealthkitExporter
xcodegen generate
open HealthKitExporter.xcodeproj
```

### Common tasks

```bash
make build   # build (unsigned, for local testing)
make test    # run unit tests
make dmg     # build a release DMG (set DEVELOPMENT_TEAM=<id> to sign)
make clean   # clean build artefacts
```

## Data format

Each year's data is written to `<year>.json`:

```json
{
  "year" : 2026,
  "exportedAt" : "2026-03-03T12:00:00Z",
  "data" : [
    {
      "date" : "2026-01-01",
      "flightsClimbed" : 4,
      "stepCount" : 8542
    }
  ]
}
```

## License

MIT
