// Copyright (c) 2026 AustinSoft.com

import Foundation
import Security

/// An error raised while parsing or validating a JWT/JWS header.
public enum JWTError: Error {
	/// The header's `alg` value is not one of the supported signature algorithms.
	case invalidAlgorithm

	/// The header's `typ` value is not `"JWT"`.
	case invalidType
}

enum JWTAlgorithm: String, Codable {
	// Symmetric, we won't support for this implementation
//	case hs256
//	case hs384
//	case hs512
	case rs256
	case rs384
	case rs512
	case es256
	case es384
	case es512
	case ps256
	case ps384
	case ps512
	// Deliberately not supported in this implementation
//	case none
	
	init(fromRawValue rawValue: String) throws {
		// The default for these values is uppercase in the standard, but our enums use lowercase.
		switch rawValue.lowercased() {
		case "rs256", "rs384", "rs512", "es256", "es384", "es512", "ps256", "ps384", "ps512":
			// These will always create a valid JWTAlgorithm, but uses a failing init.
			self = JWTAlgorithm(rawValue: rawValue)!
		default:
			throw JWTError.invalidAlgorithm
		}
	}
	
	init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		try self.init(fromRawValue: container.decode(String.self))
	}
	
	var secKeyAlgorithm: SecKeyAlgorithm {
		switch self {
		case .rs256: return .rsaSignatureMessagePKCS1v15SHA256
		case .rs384: return .rsaSignatureMessagePKCS1v15SHA384
		case .rs512: return .rsaSignatureMessagePKCS1v15SHA512
		case .es256: return .ecdsaSignatureMessageX962SHA256
		case .es384: return .ecdsaSignatureMessageX962SHA384
		case .es512: return .ecdsaSignatureMessageX962SHA512
		case .ps256: return .rsaSignatureMessagePSSSHA256
		case .ps384: return .rsaSignatureMessagePSSSHA384
		case .ps512: return .rsaSignatureMessagePSSSHA512
		}
	}
	
	var secKeyType: CFString {
		switch self {
		case .rs256, .rs384, .rs512:
			return kSecAttrKeyTypeRSA
		case .es256, .es384, .es512:
			return kSecAttrKeyTypeECSECPrimeRandom
		case .ps256, .ps384, .ps512:
			return kSecAttrKeyTypeRSA
		}
	}
	
	var secKeyLen: Int {
		switch self {
		case .rs256, .ps256:
			return 2048
		case .rs384, .ps384:
			return 3072
		case .rs512, .ps512:
			return 4096
		case .es256:
			return 256
		case .es384:
			return 384
		case .es512:
			return 521		// Yes, this is not a typo
		}
	}
}

struct JWTHeader: Codable {
	let alg: JWTAlgorithm
	let typ: String
	
	init (alg: JWTAlgorithm) {
		self.alg = alg
		self.typ = "JWT"
	}
	
	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.alg = try container.decode(JWTAlgorithm.self, forKey: .alg)
		self.typ = try container.decode(String.self, forKey: .typ)
		
		if self.typ != "JWT" {
			throw JWTError.invalidType
		}
	}
}

