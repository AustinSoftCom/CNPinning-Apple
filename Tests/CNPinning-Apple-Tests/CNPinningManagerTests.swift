// Copyright (c) 2026 AustinSoft.com

@testable import CNPinning_Apple
import Foundation
import Testing

// MARK: CNPinningManager Tests

struct CNPinningManagerTests {
    @Test func cnPinningManagerDecode() throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
                [
                    "CNPinningManager": [
                        "PinnedDomains": [
                            "www.apple.com": [
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
                                ],
                            ],
                        ],
                    ],
                ]
            },
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
        let pinningManager = try CNPinningManager(osCalls: osCalls)
        #expect(pinningManager.description == "CNPinningManager([\"www.apple.com\"], [\"www.apple.com\": CNConfiguration(includesSubdomains: false, [CNChain([CNChainLink(.prefixWithNumber, \"DigiCert C\"), CNChainLink(.exact, \"www.apple.com\")])])])")
    }

    @Test func cnPinningManagerInit() throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
                return nil
            },
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
        let pinningManager = try CNPinningManager(
            configuration: [
                "www.apple.com": .init(
                    includesSubdomains: false,
                    [
                        .init([
                            .init(.prefixWithNumber, "DigiCert C"),
                            .init(.exact, "www.apple.com"),
                        ]),
                    ]
                ),
            ],
            osCalls: osCalls
        )
        #expect(pinningManager.description == "CNPinningManager([\"www.apple.com\": CNConfiguration(includesSubdomains: false, [CNChain([CNChainLink(.prefixWithNumber, \"DigiCert C\"), CNChainLink(.exact, \"www.apple.com\")])])])")
    }

    @Test func cnPinningManagerConvinienceInitNoParams() throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
                ["CFBundleName": "test"]
            },
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
        #expect(throws: CNParseError.missingValue("CNPinningManager")) {
            _ = try CNPinningManager(osCalls: osCalls)
        }
    }

    @Test func cnPinningManagerConveniceInitWithParams() throws {
        let pinningManager = try CNPinningManager(
            configuration: [
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
        #expect(pinningManager.description == "CNPinningManager([\"www.apple.com\": CNConfiguration(includesSubdomains: false, [CNChain([CNChainLink(.prefixWithNumber, \"DigiCert C\"), CNChainLink(.exact, \"www.apple.com\")])])])")
    }

	@Test func cnPinningManagerConveniceInitWithParamsConflicts() throws {
		let osCalls = OSCalls(
			getInfoDictionary: {
				[
					"NSAppTransportSecurity": [
						"NSPinnedDomains": [
							"captive.apple.com": [
								"NSIncludesSubdomains": false,
								"NSPinnedCAIdentities": [
									[
										"SPKI-SHA256-BASE64": "uUwZgwDOxcBXrQcntwu+kYFpkiVkOaezL0WYEZ3anJc=",
									],
								],
								"NSPinnedLeafIdentities": [
									[
										"SPKI-SHA256-BASE64": "UKUeIlCGrdMx5Me88sffGGn75bDYCUtr2EIrv3aLW5E=",
									],
								],
							],
						],
					],
					"CNPinningManager": [
						"PinnedDomains": [
							"www.apple.com": [
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
								],
							],
						],
					],
				]
			},
			getServerTrust: { _ in
				#expect(Bool(false))
				return nil
			},
			getCertificateChain: { _ in
				#expect(Bool(false))
				return nil
			},
			getCommonName: { _ in
				#expect(Bool(false))
				return nil
			}
		)

		#expect(throws: CNParseError.atsConflict) {
			_ = try CNPinningManager(
				configuration: [
					"www.apple.com": .init(
						includesSubdomains: false,
						[
							.init([
								.init(.prefixWithNumber, "DigiCert C"),
								.init(.exact, "www.apple.com"),
							]),
						]
					),
				],
				osCalls: osCalls
			)
		}
	}

    @Test func cnPinningManagerConvenienceInitConflictsATS() throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
                [
                    "NSAppTransportSecurity": [
                        "NSPinnedDomains": [
                            "captive.apple.com": [
                                "NSIncludesSubdomains": false,
                                "NSPinnedCAIdentities": [
                                    [
                                        "SPKI-SHA256-BASE64": "uUwZgwDOxcBXrQcntwu+kYFpkiVkOaezL0WYEZ3anJc=",
                                    ],
                                ],
                                "NSPinnedLeafIdentities": [
                                    [
                                        "SPKI-SHA256-BASE64": "UKUeIlCGrdMx5Me88sffGGn75bDYCUtr2EIrv3aLW5E=",
                                    ],
                                ],
                            ],
                        ],
                    ],
                    "CNPinningManager": [
                        "PinnedDomains": [
                            "www.apple.com": [
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
                                ],
                            ],
                        ],
                    ],
                ]
			},
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
        #expect(throws: CNParseError.atsConflict) {
            _ = try CNPinningManager(osCalls: osCalls)
        }
    }

    @Test func cnPinningManagerConvenienceNoPlist() throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
                nil
            },
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
        #expect(throws: CNParseError.noInfoPlist) {
            _ = try CNPinningManager(osCalls: osCalls)
        }
    }

    @Test func cnPinningManagerConvenienceInitATSNotPinning() throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
                [
                    "NSAppTransportSecurity": [
                        "NSAllowArbitraryLoads": true,
                    ],
                    "CNPinningManager": [
                        "PinnedDomains": [
                            "www.apple.com": [
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
                                ],
                            ],
                        ],
                    ],
                ]
            },
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
        let pinningManager = try CNPinningManager(osCalls: osCalls)
        #expect(pinningManager.description == "CNPinningManager([\"www.apple.com\"], [\"www.apple.com\": CNConfiguration(includesSubdomains: false, [CNChain([CNChainLink(.prefixWithNumber, \"DigiCert C\"), CNChainLink(.exact, \"www.apple.com\")])])])")
    }

    @Test func cnPinningManagerSupportExplicitSubdomainsAndDomainOrder() throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
				["CFBundleName": "test"]
            },
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
        let pinningManager = try CNPinningManager(
			initType: .configuration(
				descriptionOrder: ["www.apple.com", "apple.com"],
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
			),
            osCalls: osCalls
        )
        #expect(pinningManager.description == "CNPinningManager([\"www.apple.com\", \"apple.com\"], [\"www.apple.com\": CNConfiguration(includesSubdomains: false, [CNChain([CNChainLink(.prefixWithNumber, \"DigiCert C\"), CNChainLink(.exact, \"www.apple.com\")])]), \"apple.com\": CNConfiguration(includesSubdomains: true, [CNChain([CNChainLink(.prefixWithNumber, \"DigiCert C\"), CNChainLink(.suffix, \".apple.com\")])])])")
    }

    @Test func cnPinningManagerNoCNPinningManager() throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
                ["Test": 1]
            },
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
        #expect(throws: CNParseError.missingValue("CNPinningManager")) {
            _ = try CNPinningManager(osCalls: osCalls)
        }
    }

    @Test func cnPinningManagerNoPinnedDomains() throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
                [
                    "CNPinningManager": [:],
                ]
            },
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
        #expect(throws: CNParseError.missingValue("PinnedDomains")) {
            _ = try CNPinningManager(osCalls: osCalls)
        }
    }

    @Test func cnPinningManagerPinnedDomainTypeWrong() throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
                [
                    "CNPinningManager": [
                        "PinnedDomains": [
                            "www.apple.com": false,
                        ],
                    ],
                ]
            },
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
        #expect(throws: CNParseError.invalidType("www.apple.com")) {
            _ = try CNPinningManager(osCalls: osCalls)
        }
    }

    @Test func cnPinningManagerGetConfigurationExact() throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
                return nil
            },
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
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
            ],
            osCalls: osCalls
        )
        let testConfiguration = try CNConfiguration(
            includesSubdomains: false,
            [
                .init([
                    .init(.prefixWithNumber, "DigiCert C"),
                    .init(.exact, "www.apple.com"),
                ]),
            ]
        )
        let pinningMatches = pinningManager.getConfiguration(for: "www.apple.com")
        #expect(pinningMatches.count == 1)
        let pinningMatch = try #require(pinningMatches[0] as? CNConfiguration)
        #expect(pinningMatch == testConfiguration)
    }

    @Test func cnPinningManagerGetSubdomainConfiguration() throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
                return nil
            },
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
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
            ],
            osCalls: osCalls
        )
        let testConfiguration = try CNConfiguration(
            includesSubdomains: true,
            [
                .init([
                    .init(.prefixWithNumber, "DigiCert C"),
                    .init(.suffix, ".apple.com"),
                ]),
            ]
        )
        let pinningMatches = pinningManager.getConfiguration(for: "sub.apple.com")
        #expect(pinningMatches.count == 1)
        let pinningMatch = try #require(pinningMatches[0] as? CNConfiguration)
        #expect(pinningMatch == testConfiguration)
    }

    @Test func cnPinningManagerGetDomainConfiguration() throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
                return nil
            },
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
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
            ],
            osCalls: osCalls
        )
        let testConfiguration = try CNConfiguration(
            includesSubdomains: true,
            [
                .init([
                    .init(.prefixWithNumber, "DigiCert C"),
                    .init(.suffix, ".apple.com"),
                ]),
            ]
        )
        let pinningMatches = pinningManager.getConfiguration(for: "apple.com")
        #expect(pinningMatches.count == 1)
        let pinningMatch = try #require(pinningMatches[0] as? CNConfiguration)
        #expect(pinningMatch == testConfiguration)
    }

    @Test func cnPinningManagerGetLongerDomainConfiguration() throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
                return nil
            },
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
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
                    includesSubdomains: true,
                    [
                        .init([
                            .init(.prefixWithNumber, "DigiCert C"),
                            .init(.suffix, ".www.apple.com"),
                        ]),
                    ]
                ),
            ],
            osCalls: osCalls
        )
        let testConfiguration = try CNConfiguration(
            includesSubdomains: true,
            [
                .init([
                    .init(.prefixWithNumber, "DigiCert C"),
                    .init(.suffix, ".www.apple.com"),
                ]),
            ]
        )
        let pinningMatches = pinningManager.getConfiguration(for: "sub.www.apple.com")
        #expect(pinningMatches.count == 1)
        let pinningMatch = try #require(pinningMatches[0] as? CNConfiguration)
        #expect(pinningMatch == testConfiguration)
    }

    @Test func cnPinningManagerNoSortOrder() throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
                return nil
            },
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
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
            ],
            osCalls: osCalls
        )
        #expect(pinningManager.description == "CNPinningManager([\"apple.com\": CNConfiguration(includesSubdomains: true, [CNChain([CNChainLink(.prefixWithNumber, \"DigiCert C\"), CNChainLink(.suffix, \".apple.com\")])]), \"www.apple.com\": CNConfiguration(includesSubdomains: false, [CNChain([CNChainLink(.prefixWithNumber, \"DigiCert C\"), CNChainLink(.exact, \"www.apple.com\")])])])")
    }

    @Test func cnPinningManagerSpecifyBadDomainName() throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
				["CFBundleName": "test"]
            },
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
        let pinningManager = try CNPinningManager(
			initType: .configuration(
				descriptionOrder: ["www.apple.com", "apple.com", "example.com"],
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
			),
            osCalls: osCalls
        )
        #expect(pinningManager.description == "CNPinningManager([\"www.apple.com\", \"apple.com\", \"example.com\"], [\"www.apple.com\": CNConfiguration(includesSubdomains: false, [CNChain([CNChainLink(.prefixWithNumber, \"DigiCert C\"), CNChainLink(.exact, \"www.apple.com\")])]), \"apple.com\": CNConfiguration(includesSubdomains: true, [CNChain([CNChainLink(.prefixWithNumber, \"DigiCert C\"), CNChainLink(.suffix, \".apple.com\")])])])")
    }

    @Test func cnPinningManagerValidateNotPinned() throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
                return nil
            },
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
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
            ],
            osCalls: osCalls
        )
        let challenge = buildAuthenticationChallenge(for: "example.com")
        let result = pinningManager.validate(challenge: challenge, completionHandler: { _, _ in
            #expect(Bool(false))
        })
        #expect(result == false)
    }

    @Test func cnPinningManagerAsyncValidateNotPinned() async throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
                return nil
            },
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
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
            ],
            osCalls: osCalls
        )
        let challenge = buildAuthenticationChallenge(for: "example.com")
        await #expect(throws: CNPinningError.notPinned) {
            _ = try await pinningManager.validate(challenge: challenge)
        }
    }

    @Test func cnPinningManagerValidatePinnedNoTrust() throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
                return nil
            },
            getServerTrust: { _ in
                nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
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
            ],
            osCalls: osCalls
        )
        let challenge = buildAuthenticationChallenge(for: "sub.apple.com")
        let result = pinningManager.validate(challenge: challenge, completionHandler: { disposition, trust in
            #expect(disposition == .cancelAuthenticationChallenge)
            #expect(trust == nil)
        })
        #expect(result == true)
    }

    @Test func cnPinningManagerAsyncValidatePinnedNoTrust() async throws {
        let osCalls = OSCalls(
            getInfoDictionary: {
                return nil
            },
            getServerTrust: { _ in
                nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
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
            ],
            osCalls: osCalls
        )
        let challenge = buildAuthenticationChallenge(for: "sub.apple.com")
        #expect(try await pinningManager.validate(challenge: challenge) == (.cancelAuthenticationChallenge, nil))
    }

    class TestServerTrust: CNSecTrust, @unchecked Sendable {
    }

    @Test func cnPinningManagerValidatePinnedTrustNoCertChain() throws {
        let testServerTrust = TestServerTrust()
        let osCalls = OSCalls(
            getInfoDictionary: {
                return nil
            },
            getServerTrust: { _ in
                testServerTrust
            },
            getCertificateChain: {
                #expect($0 === testServerTrust)
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
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
            ],
            osCalls: osCalls
        )
        let challenge = buildAuthenticationChallenge(for: "sub.apple.com")
        let result = pinningManager.validate(challenge: challenge, completionHandler: { disposition, trust in
            #expect(disposition == .cancelAuthenticationChallenge)
            #expect(trust == nil)
        })
        #expect(result == true)
    }

    class TestCertificate: CNSecCertificate, @unchecked Sendable {
        let name: String

        init(_ name: String) {
            self.name = name
        }
    }

    @Test func cnPinningManagerValidatePinnedTrustInvalidNamesInCertChain() throws {
        let testServerTrust = TestServerTrust()
        // Remember-certs passed to validate are in *reverse* order, so leaf first!
        let certificates = [
            TestCertificate("Leaf Certificate"),
            TestCertificate("Intermediate CA 2"),
            TestCertificate("Intermediate CA 1"),
            TestCertificate("CA Root Certificate"),
        ]
        let osCalls = OSCalls(
            getInfoDictionary: {
                return nil
            },
            getServerTrust: { _ in
                testServerTrust
            },
            getCertificateChain: { _ in
                certificates
            },
            getCommonName: { _ in
                nil
            }
        )
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
            ],
            osCalls: osCalls
        )
        let challenge = buildAuthenticationChallenge(for: "sub.apple.com")
        let result = pinningManager.validate(challenge: challenge, completionHandler: { disposition, trust in
            #expect(disposition == .cancelAuthenticationChallenge)
            #expect(trust == nil)
        })
        #expect(result == true)
    }

    @Test func cnPinningManagerValidatePinnedTrustCertNamesFail() throws {
        let testServerTrust = TestServerTrust()
        // Remember-certs passed to validate are in *reverse* order, so leaf first!
        let certificates = [
            TestCertificate("Leaf Certificate"),
            TestCertificate("Intermediate CA 1"),
            TestCertificate("CA Root Certificate"),
        ]
        let osCalls = OSCalls(
            getInfoDictionary: {
                return nil
            },
            getServerTrust: { _ in
                testServerTrust
            },
            getCertificateChain: { _ in
                certificates
            },
            getCommonName: { cert in
                guard let cert = cert as? TestCertificate else {
                    #expect(Bool(false))
                    return nil
                }
                return cert.name
            }
        )
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
            ],
            osCalls: osCalls
        )
        let challenge = buildAuthenticationChallenge(for: "sub.apple.com")
        let result = pinningManager.validate(challenge: challenge, completionHandler: { disposition, trust in
            #expect(disposition == .cancelAuthenticationChallenge)
            #expect(trust == nil)
        })
        #expect(result == true)
    }

    @Test func cnPinningManagerValidatePinnedTrustCertNamesPass() throws {
        let testServerTrust = TestServerTrust()
        // Remember-certs passed to validate are in *reverse* order, so leaf first!
        let certificates = [
            TestCertificate("Leaf Certificate"),
            TestCertificate("Intermediate CA 1"),
            TestCertificate("CA Root Certificate G9"),
        ]
        let osCalls = OSCalls(
            getInfoDictionary: {
                return nil
            },
            getServerTrust: { _ in
                testServerTrust
            },
            getCertificateChain: { _ in
                certificates
            },
            getCommonName: { cert in
                guard let cert = cert as? TestCertificate else {
                    #expect(Bool(false))
                    return nil
                }
                return cert.name
            }
        )
        let pinningManager = try CNPinningManager(
            configuration: [
                "apple.com": .init(
                    includesSubdomains: true,
                    [
                        .init([
                            .init(.prefixWithNumber, "CA Root Certificate G"),
                            .init(.prefixWithNumber, "Intermediate CA "),
                            .init(.exact, "Leaf Certificate"),
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
            ],
            osCalls: osCalls
        )
        let challenge = buildAuthenticationChallenge(for: "sub.apple.com")
        let result = pinningManager.validate(challenge: challenge, completionHandler: { disposition, trust in
            #expect(disposition == .performDefaultHandling)
            #expect(trust == nil)
        })
        #expect(result == true)
    }

    @Test func cnPinningManagerAsyncValidatePinnedTrustCertNamesPass() async throws {
        let testServerTrust = TestServerTrust()
        // Remember-certs passed to validate are in *reverse* order, so leaf first!
        let certificates = [
            TestCertificate("Leaf Certificate"),
            TestCertificate("Intermediate CA 1"),
            TestCertificate("CA Root Certificate G9"),
        ]
        let osCalls = OSCalls(
            getInfoDictionary: {
                return nil
            },
            getServerTrust: { _ in
                testServerTrust
            },
            getCertificateChain: { _ in
                certificates
            },
            getCommonName: { cert in
                guard let cert = cert as? TestCertificate else {
                    #expect(Bool(false))
                    return nil
                }
                return cert.name
            }
        )
        let pinningManager = try CNPinningManager(
            configuration: [
                "apple.com": .init(
                    includesSubdomains: true,
                    [
                        .init([
                            .init(.prefixWithNumber, "CA Root Certificate G"),
                            .init(.prefixWithNumber, "Intermediate CA "),
                            .init(.exact, "Leaf Certificate"),
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
            ],
            osCalls: osCalls
        )
        let challenge = buildAuthenticationChallenge(for: "sub.apple.com")
        #expect(try await pinningManager.validate(challenge: challenge) == (.performDefaultHandling, nil))
    }

	@Test func cnPinningManagerConveniceInitEmptyCNChainLinkValue() throws {
		let osCalls = OSCalls(
			getInfoDictionary: {
				[
					"CNPinningManager": [
						"PinnedDomains": [
							"www.apple.com": [
								"includesSubdomains": false,
								"chainSet": [
									[
										[
											"type": "prefixWithNumber",
											"value": "DigiCert C",
										],
										[
											"type": "exact",
											"value": "",
										],
									],
								],
							],
						],
					],
				]
			},
			getServerTrust: { _ in
				#expect(Bool(false))
				return nil
			},
			getCertificateChain: { _ in
				#expect(Bool(false))
				return nil
			},
			getCommonName: { _ in
				#expect(Bool(false))
				return nil
			}
		)
		#expect(throws: CNParseError.missingValue("exact value")) {
			_ = try CNPinningManager(osCalls: osCalls)
		}
	}
}

// MARK: - CNPinning 1.2 tests

struct CNPinning1_2Tests {
    @Test func newInitServerNameAndSecKey() throws {
        let (_, publicKey) = try generateTestKeypair(alg: .rs256)
        let osCalls = OSCalls(
            getInfoDictionary: {
                [
                    "CNPinningManager": [
                        "PinnedDomains": [
                            "www.apple.com": [
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
                                ],
                            ],
                        ],
                    ],
                ]
            },
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
        let pinningManager = try CNPinningManager(
            authenticationHost: "auth.example.com",
            policySigningKey: publicKey,
            osCalls: osCalls
        )
        #expect(pinningManager.configuration.count == 1)
        #expect(pinningManager.authenticationHost == "auth.example.com")
        #expect(pinningManager.policySigningKey === publicKey)
        #expect(pinningManager.enterpriseConfigurations.withLock({ $0 }) == nil )
    }
    
    @Test func newInitServerNameSecKeyConfiguration() throws {
        let (_, publicKey) = try generateTestKeypair(alg: .rs256)
        let osCalls = OSCalls(
            getInfoDictionary: {
                [
                    "CFBundleVersion": "1.0",
                ]
            },
            getServerTrust: { _ in
                #expect(Bool(false))
                return nil
            },
            getCertificateChain: { _ in
                #expect(Bool(false))
                return nil
            },
            getCommonName: { _ in
                #expect(Bool(false))
                return nil
            }
        )
        let pinningManager = try CNPinningManager(
            authenticationHost: "auth.example.com",
            policySigningKey: publicKey,
            configuration: [
                "www.apple.com": .init(
                    includesSubdomains: false,
                    [
                        .init([
                            .init(.prefixWithNumber, "DigiCert C"),
                            .init(.exact, "www.apple.com"),
                        ]),
                    ]
                ),
            ],
            osCalls: osCalls
        )
        #expect(pinningManager.configuration.count == 1)
        #expect(pinningManager.authenticationHost == "auth.example.com")
        #expect(pinningManager.policySigningKey === publicKey)
        #expect(pinningManager.enterpriseConfigurations.withLock({ $0 }) == nil )
    }
    
    @Test func initializeEnterpriseConfiguration() throws {
        let alg: JWTAlgorithm = .es256
        let (privateKey, publicKey) = try generateTestKeypair(alg: alg)
        let pinningManager = try CNPinningManager(
            authenticationHost: "auth.example.com",
            policySigningKey: publicKey,
            configuration: [:],
            osCalls: .init()
        )
        #expect(pinningManager.enterpriseConfigurations.withLock({ $0 }) == nil )
        let enterprisePolicy = try CNEnterprisePolicy(
            issuedAt: Date(timeIntervalSinceNow: -86400),
            expirationDate: Date(timeIntervalSinceNow: 86400),
            configuration: [
                "*": .init(
                    chainSet: [
                        .init([
                            .init(.exact, "Certificate Authority Name"),
                            .init(.exact, "Certificate Intermediate 1"),
                            .init(.exact, "Certificate Intermediate 2"),
                            .init(.suffix, ".example.com"),
                        ])
                    ]
                )
            ]
        )
        let payload = try JSONEncoder().encode(enterprisePolicy)
        
        let jwt = JWT(alg: alg, payload: payload, signedWith: privateKey)
        let jwtData = try #require(jwt.encoded)
        try pinningManager.applyEnterprisePolicy(with: jwtData)
        
        #expect(pinningManager.enterpriseConfigurations.withLock({ $0 }) == enterprisePolicy)
    }
    
    @Test func getPolicyEnterprise() throws {
        let alg: JWTAlgorithm = .es256
        let (privateKey, publicKey) = try generateTestKeypair(alg: alg)
        let pinningManager = try CNPinningManager(
            authenticationHost: "auth.example.com",
            policySigningKey: publicKey,
            configuration: [:],
            osCalls: .init()
        )
        #expect(pinningManager.enterpriseConfigurations.withLock({ $0 }) == nil )
        let enterprisePolicy = try CNEnterprisePolicy(
            issuedAt: Date(timeIntervalSinceNow: -86400),
            expirationDate: Date(timeIntervalSinceNow: 86400),
            configuration: [
                "*": .init(
                    chainSet: [
                        .init([
                            .init(.exact, "Certificate Authority Name"),
                            .init(.exact, "Certificate Intermediate 1"),
                            .init(.exact, "Certificate Intermediate 2"),
                            .init(.suffix, ".example.com"),
                        ])
                    ]
                )
            ]
        )
        let payload = try JSONEncoder().encode(enterprisePolicy)
        
        let jwt = JWT(alg: alg, payload: payload, signedWith: privateKey)
        let jwtData = try #require(jwt.encoded)
        try pinningManager.applyEnterprisePolicy(with: jwtData)
        
        #expect(pinningManager.enterpriseConfigurations.withLock({ $0 }) == enterprisePolicy)
    }
    
    @Test func doubleApplyEnterpriseConfiguration() throws {
        let alg: JWTAlgorithm = .es256
        let (privateKey, publicKey) = try generateTestKeypair(alg: alg)
        let pinningManager = try CNPinningManager(
            authenticationHost: "auth.example.com",
            policySigningKey: publicKey,
            configuration: [:],
            osCalls: .init()
        )
        #expect(pinningManager.enterpriseConfigurations.withLock({ $0 }) == nil )
        let enterprisePolicy = try CNEnterprisePolicy(
            issuedAt: Date(timeIntervalSinceNow: -86400),
            expirationDate: Date(timeIntervalSinceNow: 86400),
            configuration: [
                "*": .init(
                    chainSet: [
                        .init([
                            .init(.exact, "Certificate Authority Name"),
                            .init(.exact, "Certificate Intermediate 1"),
                            .init(.exact, "Certificate Intermediate 2"),
                            .init(.suffix, ".example.com"),
                        ])
                    ]
                )
            ]
        )
        let payload = try JSONEncoder().encode(enterprisePolicy)
        
        let jwt = JWT(alg: alg, payload: payload, signedWith: privateKey)
        let jwtData = try #require(jwt.encoded)
        try pinningManager.applyEnterprisePolicy(with: jwtData)
        #expect(throws: CNPinningError.existingEnterpriseConfiguration) {
            try pinningManager.applyEnterprisePolicy(with: jwtData)
        }
    }
    
    @Test func signOutEnterpriseConfiguration() throws {
        let alg: JWTAlgorithm = .es256
        let (privateKey, publicKey) = try generateTestKeypair(alg: alg)
        let pinningManager = try CNPinningManager(
            authenticationHost: "auth.example.com",
            policySigningKey: publicKey,
            configuration: [:],
            osCalls: .init()
        )
        #expect(pinningManager.enterpriseConfigurations.withLock({ $0 }) == nil )
        let enterprisePolicy = try CNEnterprisePolicy(
            issuedAt: Date(timeIntervalSinceNow: -86400),
            expirationDate: Date(timeIntervalSinceNow: 86400),
            configuration: [
                "*": .init(
                    chainSet: [
                        .init([
                            .init(.exact, "Certificate Authority Name"),
                            .init(.exact, "Certificate Intermediate 1"),
                            .init(.exact, "Certificate Intermediate 2"),
                            .init(.suffix, ".example.com"),
                        ])
                    ]
                )
            ]
        )
        let payload = try JSONEncoder().encode(enterprisePolicy)
        
        let jwt = JWT(alg: alg, payload: payload, signedWith: privateKey)
        let jwtData = try #require(jwt.encoded)
        try pinningManager.applyEnterprisePolicy(with: jwtData)
        #expect(pinningManager.enterpriseConfigurations.withLock({ $0 }) != nil )
        pinningManager.signOut()
        #expect(pinningManager.enterpriseConfigurations.withLock({ $0 }) == nil )
    }
    
    @Test func initializeEnterpriseBasic() throws {
        let alg: JWTAlgorithm = .es256
        let (_, publicKey) = try generateTestKeypair(alg: alg)
        let pinningManager = try CNPinningManager(
            authenticationHost: "auth.example.com",
            policySigningKey: publicKey,
            configuration: [
                "example.com": .init(
                    includesSubdomains: true,
                    [
                    .init([
                        .init(.exact, "Certificate Authority Name"),
                        .init(.exact, "Certificate Intermediate 1"),
                        .init(.exact, "Certificate Intermediate 2"),
                        .init(.suffix, ".example.com"),
                    ])
                ])
            ],
        )
        #expect(pinningManager.enterpriseConfigurations.withLock({ $0 }) == nil)
    }
    
    @Test func initializeEnterpriseInfoPlist() throws {
        let alg: JWTAlgorithm = .es256
        let (_, publicKey) = try generateTestKeypair(alg: alg)
        // Exercises the public `init(authenticationHost:policySigningKey:)`, which reads the real
        // `Bundle.main` Info.plist. Which CNParseError surfaces is environment-dependent and not a
        // stable contract-Xcode's test host has a non-empty Info.plist (missing key → `.missingValue`)
        // while `swift test` has none (→ `.noInfoPlist`)-so assert only that a parse error propagates.
        #expect(throws: CNParseError.self) {
            _ = try CNPinningManager(
                authenticationHost: "auth.example.com",
                policySigningKey: publicKey
            )
        }
    }

    @Test func refreshNoEnterpriseConfiguration() throws {
        let alg: JWTAlgorithm = .es256
        let (privateKey, publicKey) = try generateTestKeypair(alg: alg)
        let pinningManager = try CNPinningManager(
            authenticationHost: "auth.example.com",
            policySigningKey: publicKey,
            configuration: [:],
            osCalls: .init()
        )
        #expect(pinningManager.enterpriseConfigurations.withLock({ $0 }) == nil )
        let enterprisePolicy = try CNEnterprisePolicy(
            issuedAt: Date(timeIntervalSinceNow: -86400),
            expirationDate: Date(timeIntervalSinceNow: 86400),
            configuration: [
                "*": .init(
                    chainSet: [
                        .init([
                            .init(.exact, "Certificate Authority Name"),
                            .init(.exact, "Certificate Intermediate 1"),
                            .init(.exact, "Certificate Intermediate 2"),
                            .init(.suffix, ".example.com"),
                        ])
                    ]
                )
            ]
        )
        let payload = try JSONEncoder().encode(enterprisePolicy)
        
        let jwt = JWT(alg: alg, payload: payload, signedWith: privateKey)
        let jwtData = try #require(jwt.encoded)
        #expect(throws: CNPinningError.missingEnterpriseConfiguration) {
            try pinningManager.refreshEnterprisePolicy(with: jwtData)
        }
    }
    
    @Test func applyRefreshEnterpriseConfiguration() throws {
        let alg: JWTAlgorithm = .es256
        let (privateKey, publicKey) = try generateTestKeypair(alg: alg)
        let pinningManager = try CNPinningManager(
            authenticationHost: "auth.example.com",
            policySigningKey: publicKey,
            configuration: [:],
            osCalls: .init()
        )
        #expect(pinningManager.enterpriseConfigurations.withLock({ $0 }) == nil )
        let enterprisePolicy = try CNEnterprisePolicy(
            issuedAt: Date(timeIntervalSinceNow: -86400),
            expirationDate: Date(timeIntervalSinceNow: 86400),
            configuration: [
                "*": .init(
                    chainSet: [
                        .init([
                            .init(.exact, "Certificate Authority Name"),
                            .init(.exact, "Certificate Intermediate 1"),
                            .init(.exact, "Certificate Intermediate 2"),
                            .init(.suffix, ".example.com"),
                        ])
                    ]
                )
            ]
        )
        let payload = try JSONEncoder().encode(enterprisePolicy)
        
        let jwt = JWT(alg: alg, payload: payload, signedWith: privateKey)
        let jwtData = try #require(jwt.encoded)
        try pinningManager.applyEnterprisePolicy(with: jwtData)
        try pinningManager.refreshEnterprisePolicy(with: jwtData)
    }
    
    @Test func applyNoEnterpriseConfiguration() throws {
        let alg: JWTAlgorithm = .es256
        let (privateKey, _) = try generateTestKeypair(alg: alg)
        let pinningManager = try CNPinningManager(
            configuration: [
                "example.com": .init(
                    includesSubdomains: true,
                    [
                        .init([
                            .init(.exact, "Certificate Authority Name"),
                            .init(.exact, "Certificate Intermediate 1"),
                            .init(.exact, "Certificate Intermediate 2"),
                            .init(.suffix, ".example.com"),
                        ])
                    ])
            ],
            osCalls: .init()
        )
        #expect(pinningManager.enterpriseConfigurations.withLock({ $0 }) == nil )
        let enterprisePolicy = try CNEnterprisePolicy(
            issuedAt: Date(timeIntervalSinceNow: -86400),
            expirationDate: Date(timeIntervalSinceNow: 86400),
            configuration: [
                "*": .init(
                    chainSet: [
                        .init([
                            .init(.exact, "Certificate Authority Name"),
                            .init(.exact, "Certificate Intermediate 1"),
                            .init(.exact, "Certificate Intermediate 2"),
                            .init(.suffix, ".example.com"),
                        ])
                    ]
                )
            ]
        )
        let payload = try JSONEncoder().encode(enterprisePolicy)
        
        let jwt = JWT(alg: alg, payload: payload, signedWith: privateKey)
        let jwtData = try #require(jwt.encoded)
        #expect(throws: CNPinningError.enterpriseNotConfigured) {
            try pinningManager.applyEnterprisePolicy(with: jwtData)
        }
    }
    
    @Test func processWithEnterprise() throws {
        let alg: JWTAlgorithm = .es256
        let (privateKey, publicKey) = try generateTestKeypair(alg: alg)
        let pinningManager = try CNPinningManager(
            authenticationHost: "auth.example.com",
            policySigningKey: publicKey,
            configuration: [
                "www.example.com": .init(
                    includesSubdomains: true,
                    [
                        .init([
                            .init(.exact, "Certificate Authority Name"),
                            .init(.exact, "Certificate Intermediate 1"),
                            .init(.exact, "Certificate Intermediate 2"),
                            .init(.suffix, ".example.com"),
                        ])
                    ])
            ],
        )
        #expect(pinningManager.enterpriseConfigurations.withLock({ $0 }) == nil)

        let enterprisePolicy = try CNEnterprisePolicy(
            issuedAt: Date(timeIntervalSinceNow: -86400),
            expirationDate: Date(timeIntervalSinceNow: 86400),
            configuration: [
                "*": .init(
                    chainSet: [
                        .init([
                            .init(.exact, "Enterprise Authority Name"),
                            .init(.exact, "Enterprise Intermediate 1"),
                            .init(.exact, "Enterprise Intermediate 2"),
                            .init(.suffix, ".example.com"),
                        ])
                    ]
                )
            ]
        )
        let payload = try JSONEncoder().encode(enterprisePolicy)
        
        let jwt = JWT(alg: alg, payload: payload, signedWith: privateKey)
        let jwtData = try #require(jwt.encoded)
        try pinningManager.applyEnterprisePolicy(with: jwtData)
        
        let result = pinningManager.getConfiguration(for: "www.example.com")
        #expect(result.count == 2)
        #expect((result[0] as? CNEnterpriseConfiguration) != nil)
        #expect((result[1] as? CNConfiguration) != nil)
    }
    
    @Test func processAuthHostWithEnterprise() throws {
        let alg: JWTAlgorithm = .es256
        let (privateKey, publicKey) = try generateTestKeypair(alg: alg)
        let pinningManager = try CNPinningManager(
            authenticationHost: "auth.example.com",
            policySigningKey: publicKey,
            configuration: [
                "auth.example.com": .init(
                    includesSubdomains: true,
                    [
                        .init([
                            .init(.exact, "Certificate Authority Name"),
                            .init(.exact, "Certificate Intermediate 1"),
                            .init(.exact, "Certificate Intermediate 2"),
                            .init(.suffix, ".example.com"),
                        ])
                    ])
            ],
        )
        #expect(pinningManager.enterpriseConfigurations.withLock({ $0 }) == nil)
        
        let enterprisePolicy = try CNEnterprisePolicy(
            issuedAt: Date(timeIntervalSinceNow: -86400),
            expirationDate: Date(timeIntervalSinceNow: 86400),
            configuration: [
                "*": .init(
                    chainSet: [
                        .init([
                            .init(.exact, "Enterprise Authority Name"),
                            .init(.exact, "Enterprise Intermediate 1"),
                            .init(.exact, "Enterprise Intermediate 2"),
                            .init(.suffix, ".example.com"),
                        ])
                    ]
                )
            ]
        )
        let payload = try JSONEncoder().encode(enterprisePolicy)
        
        let jwt = JWT(alg: alg, payload: payload, signedWith: privateKey)
        let jwtData = try #require(jwt.encoded)
        try pinningManager.applyEnterprisePolicy(with: jwtData)
        
        let result = pinningManager.getConfiguration(for: "auth.example.com")
        #expect(result.count == 1)
        #expect((result[0] as? CNConfiguration) != nil)
    }
    
    @Test func processIncorrectKeyWithEnterprise() throws {
        let alg: JWTAlgorithm = .es256
        let (privateKey, _) = try generateTestKeypair(alg: alg)
        let pinningManager = try CNPinningManager(
            authenticationHost: "auth.example.com",
            policySigningKey: privateKey,
            configuration: [
                "auth.example.com": .init(
                    includesSubdomains: true,
                    [
                        .init([
                            .init(.exact, "Certificate Authority Name"),
                            .init(.exact, "Certificate Intermediate 1"),
                            .init(.exact, "Certificate Intermediate 2"),
                            .init(.suffix, ".example.com"),
                        ])
                    ])
            ],
        )
        #expect(pinningManager.enterpriseConfigurations.withLock({ $0 }) == nil)
        
        let enterprisePolicy = try CNEnterprisePolicy(
            issuedAt: Date(timeIntervalSinceNow: -86400),
            expirationDate: Date(timeIntervalSinceNow: 86400),
            configuration: [
                "*": .init(
                    chainSet: [
                        .init([
                            .init(.exact, "Enterprise Authority Name"),
                            .init(.exact, "Enterprise Intermediate 1"),
                            .init(.exact, "Enterprise Intermediate 2"),
                            .init(.suffix, ".example.com"),
                        ])
                    ]
                )
            ]
        )
        let payload = try JSONEncoder().encode(enterprisePolicy)
        
        let jwt = JWT(alg: alg, payload: payload, signedWith: privateKey)
        let jwtData = try #require(jwt.encoded)
        #expect(throws: CNPinningError.invalidJWSFormat) {
            try pinningManager.applyEnterprisePolicy(with: jwtData)
        }
    }

    @Test func enterprisePolicyDates() throws {
        let alg: JWTAlgorithm = .es256
        let (privateKey, publicKey) = try generateTestKeypair(alg: alg)
        let pinningManager = try CNPinningManager(
            authenticationHost: "auth.example.com",
            policySigningKey: publicKey,
            configuration: [:],
            osCalls: .init()
        )
        // No policy yet, so both accessors are nil.
        #expect(pinningManager.enterprisePolicyIssuedAt == nil)
        #expect(pinningManager.enterprisePolicyExpiry == nil)

        let enterprisePolicy = try CNEnterprisePolicy(
            issuedAt: Date(timeIntervalSince1970: 1_000_000),
            expirationDate: Date(timeIntervalSince1970: 2_000_000),
            configuration: [
                "*": .init(
                    chainSet: [
                        .init([
                            .init(.exact, "Certificate Authority Name"),
                            .init(.suffix, ".example.com"),
                        ])
                    ]
                )
            ]
        )
        let payload = try JSONEncoder().encode(enterprisePolicy)
        let jwt = JWT(alg: alg, payload: payload, signedWith: privateKey)
        try pinningManager.applyEnterprisePolicy(with: #require(jwt.encoded))

        #expect(pinningManager.enterprisePolicyIssuedAt == Date(timeIntervalSince1970: 1_000_000))
        #expect(pinningManager.enterprisePolicyExpiry == Date(timeIntervalSince1970: 2_000_000))

        // After signing out they revert to nil.
        pinningManager.signOut()
        #expect(pinningManager.enterprisePolicyIssuedAt == nil)
        #expect(pinningManager.enterprisePolicyExpiry == nil)
    }

    @Test func processWithExpiredEnterprise() throws {
        let alg: JWTAlgorithm = .es256
        let (privateKey, publicKey) = try generateTestKeypair(alg: alg)
        // A fixed clock past the policy's expiration: the enterprise configuration is ignored.
        let osCalls = OSCalls(getCurrentDate: { Date(timeIntervalSince1970: 2_000_001) })
        let pinningManager = try CNPinningManager(
            authenticationHost: "auth.example.com",
            policySigningKey: publicKey,
            configuration: [
                "www.example.com": .init(
                    includesSubdomains: true,
                    [
                        .init([
                            .init(.exact, "Certificate Authority Name"),
                            .init(.suffix, ".example.com"),
                        ])
                    ])
            ],
            osCalls: osCalls
        )

        let enterprisePolicy = try CNEnterprisePolicy(
            issuedAt: Date(timeIntervalSince1970: 1_000_000),
            expirationDate: Date(timeIntervalSince1970: 2_000_000),
            configuration: [
                "*": .init(
                    chainSet: [
                        .init([
                            .init(.exact, "Enterprise Authority Name"),
                            .init(.suffix, ".example.com"),
                        ])
                    ]
                )
            ]
        )
        let payload = try JSONEncoder().encode(enterprisePolicy)
        let jwt = JWT(alg: alg, payload: payload, signedWith: privateKey)
        try pinningManager.applyEnterprisePolicy(with: #require(jwt.encoded))

        // The policy is still applied (the accessors report it), but it no longer contributes mappings.
        #expect(pinningManager.enterpriseConfigurations.withLock({ $0 }) != nil)
        let result = pinningManager.getConfiguration(for: "www.example.com")
        #expect(result.count == 1)
        #expect((result[0] as? CNConfiguration) != nil)
    }
}
