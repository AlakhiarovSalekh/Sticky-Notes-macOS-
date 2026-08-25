import AppKit

// AppKit-first entry point (no SwiftUI @main). The visible UI is the AppKit
// note panels created by the delegate; SwiftUI is used only inside each note.
//
// Top-level code runs on the main thread, so it's safe to assume main-actor
// isolation for the main-actor-isolated AppKit types.
MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
