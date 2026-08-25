import XCTest
import AppKit
@testable import StickyNotes

final class WindowFrameSanitizerTests: XCTestCase {

    private let screen = NSRect(x: 0, y: 0, width: 1440, height: 900)

    func testOnScreenFrameUnchanged() {
        let frame = NSRect(x: 100, y: 100, width: 240, height: 220)
        let result = WindowFrameSanitizer.sanitize(frame, screenVisibleFrames: [screen])
        XCTAssertEqual(result, frame)
    }

    func testFullyOffScreenFrameRecentered() {
        // Way off to the right of a now-disconnected monitor.
        let frame = NSRect(x: 5000, y: 4000, width: 240, height: 220)
        let result = WindowFrameSanitizer.sanitize(frame, screenVisibleFrames: [screen])
        XCTAssertEqual(result.width, 240)
        XCTAssertEqual(result.height, 220)
        // Centered on the screen.
        XCTAssertEqual(result.midX, screen.midX, accuracy: 0.5)
        XCTAssertEqual(result.midY, screen.midY, accuracy: 0.5)
    }

    func testSliverVisibleIsRecentered() {
        // Only a few pixels poke onto the screen -> treated as off-screen.
        let frame = NSRect(x: 1435, y: 100, width: 240, height: 220)
        let result = WindowFrameSanitizer.sanitize(frame, screenVisibleFrames: [screen])
        XCTAssertEqual(result.midX, screen.midX, accuracy: 0.5)
    }

    func testNoScreensPassesThrough() {
        let frame = NSRect(x: 5000, y: 4000, width: 240, height: 220)
        let result = WindowFrameSanitizer.sanitize(frame, screenVisibleFrames: [])
        XCTAssertEqual(result, frame)
    }

    func testDefaultFrameIsOnScreen() {
        let f = WindowFrameSanitizer.defaultFrame(noteCount: 0, primaryVisibleFrame: screen)
        XCTAssertTrue(screen.intersection(f).width * screen.intersection(f).height >= Constants.minVisibleArea)
    }
}
