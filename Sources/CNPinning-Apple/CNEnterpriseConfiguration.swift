// Copyright (c) 2026 AustinSoft.com

import Foundation

/**
 An enterprise-supplied pinning configuration for a single host (or the `"*"` wildcard), carried
 inside a signed enterprise policy.

 Unlike the app-baked ``CNConfiguration`` it carries no `includesSubdomains` flag-host selection is
 handled by the enclosing policy-and performs no non-empty/duplicate validation; it is simply the
 set of certificate chains the enterprise considers acceptable. A configuration matches when *any*
 of its chains matches.
 */
public struct CNEnterpriseConfiguration: Equatable, Sendable, CustomStringConvertible, CNPinningMatches {
	let chainSet: [CNChain]
	
	init (chainSet: [CNChain]) {
		self.chainSet = chainSet
	}
	
	func matches(_ commonNames: [String]) -> Bool {
		chainSet.contains(where: { $0.matches(commonNames) })
	}
	
	public var description: String {
		"CNEnterpriseConfiguration([\(chainSet.map(\.description).joined(separator: ", "))])"
	}
}

extension CNEnterpriseConfiguration: Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		self.chainSet = try container.decode([CNChain].self)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(chainSet)
	}
}
