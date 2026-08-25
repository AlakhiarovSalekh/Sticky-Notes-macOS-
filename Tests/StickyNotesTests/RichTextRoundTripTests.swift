import XCTest
import AppKit
@testable import StickyNotes

/// Verifies the E4 risk from the plan: bold/italic/underline/strikethrough
/// survive the NSAttributedString -> RTF -> NSAttributedString round-trip used
/// for persistence.
final class RichTextRoundTripTests: XCTestCase {

    private func roundTrip(_ attr: NSAttributedString) -> NSAttributedString {
        let data = Note.rtfData(from: attr)
        XCTAssertFalse(data.isEmpty, "RTF serialization produced no data")
        return Note.attributedString(fromRTF: data)
    }

    func testBoldItalicSurvive() {
        let fm = NSFontManager.shared
        var font = NSFont.systemFont(ofSize: 16)
        font = fm.convert(font, toHaveTrait: .boldFontMask)
        font = fm.convert(font, toHaveTrait: .italicFontMask)

        let attr = NSAttributedString(string: "Hi", attributes: [.font: font])
        let out = roundTrip(attr)

        let outFont = out.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
        let traits = outFont.map { fm.traits(of: $0) } ?? []
        XCTAssertTrue(traits.contains(.boldFontMask), "bold lost in RTF")
        XCTAssertTrue(traits.contains(.italicFontMask), "italic lost in RTF")
    }

    func testUnderlineSurvives() {
        let attr = NSAttributedString(string: "Hi", attributes: [
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ])
        let out = roundTrip(attr)
        let value = out.attribute(.underlineStyle, at: 0, effectiveRange: nil) as? Int
        XCTAssertEqual(value, NSUnderlineStyle.single.rawValue, "underline lost in RTF")
    }

    func testStrikethroughSurvives() {
        // The specifically flagged risk.
        let attr = NSAttributedString(string: "Hi", attributes: [
            .strikethroughStyle: NSUnderlineStyle.single.rawValue
        ])
        let out = roundTrip(attr)
        let value = out.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) as? Int
        XCTAssertEqual(value, NSUnderlineStyle.single.rawValue, "strikethrough lost in RTF")
    }

    func testPlainTextPreserved() {
        let attr = NSAttributedString(string: "Buy milk\nCall mom")
        let out = roundTrip(attr)
        XCTAssertEqual(out.string, "Buy milk\nCall mom")
    }

    func testNotesFileCodableRoundTrip() throws {
        let note = Note(rtfData: Data([1, 2, 3]),
                        plainText: "x",
                        themeId: .windows11,
                        colorId: .pink,
                        frame: StoredRect(x: 10, y: 20, width: 240, height: 220),
                        isAlwaysOnTop: true)
        let file = NotesFile(schemaVersion: 1, notes: [note])

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(file)
        let back = try decoder.decode(NotesFile.self, from: data)

        XCTAssertEqual(back.notes.count, 1)
        XCTAssertEqual(back.notes[0].themeId, .windows11)
        XCTAssertEqual(back.notes[0].colorId, .pink)
        XCTAssertEqual(back.notes[0].frame, note.frame)
        XCTAssertEqual(back.notes[0].isAlwaysOnTop, true)
        XCTAssertEqual(back.notes[0].rtfData, Data([1, 2, 3]))
    }

    func testLegacyFileDecodesWithFallbacks() throws {
        // A note saved before themes (only `colorId`, no `themeId`) must still
        // load: themeId -> default, colorId -> the stored value.
        let legacy = """
        { "schemaVersion": 1, "notes": [{
            "id": "00000000-0000-0000-0000-000000000001",
            "rtfData": "", "plainText": "old",
            "colorId": "blue",
            "frame": { "x": 0, "y": 0, "width": 240, "height": 220 },
            "isAlwaysOnTop": false,
            "createdAt": "2024-01-01T00:00:00Z",
            "modifiedAt": "2024-01-01T00:00:00Z"
        }] }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let file = try decoder.decode(NotesFile.self, from: legacy)

        XCTAssertEqual(file.notes.count, 1)
        XCTAssertEqual(file.notes[0].themeId, Constants.defaultTheme)
        XCTAssertEqual(file.notes[0].colorId, .blue)
        XCTAssertEqual(file.notes[0].plainText, "old")
    }
}
