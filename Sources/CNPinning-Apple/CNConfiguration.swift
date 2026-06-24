// Copyright (c) 2026 AustinSoft.com

import Foundation

/**
 The configuration for pinning for a host or subdomain..
 */
public struct CNConfiguration: Equatable, Sendable, CustomStringConvertible, CNPinningMatches {
    let includesSubdomains: Bool
    let chainSet: [CNChain]
	
	/**
	 Initializes a configuration for a host or subdomain

	 - Parameters:
	   - includesSubdomains: Whether this configuration is for the host or subdomain rooted at this name
	   - chains: The chain(s) to describe the trusted connection
	 */
    public init(includesSubdomains: Bool = false, _ chains: [CNChain]) throws {
        guard !chains.isEmpty else {
            throw CNParseError.noChainsDefined
        }
        var seen: Set<CNChain> = []
        for (index, chain) in chains.enumerated() {
            guard seen.insert(chain).inserted else {
                throw CNParseError.duplicateChain(index)
            }
        }
        // If we get here, seen must include all of the chains that were defined.
        self.includesSubdomains = includesSubdomains
        chainSet = chains
    }

    init(entry: [String: Any]) throws {
        guard let includesSubdomains = entry["includesSubdomains"] as? Bool else {
            throw CNParseError.missingValue("includesSubdomains")
        }
        guard let chainData = entry["chainSet"] as? [[[String: Any]]] else {
            throw CNParseError.missingValue("chainSet")
        }

        let chains = try chainData.map(CNChain.init(entry:))
        try self.init(includesSubdomains: includesSubdomains, chains)
    }

    func matches(_ commonNames: [String]) -> Bool {
        chainSet.contains(where: { $0.matches(commonNames) })
    }

	public var description: String {
		"CNConfiguration(includesSubdomains: \(includesSubdomains), [\(chainSet.map(\.description).joined(separator: ", "))])"
	}
}
