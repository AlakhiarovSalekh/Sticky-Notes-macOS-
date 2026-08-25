import AppKit
import SwiftUI

/// Owns one note's panel + view model. Bridges edits/frame changes back to the
/// store via the injected `onPersist` closure, and routes new/delete requests
/// up to the app delegate.
@MainActor
final class NoteWindowController: NSWindowController, NSWindowDelegate {

    private(set) var note: Note
    let model: NoteViewModel

    private let onPersist: (Note) -> Void
    private let onRequestNewNote: () -> Void
    private let onRequestDelete: (NoteWindowController) -> Void

    init(note: Note,
         onPersist: @escaping (Note) -> Void,
         onRequestNewNote: @escaping () -> Void,
         onRequestDelete: @escaping (NoteWindowController) -> Void) {

        self.note = note
        self.onPersist = onPersist
        self.onRequestNewNote = onRequestNewNote
        self.onRequestDelete = onRequestDelete
        self.model = NoteViewModel(note: note)

        let sanitized = WindowFrameSanitizer.sanitize(
            note.frame.cgRect,
            screenVisibleFrames: NSScreen.screens.map { $0.visibleFrame }
        )
        let panel = NotePanel(contentRect: sanitized)
        super.init(window: panel)

        panel.delegate = self
        panel.level = note.isAlwaysOnTop ? .floating : .normal

        // Wire model bridges.
        model.onEdited = { [weak self] in self?.persistContent() }
        model.onRequestNewNote = { [weak self] in self?.onRequestNewNote() }
        model.onRequestDelete = { [weak self] in
            guard let self else { return }
            self.onRequestDelete(self)
        }

        let host = NSHostingView(rootView: NoteView(model: model))
        host.autoresizingMask = [.width, .height]
        panel.contentView = host
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: Presentation

    func present(activate: Bool) {
        guard let window else { return }
        if activate {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            window.invalidateShadow()
            model.requestFocus?()
        } else {
            window.orderFront(nil)
            window.invalidateShadow()
        }
    }

    // MARK: Persistence

    /// Persist text/color (called on every debounced-worthy edit; the store
    /// itself debounces the disk write).
    private func persistContent() {
        note.rtfData = Note.rtfData(from: model.currentText)
        note.plainText = model.currentText.string
        note.themeId = model.themeId
        note.colorId = model.colorId
        note.isAlwaysOnTop = model.isAlwaysOnTop
        note.modifiedAt = Date()
        // Reflect always-on-top changes on the live window.
        window?.level = model.isAlwaysOnTop ? .floating : .normal
        onPersist(note)
    }

    private func persistFrame() {
        guard let window else { return }
        note.frame = StoredRect(window.frame)
        note.modifiedAt = Date()
        onPersist(note)
    }

    // MARK: NSWindowDelegate

    func windowDidMove(_ notification: Notification) { persistFrame() }

    func windowDidEndLiveResize(_ notification: Notification) {
        persistFrame()
        window?.invalidateShadow()
    }
}
