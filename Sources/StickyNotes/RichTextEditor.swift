import SwiftUI
import AppKit

/// SwiftUI wrapper around `NoteTextView` (inside an NSScrollView).
/// Content is set ONCE from `model.initialText`; thereafter the NSTextView is
/// the source of truth and changes flow out via the coordinator. This avoids
/// the classic representable update loop / cursor-jump.
struct RichTextEditor: NSViewRepresentable {
    @ObservedObject var model: NoteViewModel
    let style: ThemeStyle

    private var textColor: NSColor { style.textColor }

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NoteTextView()
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.textContainerInset = Constants.textInset
        textView.font = style.font
        textView.textColor = textColor
        textView.insertionPointColor = textColor
        textView.typingAttributes = [
            .font: style.font,
            .foregroundColor: textColor
        ]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true

        if model.initialText.length > 0 {
            textView.textStorage?.setAttributedString(model.initialText)
            // Ensure restored text honors the theme's default color where none set.
            textView.textColor = textColor
        }

        // Focus bridge used by the controller when presenting a new note.
        model.requestFocus = { [weak textView] in
            guard let tv = textView else { return }
            tv.window?.makeFirstResponder(tv)
        }

        let scroll = NSScrollView()
        scroll.documentView = textView
        scroll.drawsBackground = false
        scroll.backgroundColor = .clear
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        return scroll
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let tv = scrollView.documentView as? NSTextView else { return }
        // React to theme changes: refresh default text color (not per-run fonts,
        // so user formatting survives a theme switch).
        tv.textColor = textColor
        tv.insertionPointColor = textColor
        var typing = tv.typingAttributes
        typing[.foregroundColor] = textColor
        if typing[.font] == nil { typing[.font] = style.font }
        tv.typingAttributes = typing
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        let model: NoteViewModel
        init(model: NoteViewModel) { self.model = model }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            model.textChanged(tv.attributedString())
        }
    }
}
