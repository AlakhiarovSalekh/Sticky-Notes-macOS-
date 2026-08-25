import AppKit

/// Persisted rectangle. AppKit coordinates (origin bottom-left).
/// Stored explicitly to avoid relying on CGRect Codable quirks.
struct StoredRect: Codable, Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }

    init(_ rect: NSRect) {
        x = Double(rect.origin.x)
        y = Double(rect.origin.y)
        width = Double(rect.size.width)
        height = Double(rect.size.height)
    }

    var cgRect: NSRect {
        NSRect(x: x, y: y, width: width, height: height)
    }
}

/// One sticky note. Rich text is stored as RTF data; `plainText` is a derived
/// cache used for the "has text?" delete check and future search.
struct Note: Codable, Identifiable, Equatable {
    var id: UUID
    var rtfData: Data
    var plainText: String
    var themeId: NoteTheme
    var colorId: NoteColor
    var frame: StoredRect
    var isAlwaysOnTop: Bool
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(),
         rtfData: Data = Data(),
         plainText: String = "",
         themeId: NoteTheme = Constants.defaultTheme,
         colorId: NoteColor = Constants.defaultColor,
         frame: StoredRect,
         isAlwaysOnTop: Bool = false,
         createdAt: Date = Date(),
         modifiedAt: Date = Date()) {
        self.id = id
        self.rtfData = rtfData
        self.plainText = plainText
        self.themeId = themeId
        self.colorId = colorId
        self.frame = frame
        self.isAlwaysOnTop = isAlwaysOnTop
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    // Tolerant decoding: a missing/unknown `themeId` or `colorId` falls back to
    // defaults instead of failing (covers files from earlier versions).
    enum CodingKeys: String, CodingKey {
        case id, rtfData, plainText, themeId, colorId, frame, isAlwaysOnTop, createdAt, modifiedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        rtfData = try c.decodeIfPresent(Data.self, forKey: .rtfData) ?? Data()
        plainText = try c.decodeIfPresent(String.self, forKey: .plainText) ?? ""
        themeId = (try? c.decodeIfPresent(NoteTheme.self, forKey: .themeId)) ?? Constants.defaultTheme
        colorId = (try? c.decodeIfPresent(NoteColor.self, forKey: .colorId)) ?? Constants.defaultColor
        frame = try c.decode(StoredRect.self, forKey: .frame)
        isAlwaysOnTop = try c.decodeIfPresent(Bool.self, forKey: .isAlwaysOnTop) ?? false
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        modifiedAt = try c.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? Date()
    }

    var isEmpty: Bool {
        plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: Rich-text bridging

    /// Decode the stored RTF into an attributed string (empty string if none).
    func attributedString() -> NSAttributedString {
        Note.attributedString(fromRTF: rtfData)
    }

    static func attributedString(fromRTF data: Data) -> NSAttributedString {
        guard !data.isEmpty,
              let s = NSAttributedString(rtf: data, documentAttributes: nil) else {
            return NSAttributedString(string: "")
        }
        return s
    }

    /// Serialize an attributed string to RTF data for storage.
    static func rtfData(from attributed: NSAttributedString) -> Data {
        let range = NSRange(location: 0, length: attributed.length)
        return attributed.rtf(from: range,
                              documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]) ?? Data()
    }
}

/// On-disk JSON envelope. Wrapping the array lets us version the format.
struct NotesFile: Codable {
    var schemaVersion: Int
    var notes: [Note]
}
