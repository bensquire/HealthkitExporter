APP_NAME    = FitnessExporter
PROJECT     = FitnessExporter.xcodeproj
SCHEME      = FitnessExporter
BUILD_DIR   = build
VERSION     = $(shell grep 'CFBundleShortVersionString' project.yml | sed 's/.*"\(.*\)".*/\1/')

DEVELOPMENT_TEAM ?=
DESTINATION ?= generic/platform=iOS
SIM_DESTINATION ?= platform=iOS Simulator,OS=latest,name=iPhone 17 Pro

.PHONY: generate build test lint clean

generate:
	xcodegen generate --spec project.yml

build: generate
	xcodebuild -scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		build CODE_SIGNING_ALLOWED=NO

test: generate
	xcodebuild -scheme $(SCHEME) \
		-destination "$(SIM_DESTINATION)" \
		test CODE_SIGNING_ALLOWED=NO

lint:
	swiftlint lint --strict

clean:
	rm -rf $(BUILD_DIR)
	xcodebuild -scheme $(SCHEME) clean
