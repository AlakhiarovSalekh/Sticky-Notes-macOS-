import AppKit

/// Owns the menu-bar status item. Keeps the app reachable with zero notes open.
@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {

    private let item: NSStatusItem
    private let menu: NSMenu
    private var loginMenuItem: NSMenuItem!

    private let onLeftClick: () -> Void
    private let onNewNote: () -> Void
    private let onShowAll: () -> Void
    private let onHideAll: () -> Void
    private let onToggleLogin: () -> Void
    private let isLoginEnabled: () -> Bool
    private let onQuit: () -> Void

    init(onLeftClick: @escaping () -> Void,
         onNewNote: @escaping () -> Void,
         onShowAll: @escaping () -> Void,
         onHideAll: @escaping () -> Void,
         onToggleLogin: @escaping () -> Void,
         isLoginEnabled: @escaping () -> Bool,
         onQuit: @escaping () -> Void) {

        self.onLeftClick = onLeftClick
        self.onNewNote = onNewNote
        self.onShowAll = onShowAll
        self.onHideAll = onHideAll
        self.onToggleLogin = onToggleLogin
        self.isLoginEnabled = isLoginEnabled
        self.onQuit = onQuit

        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu = NSMenu()
        super.init()

        // Left-click raises the notes; the menu is reserved for right-click.
        // Keep `item.menu` unset so the button's action fires on both clicks.
        menu.delegate = self
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Sticky Notes")
            button.toolTip = "Sticky Notes"
            button.target = self
            button.action = #selector(statusButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        buildMenu()
    }

    private func buildMenu() {
        addItem(to: menu, "New Note", #selector(newNoteAction), key: "n")
        menu.addItem(.separator())
        addItem(to: menu, "Show All Notes", #selector(showAllAction))
        addItem(to: menu, "Hide All Notes", #selector(hideAllAction))
        menu.addItem(.separator())
        loginMenuItem = addItem(to: menu, "Launch at Login", #selector(toggleLoginAction))
        menu.addItem(.separator())
        addItem(to: menu, "Quit Sticky Notes", #selector(quitAction), key: "q")
    }

    /// Left-click → raise notes. Right-click (or control-click) → show the menu.
    @objc private func statusButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let isRight = event?.type == .rightMouseUp
            || (event?.modifierFlags.contains(.control) ?? false)
        if isRight {
            item.menu = menu
            item.button?.performClick(nil)   // pops the menu under the item
        } else {
            onLeftClick()
        }
    }

    @discardableResult
    private func addItem(to menu: NSMenu, _ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let mi = NSMenuItem(title: title, action: action, keyEquivalent: key)
        mi.target = self
        menu.addItem(mi)
        return mi
    }

    // MARK: Actions

    @objc private func newNoteAction() { onNewNote() }
    @objc private func showAllAction() { onShowAll() }
    @objc private func hideAllAction() { onHideAll() }
    @objc private func toggleLoginAction() { onToggleLogin() }
    @objc private func quitAction() { onQuit() }

    // MARK: NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        loginMenuItem.state = isLoginEnabled() ? .on : .off
    }

    func menuDidClose(_ menu: NSMenu) {
        // Clear so the next left-click fires the button action instead of the menu.
        item.menu = nil
    }
}
