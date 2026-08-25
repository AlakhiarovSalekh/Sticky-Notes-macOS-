import AppKit

/// Centralized tunables. Win7-ish defaults; change here to retune the whole app.
enum Constants {

    /// Used for the Application Support subfolder. Bundle id when bundled, else this.
    static let appFolderName = "co.akari.stickynotes"

    static let notesFileName = "notes.json"
    static let backupFileName = "notes.json.bak"

    /// Schema version stored in the JSON envelope for future migrations.
    static let schemaVersion = 1

    /// Theme + color applied to brand-new notes / on first run.
    static let defaultTheme: NoteTheme = .windows7
    static let defaultColor: NoteColor = .yellow

    // MARK: Geometry

    static let defaultNoteSize = NSSize(width: 240, height: 220)
    static let minNoteSize = NSSize(width: 140, height: 120)

    /// Offset applied to each new note so they don't stack exactly.
    static let cascadeOffset: CGFloat = 26

    /// Height of the hover strip at the top of each note.
    static let stripHeight: CGFloat = 22

    /// Inset of the text inside the editor.
    static let textInset = NSSize(width: 10, height: 6)

    // MARK: Behavior

    /// Debounce window for autosave (seconds).
    static let autosaveDebounce: TimeInterval = 0.4

    /// Minimum visible area (points, w*h of the on-screen intersection) below
    /// which a restored note is considered off-screen and repositioned.
    static let minVisibleArea: CGFloat = 40 * 40

    // MARK: Typography

    /// Default note font. Handwritten vibe like Win7's Segoe Print, with fallbacks.
    static var defaultFont: NSFont {
        NSFont(name: "Bradley Hand", size: 16)
            ?? NSFont(name: "Noteworthy", size: 15)
            ?? NSFont.systemFont(ofSize: 14)
    }
}
