import XCTest
import AppKit
@testable import StickyNotes

final class ThemeStyleTests: XCTestCase {

    func testEveryThemeAndColorProducesValidStyle() {
        for theme in NoteTheme.allCases {
            for color in NoteColor.allCases {
                let style = ThemeStyle.style(for: theme, color: color)
                XCTAssertGreaterThanOrEqual(style.cornerRadius, 0, "\(theme)/\(color) radius")
                XCTAssertGreaterThan(style.caption.height, 0, "\(theme)/\(color) caption height")
                XCTAssertGreaterThan(style.font.pointSize, 0, "\(theme)/\(color) font size")
            }
        }
    }

    func testColorChangesSolidBackground() {
        // Same theme, different colors -> different body fill.
        func solidBG(_ color: NoteColor) -> NSColor? {
            if case .solid(let c) = ThemeStyle.style(for: .windows7, color: color).body { return c }
            return nil
        }
        XCTAssertNotEqual(solidBG(.yellow), solidBG(.blue))
        XCTAssertNotEqual(solidBG(.green), solidBG(.pink))
    }

    func testAllColorsHaveDistinctDisplayNames() {
        let names = Set(NoteColor.allCases.map { $0.displayName })
        XCTAssertEqual(names.count, NoteColor.allCases.count)
    }

    func testAllThemesHaveDistinctDisplayNames() {
        let names = Set(NoteTheme.allCases.map { $0.displayName })
        XCTAssertEqual(names.count, NoteTheme.allCases.count)
    }

    func testUbuntuPutsButtonsOnLeft() {
        XCTAssertEqual(ThemeStyle.style(for: .ubuntu1404).caption.buttonSide, .leading)
        XCTAssertEqual(ThemeStyle.style(for: .windows7).caption.buttonSide, .trailing)
    }

    func testWindows8IsSquare() {
        XCTAssertEqual(ThemeStyle.style(for: .windows8).cornerRadius, 0)
    }

    func testPaperThemesAreHoverOnly() {
        XCTAssertTrue(ThemeStyle.style(for: .windows7).caption.hoverOnly)
        XCTAssertTrue(ThemeStyle.style(for: .osxMavericks).caption.hoverOnly)
        XCTAssertFalse(ThemeStyle.style(for: .windows11).caption.hoverOnly)
    }

    func testGlassUsesVibrancy() {
        if case .vibrancy = ThemeStyle.style(for: .macGlass).body {
            // ok
        } else {
            XCTFail("Glass theme should use a vibrancy background")
        }
    }
}
