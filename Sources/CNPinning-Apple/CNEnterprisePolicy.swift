// Copyright (c) 2026 AustinSoft.com

import Foundation

struct CNEnterprisePolicy: Equatable, Sendable, CustomStringConvertible {
	let issuedAt: Date
	let expirationDate: Date
	let configuration: [String: CNEnterpriseConfiguration]
	
	enum MatchType: Equatable {
		case match(CNEnterpriseConfiguration)
		case wildcard(CNEnterpriseConfiguration)
		
		static func == (lhs: MatchType, rhs: MatchType) -> Bool {
			switch (lhs, rhs) {
			case (.match(let lhs), .match(let rhs)):
				return lhs == rhs
			case (.wildcard(let lhs), .wildcard(let rhs)):
				return lhs == rhs
			default:
				return false
			}
		}
	}
	
	init(issuedAt: Date, expirationDate: Date, configuration: [String: CNEnterpriseConfiguration]) {
		self.issuedAt = Date(timeIntervalSince1970: TimeInterval(Int(issuedAt.timeIntervalSince1970)))
		self.expirationDate = Date(timeIntervalSince1970: TimeInterval(Int(expirationDate.timeIntervalSince1970)))
		self.configuration = configuration
	}
	
	/// Returns the enterprise configuration that applies to `host` at `date`: `nil` if the policy is
	/// not valid at `date` (outside its `[iat, exp)` window), otherwise an exact host match, the
	/// `"*"` wildcard, or `nil`.
	///
	/// The validity gate is enforced here so an expired or not-yet-valid policy can never contribute
	/// its mappings, regardless of the caller.
	func getConfiguration(for host: String, at date: Date) -> MatchType? {
		guard isValid(at: date) else {
			return nil
		}
		if let configuration = configuration[host] {
			return .match(configuration)
		} else if let configuration = configuration["*"] {
			return .wildcard(configuration)
		} else {
			return nil
		}
	}

	/// Returns whether the policy is in effect at `date`-that is, whether it falls within the
	/// half-open `[issuedAt, expirationDate)` window: valid from `iat` (inclusive) until `exp`
	/// (exclusive), per the JWT `exp` convention.
	func isValid(at date: Date) -> Bool {
		issuedAt <= date && date < expirationDate
	}

	public var description: String {
		let configDescription = configuration
			.map { "\"\($0.key)\": \($0.value)" }
			.joined(separator: ", ")
		return "CNEnterprisePolicy(issuedAt: \(issuedAt), expires: \(expirationDate), configuration: [\(configDescription)])"
	}
}

extension CNEnterprisePolicy: Codable {
	enum CodingKeys: String, CodingKey {
		case issuedAt = "iat"
		case expirationDate = "exp"
	}
	
	struct PinKey: CodingKey {
		let stringValue: String
		var intValue: Int? { nil }
		
		init?(stringValue: String) {
			self.stringValue = stringValue
		}
		
		init?(intValue: Int) {
			nil
		}
	}
	
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let issuedAtSec = try container.decode(Int.self, forKey: .issuedAt)
		let expirationDateSec = try container.decode(Int.self, forKey: .expirationDate)
		
		issuedAt = Date(timeIntervalSince1970: TimeInterval(issuedAtSec))
		expirationDate = Date(timeIntervalSince1970: TimeInterval(expirationDateSec))
		
		let dynamic = try decoder.container(keyedBy: PinKey.self)
		var result: [String: CNEnterpriseConfiguration] = [:]
		for key in dynamic.allKeys {
			guard key.stringValue != "iat",
				  key.stringValue != "exp"
			else {
				continue
			}
			
			result[key.stringValue] = try dynamic.decode(CNEnterpriseConfiguration.self, forKey: key)
		}
		
		configuration = result
	}
	
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(issuedAt.timeIntervalSince1970, forKey: .issuedAt)
		try container.encode(expirationDate.timeIntervalSince1970, forKey: .expirationDate)
		
		var dynamic = encoder.container(keyedBy: PinKey.self)
		for (key, value) in configuration {
			let dynamicKey = PinKey(stringValue: key)!
			try dynamic.encode(value, forKey: dynamicKey)
		}
	}
}
