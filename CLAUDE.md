# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sudo is a single-player Sudoku game for iOS (iPhone & iPad) built with **Swift**, **SwiftUI**, and **SwiftData**. (Xcode project and bundle are still named "Pandoku 2" internally.) The app follows a **local-first** architecture with no backend - all data is stored on-device using SwiftData (SQLite wrapper). This is a learning project for iOS development.

**Minimum iOS Version:** iOS 17.0 (required for SwiftData)

## Build and Test Commands

### Build
```bash
# Build the project
xcodebuild -project "Pandoku 2.xcodeproj" -scheme "Pandoku 2" -configuration Debug build

# Build for release
xcodebuild -project "Pandoku 2.xcodeproj" -scheme "Pandoku 2" -configuration Release build
```

### Run Tests
```bash
# Run all tests
xcodebuild test -project "Pandoku 2.xcodeproj" -scheme "Pandoku 2" -destination 'platform=iOS Simulator,name=iPhone 15'

# Run only unit tests
xcodebuild test -project "Pandoku 2.xcodeproj" -scheme "Pandoku 2" -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:Pandoku 2Tests
```

### Alternative: Open in Xcode
```bash
open "Pandoku 2.xcodeproj"
```

Then use Xcode's built-in Run (⌘R) and Test (⌘U) commands.

## Architecture

### Pattern: MVVM (Model-View-ViewModel)
- **Models:** SwiftData `@Model` classes for persistence
- **Views:** SwiftUI views
- **ViewModels:** Business logic and state management
- **Services:** Core algorithms (Sudoku generation, validation)

### Planned Structure
```
Pandoku 2/
├── Models/           # SwiftData @Model classes
├── ViewModels/       # Observable view models
├── Views/            # SwiftUI views
├── Services/         # SudokuGenerator, SudokuValidator, DataManager
├── Utilities/        # Constants, Extensions, ThemeManager
└── Resources/        # Assets, Localizations
```

### Key SwiftData Models

The app uses two primary SwiftData models (defined in `Pandoku_2App.swift` schema):

1. **GameSession** - Stores game state
   - `difficulty`, `startTime`, `status` (inProgress/completed/abandoned)
   - `initialBoard`, `currentBoard`, `solutionBoard` (81-char strings)
   - `mistakesCount`, `hintsUsed`, `moveHistory`

2. **Statistic** - Aggregated player statistics
   - Per-difficulty tracking (gamesPlayed, gamesCompleted, bestTime)

### Testing Framework

Uses **Swift Testing** (not XCTest):
```swift
import Testing
@testable import Pandoku_2

struct Pandoku_2Tests {
    @Test func example() async throws {
        // Use #expect(...) for assertions
    }
}
```

## Important Notes

- **No Backend:** All puzzle generation happens client-side using Backtracking algorithm
- **No Authentication:** Local-only gameplay, no user accounts
- **Localization:** Supports TR/EN via `Localizable.strings`
- **Theme System:** Dark/Light/Auto mode support
- **Persistence:** Auto-save on every move using SwiftData

## See Also

- `pandoku2_prd.md` - Full Product Requirements Document with detailed specs
