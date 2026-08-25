import Foundation
import ServiceManagement

/// Launch-at-login toggle via SMAppService (macOS 13+).
/// Only works when the app runs from a bundle (.app); a no-op otherwise.
enum LoginItem {

    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    static func toggle() {
        guard #available(macOS 13.0, *) else { return }
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("StickyNotes: login item toggle failed: \(error)")
        }
    }
}
