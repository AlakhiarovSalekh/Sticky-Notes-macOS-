# Contributing

Thanks for your interest in Sticky Notes! This is a small, native macOS app.

## Dev setup

- macOS 14+ and the Swift 5.9+ toolchain (Xcode 15+; built on Xcode 26).
- Open `Package.swift` in Xcode, or use the command line.

```bash
swift build       # build
swift test        # run the test suite
swift run StickyNotes   # run from the CLI
scripts/bundle.sh release && open "build/Sticky Notes.app"   # run as a real .app
```

## Before opening a PR

- `swift build` and `swift test` must pass (CI runs both).
- Match the surrounding code style — the codebase is AppKit-first with SwiftUI
  inside each note; keep that boundary clean.
- Keep pure logic (e.g. `WindowFrameSanitizer`, `AppRelocator.shouldOfferMove`,
  `ThemeStyle.style`) unit-tested.

## Adding a theme

Themes live in [`Sources/StickyNotes/ThemeStyle.swift`](Sources/StickyNotes/ThemeStyle.swift):

1. Add a `case` to `NoteTheme` (keep the raw value stable — it's persisted).
2. Add a `displayName`.
3. Add a `case` to `ThemeStyle.style(for:color:)` describing the look
   (background fill, font, corner radius, border, caption).

`ThemeStyleTests` iterates every theme automatically, so a new theme is covered
the moment you add it.

## Reporting bugs / ideas

Open an issue using the templates. Include your macOS version and steps to
reproduce.
