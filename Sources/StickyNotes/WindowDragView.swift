import SwiftUI
import AppKit

/// A transparent NSView that drags its window on mouse-down. Placed behind the
/// strip buttons so the top strip is a reliable drag handle even though the
/// note is borderless. (Body dragging is also enabled via
/// `isMovableByWindowBackground`.)
struct WindowDragView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { DragNSView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    final class DragNSView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    }
}
