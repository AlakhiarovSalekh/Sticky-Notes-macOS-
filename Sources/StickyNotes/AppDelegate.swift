import AppKit

/// Orchestrator: activation policy, menu bar, note window lifecycle, persistence.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    let store = NoteStore()
    private var controllers: [UUID: NoteWindowController] = [:]
    private var statusBar: StatusBarController!

    // MARK: Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)   // no Dock icon; menu-bar utility

        // Offer to move into /Applications first. If the user accepts, the app
        // relaunches from the new location and terminates before reaching the
        // note setup below.
        AppRelocator.offerMoveToApplicationsIfNeeded()

        MainMenu.install()

        statusBar = StatusBarController(
            onLeftClick: { [weak self] in self?.raiseAllNotes() },
            onNewNote: { [weak self] in self?.newNote() },
            onShowAll: { [weak self] in self?.raiseAllNotes() },
            onHideAll: { [weak self] in self?.hideAll() },
            onToggleLogin: { LoginItem.toggle() },
            isLoginEnabled: { LoginItem.isEnabled },
            onQuit: { NSApp.terminate(nil) }
        )

        store.load()
        if store.notes.isEmpty {
            newNote()   // first run: open a fresh note, like Win7
        } else {
            for note in store.notes.sorted(by: { $0.createdAt < $1.createdAt }) {
                presentController(for: note, activate: false)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false   // stay alive in the menu bar with zero notes
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.saveImmediately()
    }

    func applicationDidResignActive(_ notification: Notification) {
        store.saveImmediately()
    }

    // MARK: Menu action routed via the responder chain (⌘N)

    @objc func newNoteMenuAction(_ sender: Any?) { newNote() }

    // MARK: Note management

    @discardableResult
    func newNote() -> NoteWindowController {
        let primary = NSScreen.main?.visibleFrame
            ?? NSScreen.screens.first?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let frame = WindowFrameSanitizer.defaultFrame(noteCount: store.notes.count,
                                                       primaryVisibleFrame: primary)
        let note = Note(frame: StoredRect(frame))
        store.upsert(note)
        return presentController(for: note, activate: true)
    }

    @discardableResult
    private func presentController(for note: Note, activate: Bool) -> NoteWindowController {
        let controller = NoteWindowController(
            note: note,
            onPersist: { [weak self] updated in self?.store.upsert(updated) },
            onRequestNewNote: { [weak self] in self?.newNote() },
            onRequestDelete: { [weak self] c in self?.deleteNote(c) }
        )
        controllers[note.id] = controller
        controller.present(activate: activate)
        return controller
    }

    private func deleteNote(_ controller: NoteWindowController) {
        let note = controller.note
        if !note.isEmpty {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = "Delete this note?"
            alert.informativeText = "This note has content and can't be recovered."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Delete")
            alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }
        controllers[note.id] = nil
        store.delete(id: note.id)
        controller.close()
    }

    /// Bring every note to the front, above other apps' windows (menu-bar
    /// left-click / "Show All Notes"). `orderFrontRegardless` also un-hides
    /// notes that were previously hidden or buried.
    private func raiseAllNotes() {
        NSApp.activate(ignoringOtherApps: true)
        for c in controllers.values { c.window?.orderFrontRegardless() }
    }

    private func hideAll() {
        for c in controllers.values { c.window?.orderOut(nil) }
    }
}
