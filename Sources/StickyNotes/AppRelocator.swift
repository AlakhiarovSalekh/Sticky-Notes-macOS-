import AppKit

/// Minimal self-contained port of the LetsMove behavior: on first launch from
/// outside /Applications, offer to move the app there. Asks once, then remembers
/// the choice. Only meaningful for a real `.app` bundle (skips `swift run`).
enum AppRelocator {

    private static let declinedKey = "MoveToApplicationsDeclined"

    // MARK: Pure decision (unit-tested)

    /// Whether we should present the move prompt.
    static func shouldOfferMove(bundlePath: String,
                                applicationsDirs: [String],
                                declined: Bool) -> Bool {
        guard bundlePath.hasSuffix(".app") else { return false }   // bare exec / swift run
        if declined { return false }
        for dir in applicationsDirs {
            let prefix = dir.hasSuffix("/") ? dir : dir + "/"
            if bundlePath == dir || bundlePath.hasPrefix(prefix) { return false }
        }
        return true
    }

    // MARK: Entry point

    @MainActor
    static func offerMoveToApplicationsIfNeeded() {
        let defaults = UserDefaults.standard
        let bundlePath = Bundle.main.bundlePath
        guard shouldOfferMove(bundlePath: bundlePath,
                              applicationsDirs: applicationsDirs,
                              declined: defaults.bool(forKey: declinedKey)) else { return }

        let appName = (bundlePath as NSString).lastPathComponent   // "Sticky Notes.app"

        let alert = NSAlert()
        alert.messageText = "Move to the Applications folder?"
        alert.informativeText = "“\(displayName)” works best from your Applications folder. Move it there now?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Move to Applications Folder")
        alert.addButton(withTitle: "Do Not Move")

        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else {
            defaults.set(true, forKey: declinedKey)   // remember "don't ask again"
            return
        }

        do {
            let dest = try moveToApplications(from: bundlePath, appName: appName)
            relaunch(at: dest)   // opens the moved copy, then terminates this one
        } catch {
            NSLog("StickyNotes: move to Applications failed: \(error)")
            let fail = NSAlert()
            fail.messageText = "Couldn't move the app."
            fail.informativeText = "\(error.localizedDescription)\nYou can move it to /Applications manually."
            fail.runModal()
        }
    }

    // MARK: Helpers

    private static var applicationsDirs: [String] {
        var dirs = FileManager.default
            .urls(for: .applicationDirectory, in: .allDomainsMask)
            .map { $0.path }
        dirs.append("/Applications")
        return Array(Set(dirs))
    }

    private static var isTranslocated: Bool {
        Bundle.main.bundlePath.contains("/AppTranslocation/")
    }

    private static var displayName: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? "Sticky Notes"
    }

    /// Place the bundle into /Applications, returning the destination path.
    private static func moveToApplications(from bundlePath: String, appName: String) throws -> String {
        let fm = FileManager.default
        let dest = "/Applications/" + appName

        if fm.fileExists(atPath: dest) {
            try? fm.trashItem(at: URL(fileURLWithPath: dest), resultingItemURL: nil)
        }

        if isTranslocated {
            // Read-only translocated mount: copy rather than move.
            try fm.copyItem(atPath: bundlePath, toPath: dest)
        } else {
            do {
                try fm.moveItem(atPath: bundlePath, toPath: dest)
            } catch {
                // Likely /Applications permissions: fall back to an authenticated copy.
                try authenticatedCopy(from: bundlePath, to: dest)
            }
        }

        // Clear quarantine so Gatekeeper opens the moved copy cleanly.
        _ = try? runProcess("/usr/bin/xattr", ["-dr", "com.apple.quarantine", dest])
        return dest
    }

    private static func authenticatedCopy(from src: String, to dest: String) throws {
        let script = "do shell script \"/usr/bin/ditto \\\"\(src)\\\" \\\"\(dest)\\\"\" with administrator privileges"
        guard let apple = NSAppleScript(source: script) else {
            throw NSError(domain: "AppRelocator", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Couldn't build the install script."])
        }
        var err: NSDictionary?
        apple.executeAndReturnError(&err)
        if let err {
            throw NSError(domain: "AppRelocator", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "\(err)"])
        }
    }

    @MainActor
    private static func relaunch(at path: String) {
        let url = URL(fileURLWithPath: path)
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }

    @discardableResult
    private static func runProcess(_ launchPath: String, _ args: [String]) throws -> Int32 {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: launchPath)
        p.arguments = args
        try p.run()
        p.waitUntilExit()
        return p.terminationStatus
    }
}
