// Copyright (c) 2026 AustinSoft.com

@testable import CNPinning_Apple
import Foundation
import Testing

struct URLSessionAssociatedObjectTests {
    @Test func urlSessionAssociatedObjectUnset() {
        let urlSession: URLSession = .init(configuration: .default)
        #expect(urlSession.cnPinningManager == nil)
    }

    @Test func urlSessionAssociatedObjectSetAndRetrieveAndNil() throws {
        let pinningManager = try CNPinningManager(
            configuration: [
                "apple.com": .init(
                    includesSubdomains: true,
                    [
                        .init([
                            .init(.prefixWithNumber, "DigiCert C"),
                            .init(.suffix, ".apple.com"),
                        ]),
                    ]
                ),
                "www.apple.com": .init(
                    includesSubdomains: false,
                    [
                        .init([
                            .init(.prefixWithNumber, "DigiCert C"),
                            .init(.exact, "www.apple.com"),
                        ]),
                    ]
                ),
            ]
        )
        let urlSession: URLSession = .init(configuration: .default)

        urlSession.cnPinningManager = pinningManager
        #expect(urlSession.cnPinningManager === pinningManager)
        urlSession.cnPinningManager = nil
        #expect(urlSession.cnPinningManager == nil)
    }
}
