import AppKit

/// The single source of truth for note data + disk persistence.
/// No UI knowledge. Debounced autosave with an immediate-flush path for quit.
@MainActor
final class NoteStore {

    private(set) var notes: [Note] = []

    private let directoryURL: URL
    private let fileURL: URL
    private let backupURL: URL

    private var saveWorkItem: DispatchWorkItem?

    init() {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        directoryURL = base.appendingPathComponent(Constants.appFolderName, isDirectory: true)
        fileURL = directoryURL.appendingPathComponent(Constants.notesFileName)
        backupURL = directoryURL.appendingPathComponent(Constants.backupFileName)
    }

    // MARK: Loading

    /// Read notes from disk. Falls back to the backup if the main file is corrupt.
    func load() {
        notes = readNotes(at: fileURL) ?? readNotes(at: backupURL) ?? []
    }

    private func readNotes(at url: URL) -> [Note]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let file = try? JSONDecoder.notes.decode(NotesFile.self, from: data) else { return nil }
        return file.notes
    }

    // MARK: Mutations

    /// Insert or replace a note by id, then schedule a save.
    func upsert(_ note: Note) {
        if let i = notes.firstIndex(where: { $0.id == note.id }) {
            notes[i] = note
        } else {
            notes.append(note)
        }
        scheduleSave()
    }

    func delete(id: UUID) {
        notes.removeAll { $0.id == id }
        scheduleSave()
    }

    func note(id: UUID) -> Note? {
        notes.first { $0.id == id }
    }

    // MARK: Saving

    private func scheduleSave() {
        saveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.writeToDisk()
        }
        saveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.autosaveDebounce, execute: work)
    }

    /// Cancel any pending debounce and write synchronously (call on quit/resign).
    func saveImmediately() {
        saveWorkItem?.cancel()
        saveWorkItem = nil
        writeToDisk()
    }

    private func writeToDisk() {
        let file = NotesFile(schemaVersion: Constants.schemaVersion, notes: notes)
        guard let data = try? JSONEncoder.notes.encode(file) else { return }
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            // Keep a cheap backup of the previous good file before overwriting.
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try? FileManager.default.removeItem(at: backupURL)
                try? FileManager.default.copyItem(at: fileURL, to: backupURL)
            }
            try data.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("StickyNotes: failed to save notes: \(error)")
        }
    }
}

private extension JSONEncoder {
    static var notes: JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }
}

private extension JSONDecoder {
    static var notes: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
