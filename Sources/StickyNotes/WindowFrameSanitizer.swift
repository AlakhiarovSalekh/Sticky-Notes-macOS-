import AppKit

/// Pure geometry helper (no UI state) so it is unit-testable.
/// Guards against notes restored off-screen after a monitor is unplugged or
/// the resolution changes.
enum WindowFrameSanitizer {

    /// Return a frame guaranteed to be substantially visible on one of the
    /// given screens. If the saved frame is effectively off-screen, recenter a
    /// same-sized frame on the primary (first) screen.
    ///
    /// - Parameters:
    ///   - frame: the saved note frame (AppKit coords).
    ///   - screenVisibleFrames: `visibleFrame` of each available screen.
    ///   - minVisibleArea: minimum on-screen intersection area to accept as-is.
    static func sanitize(_ frame: NSRect,
                         screenVisibleFrames: [NSRect],
                         minVisibleArea: CGFloat = Constants.minVisibleArea) -> NSRect {

        guard let primary = screenVisibleFrames.first else {
            // No screens reported (headless / tests): pass frame through.
            return frame
        }

        let bestVisible = screenVisibleFrames
            .map { $0.intersection(frame) }
            .filter { !$0.isNull && !$0.isEmpty }
            .map { $0.width * $0.height }
            .max() ?? 0

        if bestVisible >= minVisibleArea {
            return frame
        }

        // Off-screen: keep size (clamped to the primary screen) and recenter.
        let w = min(frame.width, primary.width)
        let h = min(frame.height, primary.height)
        let x = primary.midX - w / 2
        let y = primary.midY - h / 2
        return NSRect(x: x, y: y, width: w, height: h)
    }

    /// A cascaded default frame for a brand-new note on the primary screen.
    static func defaultFrame(noteCount: Int,
                             size: NSSize = Constants.defaultNoteSize,
                             primaryVisibleFrame: NSRect) -> NSRect {
        // Cascade from the upper-left-ish area, wrapping so we never march off-screen.
        let step = Constants.cascadeOffset
        let wrap = 8
        let i = CGFloat(noteCount % wrap)
        let baseX = primaryVisibleFrame.minX + 60 + i * step
        // AppKit origin is bottom-left; start high (near top) and move down.
        let baseY = primaryVisibleFrame.maxY - size.height - 60 - i * step
        return NSRect(x: baseX, y: baseY, width: size.width, height: size.height)
    }
}
