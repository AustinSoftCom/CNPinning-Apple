// Copyright (c) 2026 AustinSoft.com

import Foundation
import Security

enum JWT {
	case incoming(data: Data, publicKey: SecKey)
	case outgoing(alg: JWTAlgorithm, payload: Data, privateKey: SecKey)
	
	// Decode init
	init(from data: Data, verifiedWith key: SecKey) {
		self = .incoming(data: data, publicKey: key)
	}
	
	// Encode init
	init(alg: JWTAlgorithm, payload: Data, signedWith key: SecKey) {
		self = .outgoing(alg: alg, payload: payload, privateKey: key)
	}
	
	// Returns validated payload or nil
	var validatedPayload: Data? {
		guard case .incoming(let data, let key) = self else {
			return nil
		}
		
		// JWS is ASCII-safe by definition
		guard let jwsString = String(data: data, encoding: .ascii) else {
			return nil
		}
		
		let parts = jwsString.split(separator: ".", omittingEmptySubsequences: false)
		guard parts.count == 3 else {
			return nil
		}
		
		let headerB64 = parts[0]
		let payloadB64 = parts[1]
		let signatureB64 = parts[2]
		
		// Base64url decode each part
		guard let headerData = Data(base64URLEncoded: headerB64),
			  let payloadData = Data(base64URLEncoded: payloadB64),
			  let signatureData = Data(base64URLEncoded: signatureB64)
		else {
			return nil
		}
		
		guard let header = try? JSONDecoder().decode(JWTHeader.self, from: headerData) else {
			return nil
		}
		
		let message = Data((headerB64 + "." + payloadB64).utf8)
		let isValid = SecKeyVerifySignature(
			key,
			header.alg.secKeyAlgorithm,
			message as CFData,
			signatureData as CFData,
			nil
		)
		if !isValid {
			return nil
		}

		return payloadData
	}
	
	// Returns encoded JWT data
	var encoded: Data? {
		guard case .outgoing(let alg, let payload, let key) = self else {
			return nil
		}
		
		let payloadB64 = payload.base64URLEncodedString
		let header = JWTHeader(alg: alg)
		
		// None of the following two steps should *ever* fail, since JWTHeader is guaranteed
		// to be Codable, and headerB64 and payloadB64 should *always* encode back to UTF-8
		guard let headerB64 = try? JSONEncoder().encode(header).base64URLEncodedString,
			  let message = (headerB64 + "." + payloadB64).data(using: .utf8) else {
			return nil
		}
		
		guard let data = SecKeyCreateSignature(
			key,
			header.alg.secKeyAlgorithm,
			message as CFData,
			nil
		) as? Data else {
			return nil
		}
				
		return (headerB64 + "." + payloadB64 + "." + data.base64URLEncodedString).data(using: .utf8)
	}
}

extension Data {
	init?(base64URLEncoded string: any StringProtocol) {
		var base64 = string
			.replacingOccurrences(of: "-", with: "+")
			.replacingOccurrences(of: "_", with: "/")
		while base64.count % 4 != 0 {
			base64.append("=")
		}
		self.init(base64Encoded: base64)
	}
	
	var base64URLEncodedString: String {
		base64EncodedString()
			.replacingOccurrences(of: "+", with: "-")
			.replacingOccurrences(of: "/", with: "_")
			.replacingOccurrences(of: "=", with: "")
	}
}
