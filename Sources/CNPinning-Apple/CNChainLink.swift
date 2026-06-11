// Copyright (c) 2026 AustinSoft.com

import Foundation

/**
 An X.509 commonName to use for a link in the certificate validation chain. All strings are case-sensitive!
 */
public struct CNChainLink: Hashable, Equatable, Sendable, CustomStringConvertible {
	/// The kind of matching to perform between a link's `value` and a certificate's commonName.
    public enum LinkType: String, Hashable, Equatable, Sendable {
		/// The certificate commonName must *match* this string
        case exact
		/// The certificate commonName must *start* with this string
        case prefix
		/// The certificate commonName must *start* with this string, and end with one or more digits
        case prefixWithNumber
		/// The certificate commonName must *end* with this string
        case suffix
    }

    let linkType: LinkType
    let value: String

	/**
	 Defines a link in the chain for validating a connection
	 
	 - Parameters:
		- linkType: the kind of  matching to use for this link
		- value: the value to match
	 */

    public init(_ linkType: LinkType, _ value: String) throws {
        self.linkType = linkType
        self.value = value
		if value.isEmpty {
			throw CNParseError.missingValue("\(linkType.rawValue) value")
		}
    }

    init(entry: [String: Any]) throws {
        guard let value = entry["value"] as? String else {
            throw CNParseError.missingValue("value")
        }
        self.value = value

        if let linkTypeString = entry["type"] as? String {
            guard let parsed = LinkType(rawValue: linkTypeString) else {
                throw CNParseError.invalidLinkType(linkTypeString)
            }
            linkType = parsed
        } else {
#if DEBUG
			FileHandle.standardError.write(Data("CNChainLink: missing type for \(value), defaulting to .exact\n".utf8))
#endif
            linkType = .exact
        }
		if value.isEmpty {
			throw CNParseError.missingValue("\(linkType.rawValue) value")
		}
    }

    func matches(_ commonName: String) -> Bool {
        switch linkType {
        case .exact:
            return commonName == value

        case .prefix:
            return commonName.hasPrefix(value)

        case .prefixWithNumber:
            guard commonName.hasPrefix(value) else { return false }
            let suffix = commonName.dropFirst(value.count)
            return !suffix.isEmpty && suffix.allSatisfy(\.isNumber)

        case .suffix:
            return commonName.hasSuffix(value)
        }
    }

	public var description: String {
		"CNChainLink(.\(linkType.rawValue), \"\(value)\")"
	}
}
