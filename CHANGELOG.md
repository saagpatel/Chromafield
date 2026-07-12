# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Changed

- Start new sessions from the editable Nebula preset for a useful first-run canvas.
- Improve particle legibility and trail decay, and correct Simulator device-tier detection.
- Surface Metal initialization, save, delete, and export failures to the user.
- Harden video writer setup and frame-append error handling.
- Make signing automatic by default while keeping provisioning updates an explicit operator action.
- Expand CI to validate release builds, bundled presets, privacy declarations, and the full test suite.

### Fixed

- Prevent Simulator builds from receiving desktop-class particle budgets.
- Prevent failed video exports from being reported as successful.
