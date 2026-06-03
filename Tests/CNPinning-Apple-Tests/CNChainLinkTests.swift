// Copyright (c) 2026 AustinSoft.com

@testable import CNPinning_Apple
import Foundation
import Testing

// MARK: CNChainLink tests

struct CNChainLinkTests {
    @Test func cnChainLinkDecodeExact() throws {
        let linkDict: [String: Any] = [
            "type": "exact",
            "value": "example.com",
        ]
        let link = try CNChainLink(entry: linkDict)
        #expect(link.linkType == .exact)
        #expect(link.value == "example.com")
    }

    @Test func cnChainLinkDecodePrefix() throws {
        let linkDict: [String: Any] = [
            "type": "prefix",
            "value": "DigiCert ",
        ]
        let link = try CNChainLink(entry: linkDict)
        #expect(link.linkType == .prefix)
        #expect(link.value == "DigiCert ")
    }

    @Test func cnChainLinkDecodePrefixNumber() throws {
        let linkDict: [String: Any] = [
            "type": "prefixWithNumber",
            "value": "DigiCert C",
        ]
        let link = try CNChainLink(entry: linkDict)
        #expect(link.linkType == .prefixWithNumber)
        #expect(link.value == "DigiCert C")
    }

    @Test func cnChainLinkDecodeSuffix() throws {
        let linkDict: [String: Any] = [
            "type": "suffix",
            "value": " TLS",
        ]
        let link = try CNChainLink(entry: linkDict)
        #expect(link.linkType == .suffix)
        #expect(link.value == " TLS")
    }

    @Test func cnChainLinkDecodeMissingType() throws {
        let linkDict: [String: Any] = [
            "value": "example.com",
        ]
        let link = try CNChainLink(entry: linkDict)
        #expect(link.linkType == .exact)
        #expect(link.value == "example.com")
    }

    @Test func cnChainLinkDecodeMissingValue() throws {
        let linkDict: [String: Any] = [
            "type": "exact",
        ]
        #expect(throws: CNParseError.missingValue("value")) {
            _ = try CNChainLink(entry: linkDict)
        }
    }

    @Test func cnChainLinkDecodeBadType() throws {
        let linkDict: [String: Any] = [
            "type": "notAValidType",
            "value": "example.com",
        ]
        #expect(throws: CNParseError.invalidLinkType("notAValidType")) {
            _ = try CNChainLink(entry: linkDict)
        }
    }

    @Test func cnChainLinkExact() {
        let link = CNChainLink(.exact, "example.com")
        #expect(link.matches("example.com"))
        #expect(!link.matches("not example.com"))
    }

    @Test func cnChainLinkPrefix() {
        let link = CNChainLink(.prefix, "DigiCert C")
        #expect(link.matches("DigiCert C4"))
        #expect(!link.matches("DigiCert "))
    }

    @Test func cnChainLinkPrefixWithNumber() {
        let link = CNChainLink(.prefixWithNumber, "DigiCert C")
        #expect(link.matches("DigiCert C4"))
        #expect(!link.matches("DigiCert CA"))
        #expect(!link.matches("DigiCert"))
    }

    @Test func cnChainLinkSuffix() {
        let link = CNChainLink(.suffix, ".example.com")
        #expect(link.matches("www.example.com"))
        #expect(!link.matches("example.com"))
    }

    @Test func cnChainLinkDescription() {
        let link = CNChainLink(.exact, "example.com")
        #expect(link.description == "CNChainLink(.exact, \"example.com\")")
    }
}
