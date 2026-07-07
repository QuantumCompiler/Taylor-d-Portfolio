//
//  URLSessionHTTPClient.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Net — URLSession-backed HTTPClient.
//

import Foundation

/// The production `HTTPClient`, backed by `URLSession`.
nonisolated struct URLSessionHTTPClient: HTTPClient {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(_ url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw HTTPError.nonHTTPResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw HTTPError.status(code: http.statusCode, body: data)
        }
        return data
    }
}
