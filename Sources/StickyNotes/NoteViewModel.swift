import AppKit
import Combine

/// Per-note observable state bridging the SwiftUI `NoteView` and the AppKit
/// `NoteWindowController`. One instance per open note. The window controller
/// owns it and persists on `onEdited`.
@MainActor
final class NoteViewModel: ObservableObject {
    let id: UUID

    /// Initial content, applied once into the NSTextView. Never re-applied, so
    /// theme re-renders can't clobber the user's edits.
    let initialText: NSAttributedString

    /// Latest text from the editor (source of truth is the live NSTextView).
    private(set) var currentText: NSAttributedString

    @Published var themeId: NoteTheme
    @Published var colorId: NoteColor
    @Published var isAlwaysOnTop: Bool

    var style: ThemeStyle { ThemeStyle.style(for: themeId, color: colorId) }

    // Bridges wired by the controller / editor.
    var onEdited: (() -> Void)?          // text or color changed -> persist
    var onRequestNewNote: (() -> Void)?  // "+" tapped
    var onRequestDelete: (() -> Void)?   // "×" tapped
    var requestFocus: (() -> Void)?      // set by the editor's coordinator

    init(note: Note) {
        id = note.id
        let attr = note.attributedString()
        initialText = attr
        currentText = attr
        themeId = note.themeId
        colorId = note.colorId
        isAlwaysOnTop = note.isAlwaysOnTop
    }

    func textChanged(_ s: NSAttributedString) {
        currentText = s
        onEdited?()
    }

    func setTheme(_ theme: NoteTheme) {
        guard theme != themeId else { return }
        themeId = theme
        onEdited?()
    }

    func setColor(_ color: NoteColor) {
        guard color != colorId else { return }
        colorId = color
        onEdited?()
    }
}
