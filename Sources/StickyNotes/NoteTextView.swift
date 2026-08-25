import AppKit

/// NSTextView subclass implementing the Win7 formatting shortcuts:
/// ⌘B bold, ⌘I italic, ⌘U underline, ⌘T strikethrough.
/// Toggles apply to the selection, or to typing attributes when there is none.
final class NoteTextView: NSTextView {

    override var acceptsFirstResponder: Bool { true }

    /// Intercept the format shortcuts before the system (notably ⌘T, which
    /// macOS otherwise routes to the Fonts panel).
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags == .command, let chars = event.charactersIgnoringModifiers?.lowercased() {
            switch chars {
            case "b": toggleBoldface(self); return true
            case "i": toggleItalics(self); return true
            case "u": toggleUnderline(self); return true
            case "t": formatStrikethrough(self); return true
            default: break
            }
        }
        return super.performKeyEquivalent(with: event)
    }

    // MARK: Actions (also reachable from the Format menu via the responder chain)

    @objc func toggleBoldface(_ sender: Any?) { toggleFontTrait(.boldFontMask) }
    @objc func toggleItalics(_ sender: Any?) { toggleFontTrait(.italicFontMask) }
    @objc func toggleUnderline(_ sender: Any?) {
        toggleIntAttribute(.underlineStyle, onValue: NSUnderlineStyle.single.rawValue)
    }
    @objc func formatStrikethrough(_ sender: Any?) {
        toggleIntAttribute(.strikethroughStyle, onValue: NSUnderlineStyle.single.rawValue)
    }

    // MARK: Paste

    /// Always paste as plain text — drop the source's font/formatting and adopt
    /// the note's current typing attributes (theme font + color). Covers ⌘V,
    /// the Edit menu, and the right-click menu (all route to `paste:`).
    override func paste(_ sender: Any?) {
        pasteAsPlainText(sender)
    }

    // MARK: Implementation

    private func fontAtSelectionStart() -> NSFont {
        let sel = selectedRange()
        if sel.length == 0 {
            return (typingAttributes[.font] as? NSFont) ?? Constants.defaultFont
        }
        if let ts = textStorage, sel.location < ts.length,
           let font = ts.attribute(.font, at: sel.location, effectiveRange: nil) as? NSFont {
            return font
        }
        return Constants.defaultFont
    }

    private func toggleFontTrait(_ trait: NSFontTraitMask) {
        let fm = NSFontManager.shared
        // Decide direction once, from the selection start, so a mixed run
        // resolves to a single consistent state (like every Mac text app).
        let shouldAdd = !fm.traits(of: fontAtSelectionStart()).contains(trait)
        let transform: (NSFont) -> NSFont = { font in
            shouldAdd ? fm.convert(font, toHaveTrait: trait)
                      : fm.convert(font, toNotHaveTrait: trait)
        }

        let sel = selectedRange()
        if sel.length == 0 {
            let cur = (typingAttributes[.font] as? NSFont) ?? Constants.defaultFont
            typingAttributes[.font] = transform(cur)
            return
        }
        guard let ts = textStorage else { return }
        ts.beginEditing()
        ts.enumerateAttribute(.font, in: sel, options: []) { value, range, _ in
            let font = (value as? NSFont) ?? Constants.defaultFont
            ts.addAttribute(.font, value: transform(font), range: range)
        }
        ts.endEditing()
        didChangeText()
    }

    private func toggleIntAttribute(_ key: NSAttributedString.Key, onValue: Int) {
        let sel = selectedRange()
        if sel.length == 0 {
            let cur = (typingAttributes[key] as? Int) ?? 0
            typingAttributes[key] = (cur == 0) ? onValue : 0
            return
        }
        guard let ts = textStorage else { return }
        let curAtStart: Int = {
            guard sel.location < ts.length else { return 0 }
            return (ts.attribute(key, at: sel.location, effectiveRange: nil) as? Int) ?? 0
        }()
        let newValue = (curAtStart == 0) ? onValue : 0
        ts.beginEditing()
        ts.addAttribute(key, value: newValue, range: sel)
        ts.endEditing()
        didChangeText()
    }
}
