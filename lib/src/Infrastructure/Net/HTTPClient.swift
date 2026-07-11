//
//  HTTPClient.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Net — the raw HTTP GET port.
//

import Foundation

/// A minimal HTTP capability, declared in Infrastructure so Data-layer gateways can
/// depend on it and be tested against a stub.
protocol HTTPClient: Sendable {
    /// Performs a GET for `url`, returning the response body. Throws on a non-2xx status.
    func get(_ url: URL) async throws -> Data

    /// Performs a GET for `url` with request `headers` (e.g. a browser-like `User-Agent`
    /// so job boards that reject non-browser clients still answer). Defaults to ignoring
    /// the headers and calling ``get(_:)``, so existing stubs need no change.
    func get(_ url: URL, headers: [String: String]) async throws -> Data
}

extension HTTPClient {
    func get(_ url: URL, headers: [String: String]) async throws -> Data {
        try await get(url)
    }
}

/// Errors raised by an `HTTPClient`.
enum HTTPError: Error, Equatable {
    /// The response wasn't an HTTP response.
    case nonHTTPResponse
    /// The server returned a non-2xx status; `body` is the (possibly empty) payload.
    case status(code: Int, body: Data)
}
