//
//  URLSessionHTTPClientTests.swift
//  Taylor'd PortfolioTests
//
//  Tests · Infrastructure · Net — status handling via a stubbed URLProtocol.
//

import Testing
import Foundation
@testable import Taylor_d_Portfolio

/// Intercepts URLSession requests and replays a canned status + body.
private final class URLProtocolStub: URLProtocol {
    nonisolated(unsafe) static var stub: (status: Int, data: Data)?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let stub = Self.stub {
            let response = HTTPURLResponse(
                url: request.url!, statusCode: stub.status, httpVersion: nil, headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: stub.data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite("URLSessionHTTPClient", .serialized)
struct URLSessionHTTPClientTests {

    private func makeClient() -> URLSessionHTTPClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        return URLSessionHTTPClient(session: URLSession(configuration: config))
    }

    private let url = URL(string: "https://example.com/data")!

    @Test func returnsBodyOnSuccess() async throws {
        URLProtocolStub.stub = (200, Data("hello".utf8))
        defer { URLProtocolStub.stub = nil }

        let data = try await makeClient().get(url)
        #expect(String(data: data, encoding: .utf8) == "hello")
    }

    @Test func throwsStatusErrorOnNon2xx() async {
        URLProtocolStub.stub = (404, Data())
        defer { URLProtocolStub.stub = nil }

        await #expect(throws: HTTPError.self) {
            _ = try await makeClient().get(url)
        }
    }
}
