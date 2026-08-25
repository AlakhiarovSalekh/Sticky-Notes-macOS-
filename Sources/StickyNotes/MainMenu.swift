import AppKit

/// Programmatic main menu. An `.accessory` app has no menu bar of its own, but
/// the main menu still routes key equivalents (⌘C/⌘V/⌘Z, ⌘B/I/U/T, ⌘N, ⌘Q)
/// down the responder chain to the focused note's text view.
enum MainMenu {

    @MainActor
    static func install() {
        let mainMenu = NSMenu()

        // App menu
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(withTitle: "New Note",
                        action: #selector(AppDelegate.newNoteMenuAction(_:)),
                        keyEquivalent: "n")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Sticky Notes",
                        action: #selector(NSApplication.terminate(_:)),
                        keyEquivalent: "q")

        // Edit menu (standard responder actions)
        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editItem.submenu = editMenu
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        // Format menu (NoteTextView actions; ⌘T deliberately = strikethrough)
        let fmtItem = NSMenuItem()
        mainMenu.addItem(fmtItem)
        let fmtMenu = NSMenu(title: "Format")
        fmtItem.submenu = fmtMenu
        fmtMenu.addItem(withTitle: "Bold",
                        action: #selector(NoteTextView.toggleBoldface(_:)), keyEquivalent: "b")
        fmtMenu.addItem(withTitle: "Italic",
                        action: #selector(NoteTextView.toggleItalics(_:)), keyEquivalent: "i")
        fmtMenu.addItem(withTitle: "Underline",
                        action: #selector(NoteTextView.toggleUnderline(_:)), keyEquivalent: "u")
        fmtMenu.addItem(withTitle: "Strikethrough",
                        action: #selector(NoteTextView.formatStrikethrough(_:)), keyEquivalent: "t")

        NSApp.mainMenu = mainMenu
    }
}
