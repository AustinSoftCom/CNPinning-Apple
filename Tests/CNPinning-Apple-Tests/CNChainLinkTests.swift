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
	
	@Test func cnChainLinkExact() throws {
		let link = try CNChainLink(.exact, "example.com")
		#expect(link.matches("example.com"))
		#expect(!link.matches("not example.com"))
	}
	
	@Test func cnChainLinkPrefix() throws {
		let link = try CNChainLink(.prefix, "DigiCert C")
		#expect(link.matches("DigiCert C4"))
		#expect(!link.matches("DigiCert "))
	}
	
	@Test func cnChainLinkPrefixWithNumber() throws {
		let link = try CNChainLink(.prefixWithNumber, "DigiCert C")
		#expect(link.matches("DigiCert C4"))
		#expect(!link.matches("DigiCert CA"))
		#expect(!link.matches("DigiCert"))
	}
	
	@Test func cnChainLinkSuffix() throws {
		let link = try CNChainLink(.suffix, ".example.com")
		#expect(link.matches("www.example.com"))
		#expect(!link.matches("example.com"))
	}
	
	@Test func cnChainLinkDescription() throws {
		let link = try CNChainLink(.exact, "example.com")
		#expect(link.description == "CNChainLink(.exact, \"example.com\")")
	}
	
	@Test func cnChainLinkExactEmptyValue() throws {
		#expect(throws: CNParseError.missingValue("exact value")) {
			_ = try CNChainLink(.exact, "")
		}
	}
	
	@Test func cnChainLinkPrefixEmptyValue() throws {
		#expect(throws: CNParseError.missingValue("prefix value")) {
			_ = try CNChainLink(.prefix, "")
		}
	}
	
	@Test func cnChainLinkPrefixWithNumbersEmptyValue() throws {
		#expect(throws: CNParseError.missingValue("prefixWithNumber value")) {
			_ = try CNChainLink(.prefixWithNumber, "")
		}
	}
	
	@Test func cnChainLinkSuffixEmptyValue() throws {
		#expect(throws: CNParseError.missingValue("suffix value")) {
			_ = try CNChainLink(.suffix, "")
		}
	}
	
	@Test func cnChainLinkParseExactEmptyValue() throws {
		let linkDict: [String: Any] = [
			"type": "exact",
			"value": "",
		]
		#expect(throws: CNParseError.missingValue("exact value")) {
			_ = try CNChainLink(entry: linkDict)
		}
	}
	
	@Test func cnChainLinkParsePrefixEmptyValue() throws {
		let linkDict: [String: Any] = [
			"type": "prefix",
			"value": "",
		]
		#expect(throws: CNParseError.missingValue("prefix value")) {
			_ = try CNChainLink(entry: linkDict)
		}
	}
	
	@Test func cnChainLinkParsePrefixWithNumbersEmptyValue() throws {
		let linkDict: [String: Any] = [
			"type": "prefixWithNumber",
			"value": "",
		]
		#expect(throws: CNParseError.missingValue("prefixWithNumber value")) {
			_ = try CNChainLink(entry: linkDict)
		}
	}
	
	@Test func cnChainLinkParseSuffixEmptyValue() throws {
		let linkDict: [String: Any] = [
			"type": "suffix",
			"value": "",
		]
		#expect(throws: CNParseError.missingValue("suffix value")) {
			_ = try CNChainLink(entry: linkDict)
		}
	}
	
	@Test func cnChainLinkLinkTypeInvalid() throws {
		struct InvalidLinkType: Encodable {
			let type: String
			let value: String
		}
		let invalidLink: InvalidLinkType = .init(type: "invalid", value: "value")
		let encoded = try JSONEncoder().encode(invalidLink)
		#expect(throws: DecodingError.self) {
			_ = try JSONDecoder().decode(CNChainLink.self, from: encoded)
		}
	}
	
	@Test func cnChainLinkNoLinkType() throws {
		struct InvalidLinkType: Encodable {
			let value: String
		}
		let invalidLink: InvalidLinkType = .init(value: "value")
		let encoded = try JSONEncoder().encode(invalidLink)
		#expect(try JSONDecoder().decode(CNChainLink.self, from: encoded).linkType == .exact)
	}
	
	@Test func cnChainLinkValueEmpty() throws {
		struct InvalidLinkType: Encodable {
			let type: String
			let value: String
		}
		let invalidLink: InvalidLinkType = .init(type: "exact", value: "")
		let encoded = try JSONEncoder().encode(invalidLink)
		#expect(throws: CNParseError.missingValue("exact value").self) {
			_ = try JSONDecoder().decode(CNChainLink.self, from: encoded)
		}
	}
}
