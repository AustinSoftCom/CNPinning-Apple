// Copyright (c) 2026 AustinSoft.com

import Foundation

/**
 The array of `CNChainLink`s to be used as an option for prinning the connection to a server.
 */
public struct CNChain: Hashable, Sendable, CustomStringConvertible {
    let links: [CNChainLink]

	/**
	 The chain of links used to validate a connection.
	- Parameter chain: A chain of links for validating the connection
	 */
    public init(_ chain: [CNChainLink]) {
        // While developers define chains root-to-leaf, URLSession
        // passes us the chain leaf-to-root, so we'll reverse the
        // order when we save the chain so we don't have to
        // reverse the order of the URLSession-provided chain later.
        links = chain.reversed()
    }

    init(entry: [[String: Any]]) throws {
        // While developers define chains root-to-leaf, URLSession
        // passes us the chain leaf-to-root, so we'll reverse the
        // order when we save the chain so we don't have to
        // reverse the order of the URLSession-provided chain later.
        links = try entry.map(CNChainLink.init).reversed()
    }

    func matches(_ commonNames: [String]) -> Bool {
        // If the count of elements doesn't match between the two, then
        // this chain is never valid.
        guard commonNames.count == links.count else {
            return false
        }
        return zip(links, commonNames).allSatisfy { link, name in
            link.matches(name)
        }
    }

	public var description: String {
		// Display chains as entered, not as stored
		"CNChain([\(links.reversed().map(\.self.description).joined(separator: ", "))])"
	}
}

extension CNChain: Codable {
	public init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		self.links = try container.decode([CNChainLink].self).reversed()
	}
	
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(links.reversed())
	}
}
