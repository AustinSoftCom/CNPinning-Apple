// Copyright (c) 2026 AustinSoft.com

import Foundation


/**
 Errors throws during parsing of your configuration from your application's Info.plist
 */
public enum CNParseError: Swift.Error, Equatable {
	/// No Info.plist available, or the Info.plist is empty
    case noInfoPlist
	/// ATS has been configured for pinning, which would override CNPinning
    case atsConflict
	/// A required value was missing, value name is in the String
    case missingValue(String)
	/// An invalid linkType was requested
    case invalidLinkType(String)
	/// An invalid type was requested
    case invalidType(String)
	/// No chains were defined
    case noChainsDefined
	/// A duplicate chain was found in a CNConfiguration
    case duplicateChain(Int)
}
