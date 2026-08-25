import AppKit

/// Borderless, resizable panel hosting one note. Overrides key/main so the
/// embedded text view can receive input despite having no title bar.
final class NotePanel: NSPanel {

    init(contentRect: NSRect) {
        super.init(contentRect: contentRect,
                   styleMask: [.borderless, .resizable],
                   backing: .buffered,
                   defer: false)

        isOpaque = false
        backgroundColor = .clear           // SwiftUI paints the note; corners stay transparent
        hasShadow = true                   // system shadow follows the rounded opaque content
        isMovableByWindowBackground = true // drag by the body
        level = .normal                    // Win7: ordinary window, not always-on-top
        hidesOnDeactivate = false          // notes stay visible when app loses focus
        becomesKeyOnlyIfNeeded = false
        isFloatingPanel = false
        isReleasedWhenClosed = false       // controller owns lifecycle
        minSize = Constants.minNoteSize
        collectionBehavior.insert(.fullScreenAuxiliary)
        animationBehavior = .utilityWindow
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
