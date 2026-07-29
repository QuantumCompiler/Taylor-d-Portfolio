//
//  KeychainStore.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Store — KeyValueStore backed by the macOS Keychain (for secrets).
//

import Foundation
import Security

/// A `KeyValueStore` backed by the macOS Keychain, for **secrets** (API keys) that must
/// not sit in the `UserDefaults` plist — the keychain option the `KeyValueStore` port
/// comment anticipates (Milestone D). Non-secret preferences stay in ``UserDefaultsStore``.
///
/// Each entry is a **generic password** item namespaced by `service`, with the caller's
/// `key` as the account. Uses the legacy (file-based) keychain — not the data-protection
/// keychain — so the **unsandboxed** app target works without a keychain-access-group
/// entitlement (the data-protection keychain would return `errSecMissingEntitlement`).
///
/// The `KeyValueStore` surface is non-throwing (like `UserDefaultsStore`): read/write
/// failures collapse to `nil` / no-op. The throwing ``readData(forKey:)`` /
/// ``writeData(_:forKey:)`` underneath surface the real `OSStatus` for tests and for
/// callers that need to distinguish "absent" from "keychain unavailable".
nonisolated struct KeychainStore: KeyValueStore {
    /// Namespaces this store's items (`kSecAttrService`), so several logical stores can
    /// share the keychain without colliding. Defaults to the app's credential namespace.
    let service: String

    init(service: String = "com.veritum.taylordportfolio.credentials") {
        self.service = service
    }

    // MARK: KeyValueStore (non-throwing port surface)

    func data(forKey key: String) -> Data? {
        try? readData(forKey: key)
    }

    func setData(_ data: Data?, forKey key: String) {
        try? writeData(data, forKey: key)
    }

    // MARK: Throwing API (surfaces OSStatus)

    /// The data stored for `key`, or `nil` if there's no such item. Throws
    /// ``KeychainError/unexpectedStatus(_:)`` on any status other than success/not-found.
    func readData(forKey key: String) throws -> Data? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Stores `data` for `key` (insert or update), or removes the entry when `data` is
    /// `nil`. Throws ``KeychainError/unexpectedStatus(_:)`` on failure.
    func writeData(_ data: Data?, forKey key: String) throws {
        guard let data else {
            try delete(forKey: key)
            return
        }

        // Update in place if the item exists; otherwise add it. (Update-or-add keeps a
        // single item per key without a delete/add race.)
        let updateStatus = SecItemUpdate(
            baseQuery(forKey: key) as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var attributes = baseQuery(forKey: key)
            attributes[kSecValueData as String] = data
            // Ignored by the legacy keychain, honoured by the data-protection keychain —
            // set for forward-compatibility.
            attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            let addStatus = SecItemAdd(attributes as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(addStatus)
            }
        default:
            throw KeychainError.unexpectedStatus(updateStatus)
        }
    }

    /// Removes every item under this store's `service`. Convenience for tests / a full reset.
    func clear() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        // The legacy (file-based) macOS keychain deletes only **one** matching item per
        // `SecItemDelete` call, so loop until nothing matches — otherwise a multi-item
        // service is left partially populated.
        while true {
            let status = SecItemDelete(query as CFDictionary)
            if status == errSecItemNotFound { return }
            guard status == errSecSuccess else {
                throw KeychainError.unexpectedStatus(status)
            }
        }
    }

    // MARK: Helpers

    private func delete(forKey key: String) throws {
        let status = SecItemDelete(baseQuery(forKey: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private func baseQuery(forKey key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}

/// A keychain operation returned a non-success `OSStatus`.
enum KeychainError: Error, Equatable {
    case unexpectedStatus(OSStatus)

    /// Whether the status reflects an **environment** limitation (missing entitlement,
    /// keychain unavailable, or interaction not allowed) rather than a caller bug — used
    /// to skip keychain round-trip tests on hosts (e.g. CI) that can't use the keychain.
    var isEnvironmentUnavailable: Bool {
        guard case let .unexpectedStatus(status) = self else { return false }
        return status == errSecMissingEntitlement
            || status == errSecNotAvailable
            || status == errSecInteractionNotAllowed
    }
}
