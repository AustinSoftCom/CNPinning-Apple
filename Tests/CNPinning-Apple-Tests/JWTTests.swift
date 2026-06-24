//  Copyright © 2026 AustinSoft.com. All rights reserved worldwide.
//  Created by Glenn L. Austin on 6/23/26

import Testing
import Foundation
import Security
@testable import CNPinning_Apple

struct JWTTests {
	@Test func testJWTAlgorithmInfo() {
		#expect(JWTAlgorithm.rs256.rawValue == "rs256", "Should be able to get the correct raw value")
		#expect(JWTAlgorithm.rs384.rawValue == "rs384", "Should be able to get the correct raw value")
		#expect(JWTAlgorithm.rs512.rawValue == "rs512", "Should be able to get the correct raw value")
		#expect(JWTAlgorithm.es256.rawValue == "es256", "Should be able to get the correct raw value")
		#expect(JWTAlgorithm.es384.rawValue == "es384", "Should be able to get the correct raw value")
		#expect(JWTAlgorithm.es512.rawValue == "es512", "Should be able to get the correct raw value")
		#expect(JWTAlgorithm.ps256.rawValue == "ps256", "Should be able to get the correct raw value")
		#expect(JWTAlgorithm.ps384.rawValue == "ps384", "Should be able to get the correct raw value")
		#expect(JWTAlgorithm.ps512.rawValue == "ps512", "Should be able to get the correct raw value")
		
		#expect(JWTAlgorithm.rs256.secKeyAlgorithm == .rsaSignatureMessagePKCS1v15SHA256, "Should be able to get the correct algorithm")
		#expect(JWTAlgorithm.rs384.secKeyAlgorithm == .rsaSignatureMessagePKCS1v15SHA384, "Should be able to get the correct algorithm")
		#expect(JWTAlgorithm.rs512.secKeyAlgorithm == .rsaSignatureMessagePKCS1v15SHA512, "Should be able to get the correct algorithm")
		#expect(JWTAlgorithm.es256.secKeyAlgorithm == .ecdsaSignatureMessageX962SHA256, "Should be able to get the correct algorithm")
		#expect(JWTAlgorithm.es384.secKeyAlgorithm == .ecdsaSignatureMessageX962SHA384, "Should be able to get the correct algorithm")
		#expect(JWTAlgorithm.es512.secKeyAlgorithm == .ecdsaSignatureMessageX962SHA512, "Should be able to get the correct algorithm")
		#expect(JWTAlgorithm.ps256.secKeyAlgorithm == .rsaSignatureMessagePSSSHA256, "Should be able to get the correct algorithm")
		#expect(JWTAlgorithm.ps384.secKeyAlgorithm == .rsaSignatureMessagePSSSHA384, "Should be able to get the correct algorithm")
		#expect(JWTAlgorithm.ps512.secKeyAlgorithm == .rsaSignatureMessagePSSSHA512, "Should be able to get the correct algorithm")
		
		#expect(JWTAlgorithm.rs256.secKeyType == kSecAttrKeyTypeRSA, "Should be able to get the correct secKeyType")
		#expect(JWTAlgorithm.rs384.secKeyType == kSecAttrKeyTypeRSA, "Should be able to get the correct secKeyType")
		#expect(JWTAlgorithm.rs512.secKeyType == kSecAttrKeyTypeRSA, "Should be able to get the correct secKeyType")
		#expect(JWTAlgorithm.es256.secKeyType == kSecAttrKeyTypeECSECPrimeRandom, "Should be able to get the correct secKeyType")
		#expect(JWTAlgorithm.es384.secKeyType == kSecAttrKeyTypeECSECPrimeRandom, "Should be able to get the correct secKeyType")
		#expect(JWTAlgorithm.es512.secKeyType == kSecAttrKeyTypeECSECPrimeRandom, "Should be able to get the correct secKeyType")
		#expect(JWTAlgorithm.ps256.secKeyType == kSecAttrKeyTypeRSA, "Should be able to get the correct secKeyType")
		#expect(JWTAlgorithm.ps384.secKeyType == kSecAttrKeyTypeRSA, "Should be able to get the correct secKeyType")
		#expect(JWTAlgorithm.ps512.secKeyType == kSecAttrKeyTypeRSA, "Should be able to get the correct secKeyType")
		
		#expect(JWTAlgorithm.rs256.secKeyLen == 2048, "Should be able to get the correct secKeyType")
		#expect(JWTAlgorithm.rs384.secKeyLen == 3072, "Should be able to get the correct secKeyType")
		#expect(JWTAlgorithm.rs512.secKeyLen == 4096, "Should be able to get the correct secKeyType")
		#expect(JWTAlgorithm.es256.secKeyLen == 256, "Should be able to get the correct secKeyType")
		#expect(JWTAlgorithm.es384.secKeyLen == 384, "Should be able to get the correct secKeyType")
		#expect(JWTAlgorithm.es512.secKeyLen == 521, "Should be able to get the correct secKeyType")
		#expect(JWTAlgorithm.ps256.secKeyLen == 2048, "Should be able to get the correct secKeyType")
		#expect(JWTAlgorithm.ps384.secKeyLen == 3072, "Should be able to get the correct secKeyType")
		#expect(JWTAlgorithm.ps512.secKeyLen == 4096, "Should be able to get the correct secKeyType")
	}
	
	@Test func jwtDecodingOutgoing() throws {
		let (privateKey, _) = try generateTestKeypair(alg: .rs256)
		let data = try #require("Hello, world!".data(using: .utf8))
		let jwt = JWT(alg: .rs256, payload: data, signedWith: privateKey)
		#expect(jwt.validatedPayload == nil)
	}
	
	@Test func jwtDecodingNonASCII() throws {
		let (_, publicKey) = try generateTestKeypair(alg: .rs256)
		let data = try #require("🤞.2.3".data(using: .utf8))
		let jwt = JWT(from: data, verifiedWith: publicKey)
		#expect(jwt.validatedPayload == nil)
	}
	
	@Test func jwtDecodingNotEnoughParts() throws {
		let (_, publicKey) = try generateTestKeypair(alg: .rs256)
		let data = try #require("1.2".data(using: .utf8))
		let jwt = JWT(from: data, verifiedWith: publicKey)
		#expect(jwt.validatedPayload == nil)
	}
	
	@Test func jwtDecodingTooManyParts() throws {
		let (_, publicKey) = try generateTestKeypair(alg: .rs256)
		let data = try #require("1.2.3.4".data(using: .utf8))
		let jwt = JWT(from: data, verifiedWith: publicKey)
		#expect(jwt.validatedPayload == nil)
	}
	
	@Test func jwtDecodingNotJWTHeader() throws {
		let (_, publicKey) = try generateTestKeypair(alg: .rs256)
		let part1 = try #require("1".data(using: .utf8)?.base64URLEncodedString)
		let part3 = try #require("3".data(using: .utf8)?.base64URLEncodedString)
		let data = try #require((part1 + ".." + part3).data(using: .utf8))
		let jwt = JWT(from: data, verifiedWith: publicKey)
		#expect(jwt.validatedPayload == nil)
	}
	
	@Test func jwtDecodingOnlyJWTHeader() throws {
		let (_, publicKey) = try generateTestKeypair(alg: .rs256)
		let part1 = try JSONEncoder().encode(JWTHeader(alg: .rs256)).base64URLEncodedString
		let part3 = try #require("3".data(using: .utf8)?.base64URLEncodedString)
		let data = try #require((part1 + ".." + part3).data(using: .utf8))
		let jwt = JWT(from: data, verifiedWith: publicKey)
		#expect(jwt.validatedPayload == nil)
	}
	
	@Test func jwtRoundTrip() throws {
		let (privateKey, publicKey) = try generateTestKeypair(alg: .rs256)
		let data = try #require("Hello, world!".data(using: .utf8))
		let jwt = JWT(alg: .rs256, payload: data, signedWith: privateKey)
		let encodedJWT = try #require(jwt.encoded)
		
		let decodedJWT = JWT(from: encodedJWT, verifiedWith: publicKey)
		let outData = try #require(decodedJWT.validatedPayload)
		
		#expect(outData == data)
	}
	
	@Test func jwtEncodingIncoming() throws {
		let (_, publicKey) = try generateTestKeypair(alg: .rs256)
		let data = try #require("Hello, world!".data(using: .utf8))
		let jwt = JWT(from: data, verifiedWith: publicKey)
		#expect(jwt.encoded == nil)
	}
	
	@Test func jwtDecodingBadIncoming() throws {
		let (privateKey, publicKey) = try generateTestKeypair(alg: .rs256)
		let data = try #require("Hello, world!".data(using: .utf8))
		let jwt = JWT(alg: .rs256, payload: data, signedWith: privateKey)
		let jwtData = try #require(jwt.encoded)
		let jwtString = try #require(String(data: jwtData, encoding: .utf8))
		var parts = jwtString.split(separator: ".")
		parts[2] = "notbase64"
		let badJWTData = try #require(parts.joined(separator: ".").data(using: .utf8))
		#expect(JWT(from: badJWTData, verifiedWith: publicKey).validatedPayload == nil)
	}

	@Test func jwtEncodingBadKey() throws {
		let (_, publicKey) = try generateTestKeypair(alg: .es256)
		let data = try #require("Hello, world!".data(using: .utf8))
		let jwt = JWT(alg: .rs256, payload: data, signedWith: publicKey)
		#expect(jwt.encoded == nil)
	}
	
	@Test func invalidJWTAlgorithm() throws {
		#expect(throws: JWTError.invalidAlgorithm) {
			try JWTAlgorithm(fromRawValue: "badAlgorithnValue")
		}
	}
	
	@Test(arguments: ["rs256", "rs384", "rs512", "es256", "es384", "es512", "ps256", "ps384", "ps512"])
	func validJWTAlgorithms(_ algName: String) throws {
		_ = try JWTAlgorithm(fromRawValue: algName)
	}
	
	@Test func invalidJWTHeader() throws {
		struct BadJWTHeader: Codable {
			let alg: JWTAlgorithm
			let typ: String
		}
		
		let badJWTHeader = BadJWTHeader(alg: .rs256, typ: "BAD!")
		let encoded = try JSONEncoder().encode(badJWTHeader)
		#expect(throws: JWTError.invalidType) {
			_ = try JSONDecoder().decode(JWTHeader.self, from: encoded)
		}
	}
}

enum KeyError: Error {
	case publicKeyExtractionFailed
}

// Test utility - not for production use
func generateTestKeypair(alg: JWTAlgorithm) throws -> (privateKey: SecKey, publicKey: SecKey) {
	let attributes: [String: Any] = [
		kSecAttrKeyType as String: alg.secKeyType,
		kSecAttrKeySizeInBits as String: alg.secKeyLen,
		kSecPrivateKeyAttrs as String: [
			kSecAttrIsPermanent as String: false  // no keychain storage
		]
	]
	
	var error: Unmanaged<CFError>?
	guard let privateKey = SecKeyCreateRandomKey(
		attributes as CFDictionary,
		&error
	) else {
		throw error!.takeRetainedValue()
	}
	guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
		throw KeyError.publicKeyExtractionFailed
	}
	return (privateKey, publicKey)
}
