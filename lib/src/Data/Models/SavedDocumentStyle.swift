//
//  SavedDocumentStyle.swift
//  Taylor'd Portfolio
//
//  Data · Models — a named, persisted LaTeXStyle the user can reuse (v0.7.0 Milestone D).
//

import Foundation

/// A ``LaTeXStyle`` the user has saved under a name so it can be reused on any export. `id` is
/// assigned at first save and is stable across updates; `createdAt` orders the library (newest
/// first). Styles are **global** — not tied to a job, profile, or generation.
///
/// The library holds **user** styles only. The built-in templates stay in
/// ``LaTeXTemplateRegistry`` (Milestone A) and are never written here; Milestone E's picker shows
/// both lists together.
///
/// Holding an Infrastructure value (`LaTeXStyle`) in a Data model is the legal direction under the
/// layer rule — Data may depend on Infrastructure. The consequence to keep in mind: from here on
/// `LaTeXStyle`'s JSON shape is a **persistence contract**, which is why its decoder is tolerant.
nonisolated struct SavedDocumentStyle: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var name: String
    var style: LaTeXStyle
    var createdAt: Date

    init(id: String, name: String, style: LaTeXStyle, createdAt: Date) {
        self.id = id
        self.name = name
        self.style = style
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, style, createdAt
    }

    /// Decodes so that a record survives a `style` that can't be read **at all** — a blob whose
    /// style isn't even a JSON object (hand-edited, half-written, a future re-encoding). Such a
    /// record still loads as a named, deletable row rather than being dropped by the repository's
    /// best-effort `all()` and stranded in the store as something the UI can neither show nor
    /// remove — `all()` reads `records(ofKind:)`, which hands back blobs *without* their ids, so a
    /// row that fails to decode leaves the list with no id to delete by. (The store can also be
    /// read with `entries(ofKind:)`, which does carry ids; recovering orphans that way would be a
    /// repair path, not a substitute for the record loading in the first place.)
    ///
    /// Field-level drift *inside* a style is handled one layer down by ``LaTeXStyle``'s own
    /// tolerant decoder. This is the outer guard, not a substitute: falling back here replaces
    /// every choice the user made, so it should be reachable only by genuinely malformed data.
    /// Later envelope fields get the `SavedProfile` treatment — `decodeIfPresent(…) ?? default`.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        style = (try? container.decode(LaTeXStyle.self, forKey: .style)) ?? .default
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    /// A friendly default name derived from the style — its template, plus its accent when the
    /// user chose one. Mirrors `GenerationPreset.defaultName(for:)`.
    ///
    /// Kept on the primary declaration rather than an extension: under default-`MainActor`
    /// isolation a `static` added in an extension is re-inferred `@MainActor` and stops being
    /// callable from this `nonisolated` type (see `CLAUDE.md` → Conventions).
    static func defaultName(for style: LaTeXStyle) -> String {
        let template = LaTeXTemplateRegistry.descriptor(for: style).displayName
        switch style.accent {
        case .templateDefault:
            return template
        case let .named(colour):
            return "\(template) · \(colour.displayName)"
        case let .custom(hex):
            guard let hex = LaTeXAccent.normalizedHex(hex) else { return template }
            return "\(template) · #\(hex)"
        }
    }
}
