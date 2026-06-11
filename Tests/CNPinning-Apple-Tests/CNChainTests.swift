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
        try #expect(chain.links == [
            .init(.exact, "www.apple.com"),
            .init(.prefixWithNumber, "DigiCert C"),
        ])
    }

    @Test func cnChainInit() throws {
        let chain = try CNChain(
            [
                .init(.prefixWithNumber, "DigiCert C"),
                .init(.exact, "www.apple.com"),
            ]
        )
        try #expect(chain.links == [
            .init(.exact, "www.apple.com"),
            .init(.prefixWithNumber, "DigiCert C"),
        ])
    }

    @Test func cnChainMatches() throws {
        let chain = try CNChain(
            [
                .init(.exact, "a"),
                .init(.prefix, "b"),
            ]
        )
        #expect(chain.matches(["b", "a"]))
    }

    @Test func cnChainDoesntMatchByCount() throws {
        let chain = try CNChain(
            [
                .init(.exact, "a"),
                .init(.prefix, "b"),
            ]
        )
        #expect(!chain.matches(["b"]))
    }

    @Test func cnChainDescription() throws {
        let chain = try CNChain(
            [
                .init(.exact, "a"),
                .init(.prefix, "b"),
            ]
        )
        #expect(chain.description == "CNChain([CNChainLink(.exact, \"a\"), CNChainLink(.prefix, \"b\")])")
    }
}
