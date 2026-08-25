import XCTest
@testable import StickyNotes

final class AppRelocatorTests: XCTestCase {

    private let appsDirs = ["/Applications", "/Users/me/Applications", "/System/Applications"]

    func testOffersWhenOutsideApplications() {
        XCTAssertTrue(AppRelocator.shouldOfferMove(
            bundlePath: "/Users/me/Downloads/Sticky Notes.app",
            applicationsDirs: appsDirs, declined: false))
    }

    func testSkipsWhenAlreadyInApplications() {
        XCTAssertFalse(AppRelocator.shouldOfferMove(
            bundlePath: "/Applications/Sticky Notes.app",
            applicationsDirs: appsDirs, declined: false))
    }

    func testSkipsWhenInUserApplications() {
        XCTAssertFalse(AppRelocator.shouldOfferMove(
            bundlePath: "/Users/me/Applications/Sticky Notes.app",
            applicationsDirs: appsDirs, declined: false))
    }

    func testSkipsWhenDeclined() {
        XCTAssertFalse(AppRelocator.shouldOfferMove(
            bundlePath: "/Users/me/Downloads/Sticky Notes.app",
            applicationsDirs: appsDirs, declined: true))
    }

    func testSkipsForBareExecutable() {
        // `swift run` path: not a .app bundle.
        XCTAssertFalse(AppRelocator.shouldOfferMove(
            bundlePath: "/Users/me/stick-notes/.build/debug",
            applicationsDirs: appsDirs, declined: false))
    }

    func testDoesNotFalseMatchSiblingPrefix() {
        // "/ApplicationsX" must not count as inside "/Applications".
        XCTAssertTrue(AppRelocator.shouldOfferMove(
            bundlePath: "/ApplicationsX/Sticky Notes.app",
            applicationsDirs: ["/Applications"], declined: false))
    }
}
