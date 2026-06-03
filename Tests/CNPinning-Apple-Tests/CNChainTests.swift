// Copyright (c) 2026 AustinSoft.com

@testable import CNPinning_Apple
import Foundation
import Testing

// MARK: CNChain Tests

struct CNChainTests {
    @Test func cnChainDecode() throws {
        let chain = try CNChain(entry: [
            [
                "type": "prefixWithNumber",
                "value": "DigiCert C",
            ],
            [
                "type": "exact",
                "value": "www.apple.com",
            ],
        ])
        #expect(chain.links == [
            .init(.exact, "www.apple.com"),
            .init(.prefixWithNumber, "DigiCert C"),
        ])
    }

    @Test func cnChainInit() {
        let chain = CNChain(
            [
                .init(.prefixWithNumber, "DigiCert C"),
                .init(.exact, "www.apple.com"),
            ]
        )
        #expect(chain.links == [
            .init(.exact, "www.apple.com"),
            .init(.prefixWithNumber, "DigiCert C"),
        ])
    }

    @Test func cnChainMatches() {
        let chain = CNChain(
            [
                .init(.exact, "a"),
                .init(.prefix, "b"),
            ]
        )
        #expect(chain.matches(["b", "a"]))
    }

    @Test func cnChainDoesntMatchByCount() {
        let chain = CNChain(
            [
                .init(.exact, "a"),
                .init(.prefix, "b"),
            ]
        )
        #expect(!chain.matches(["b"]))
    }

    @Test func cnChainDescription() {
        let chain = CNChain(
            [
                .init(.exact, "a"),
                .init(.prefix, "b"),
            ]
        )
        #expect(chain.description == "CNChain([CNChainLink(.exact, \"a\"), CNChainLink(.prefix, \"b\")])")
    }
}
