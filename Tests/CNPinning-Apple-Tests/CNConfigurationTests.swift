// Copyright (c) 2026 AustinSoft.com

@testable import CNPinning_Apple
import Foundation
import Testing

// MARK: CNConfiguration Tests

struct CNConfigurationTests {
    @Test func cnConfigurationDecode() throws {
        let configuration = try CNConfiguration(
            entry: [
                "includesSubdomains": false,
                "chainSet": [
                    [
                        [
                            "type": "prefixWithNumber",
                            "value": "DigiCert C",
                        ],
                        [
                            "type": "exact",
                            "value": "www.apple.com",
                        ],
                    ],
                    [
                        [
                            "type": "exact",
                            "value": "a",
                        ],
                        [
                            "type": "exact",
                            "value": "b",
                        ],
                    ],
                ],
            ]
        )
        #expect(configuration.description == "CNConfiguration(includesSubdomains: false, [CNChain([CNChainLink(.prefixWithNumber, \"DigiCert C\"), CNChainLink(.exact, \"www.apple.com\")]), CNChain([CNChainLink(.exact, \"a\"), CNChainLink(.exact, \"b\")])])")
        #expect(configuration.matches(["www.apple.com", "DigiCert C4"]))
        #expect(!configuration.matches(["foo.www.apple.com", "DigiCert C4"]))
        #expect(!configuration.matches(["foo.www.apple.com", "DigiCert CA"]))
        #expect(configuration.matches(["b", "a"]))
    }

    @Test func cnConfigurationInit() throws {
        let configuration = try CNConfiguration(
            includesSubdomains: true,
            [
                .init([
                    .init(.prefixWithNumber, "DigiCert C"),
                    .init(.exact, "www.apple.com"),
                ]),
                .init([
                    .init(.exact, "a"),
                    .init(.exact, "b"),
                ]),
            ]
        )
        #expect(configuration.description == "CNConfiguration(includesSubdomains: true, [CNChain([CNChainLink(.prefixWithNumber, \"DigiCert C\"), CNChainLink(.exact, \"www.apple.com\")]), CNChain([CNChainLink(.exact, \"a\"), CNChainLink(.exact, \"b\")])])")
        #expect(configuration.matches(["www.apple.com", "DigiCert C4"]))
        #expect(!configuration.matches(["foo.www.apple.com", "DigiCert C4"]))
        #expect(!configuration.matches(["foo.www.apple.com", "DigiCert CA"]))
        #expect(configuration.matches(["b", "a"]))
    }

    @Test func cnConfigurationInitFailNoSubdomain() throws {
        #expect(throws: CNParseError.missingValue("includesSubdomains")) {
            _ = try CNConfiguration(
                entry: [
                    "chainSet": [
                        [
                            [
                                "type": "prefixWithNumber",
                                "value": "DigiCert C",
                            ],
                            [
                                "type": "exact",
                                "value": "www.apple.com",
                            ],
                        ],
                        [
                            [
                                "type": "exact",
                                "value": "a",
                            ],
                            [
                                "type": "exact",
                                "value": "b",
                            ],
                        ],
                    ],
                ]
            )
        }
    }

    @Test func cnConfigurationInitFailNoChains() throws {
        #expect(throws: CNParseError.missingValue("chainSet")) {
            _ = try CNConfiguration(
                entry: [
                    "includesSubdomains": true,
                ]
            )
        }
    }

    @Test func cnConfigurationInitFailEmptyChain() throws {
        #expect(throws: CNParseError.noChainsDefined) {
            _ = try CNConfiguration(
                entry: [
                    "includesSubdomains": true,
                    "chainSet": [],
                ]
            )
        }
    }

    @Test func cnConfigurationInitFailDuplicateChain() throws {
        #expect(throws: CNParseError.duplicateChain(2)) {
            _ = try CNConfiguration(
                entry: [
                    "includesSubdomains": true,
                    "chainSet": [
                        [
                            [
                                "type": "prefixWithNumber",
                                "value": "DigiCert C",
                            ],
                            [
                                "type": "exact",
                                "value": "www.apple.com",
                            ],
                        ],
                        [
                            [
                                "type": "exact",
                                "value": "a",
                            ],
                            [
                                "type": "exact",
                                "value": "b",
                            ],
                        ],
                        [
                            [
                                "type": "prefixWithNumber",
                                "value": "DigiCert C",
                            ],
                            [
                                "type": "exact",
                                "value": "www.apple.com",
                            ],
                        ],
                    ],
                ]
            )
        }
    }
}
