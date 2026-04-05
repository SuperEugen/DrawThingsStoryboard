import Foundation

// MARK: - FountainParser
/// Parses Fountain (.fountain) screenplay files into the storyboard data model.
/// Phase 1: Structural import only (Act / Sequence / Scene).
///
/// Mapping:
///   # Heading    → ActEntry
///   ## Heading   → SequenceEntry
///   ### Heading  → SceneEntry (with one empty PanelEntry)
///
/// Ignores Beat metadata blocks (/* ... */) and blank lines.

enum FountainParser {

    /// Parse a Fountain file's text content into acts.
    static func parse(_ text: String) -> [ActEntry] {
        // Strip Beat metadata block
        let cleaned = stripBeatMetadata(text)

        var acts: [ActEntry] = []
        var currentAct: ActEntry?
        var currentSequence: SequenceEntry?

        for rawLine in cleaned.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }

            if line.hasPrefix("### ") {
                // Scene
                let sceneName = String(line.dropFirst(4)).trimmingCharacters(in: .whitespaces)
                guard !sceneName.isEmpty else { continue }
                let panel = PanelEntry(
                    panelID: UUID().uuidString,
                    name: sceneName,
                    duration: 30
                )
                let scene = SceneEntry(name: sceneName, panels: [panel])
                if currentSequence != nil {
                    currentSequence!.scenes.append(scene)
                } else {
                    // Scene without a sequence — create an implicit one
                    currentSequence = SequenceEntry(name: "Sequence", scenes: [scene])
                }

            } else if line.hasPrefix("## ") {
                // Sequence — flush previous sequence into current act
                flushSequence(&currentSequence, into: &currentAct)
                let seqName = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                guard !seqName.isEmpty else { continue }
                currentSequence = SequenceEntry(name: seqName, scenes: [])

            } else if line.hasPrefix("# ") {
                // Act — flush previous sequence + act
                flushSequence(&currentSequence, into: &currentAct)
                flushAct(&currentAct, into: &acts)
                let actName = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                guard !actName.isEmpty else { continue }
                currentAct = ActEntry(name: actName, sequences: [])

            }
            // Other lines are ignored for now (dialogue, action, etc.)
        }

        // Flush remaining
        flushSequence(&currentSequence, into: &currentAct)
        flushAct(&currentAct, into: &acts)

        return acts
    }

    /// Parse a Fountain file from a URL.
    static func parse(contentsOf url: URL) throws -> [ActEntry] {
        let text = try String(contentsOf: url, encoding: .utf8)
        return parse(text)
    }

    /// Derive a storyboard name from a file URL (filename without extension).
    static func storyboardName(from url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
    }

    // MARK: - Private helpers

    private static func flushSequence(_ seq: inout SequenceEntry?, into act: inout ActEntry?) {
        guard let s = seq, !s.scenes.isEmpty else {
            seq = nil
            return
        }
        if act == nil {
            act = ActEntry(name: "Act", sequences: [])
        }
        act!.sequences.append(s)
        seq = nil
    }

    private static func flushAct(_ act: inout ActEntry?, into acts: inout [ActEntry]) {
        guard let a = act, !a.sequences.isEmpty else {
            act = nil
            return
        }
        acts.append(a)
        act = nil
    }

    private static func stripBeatMetadata(_ text: String) -> String {
        // Remove /* ... */ blocks (Beat metadata)
        guard let startRange = text.range(of: "/*") else { return text }
        if let endRange = text.range(of: "*/", range: startRange.upperBound..<text.endIndex) {
            var cleaned = text
            cleaned.removeSubrange(startRange.lowerBound...endRange.upperBound)
            return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // No closing */ — strip from /* to end
        return String(text[text.startIndex..<startRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
