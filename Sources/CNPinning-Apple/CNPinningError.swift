// Copyright (c) 2026 AustinSoft.com

import Foundation

/**
 Errors thrown when connecting to a server over a potentially-pinned connection
 */
public enum CNPinningError: Swift.Error, Equatable {
	/// The specified connection is not defined as pinned when calling `validate`
    case notPinned
	 
	/// The CNPinning instance was not configured for enterprise use.
	/// Initialize with `authenticationHost` and `policySigningKey` to enable enterprise policy support.
	case enterpriseNotConfigured
	
	/// An enterprise configuration is already active.
	/// Call `signOut()` before calling `applyEnterprisePolicy(with:)` again.
	case existingEnterpriseConfiguration
	
	/// No enterprise configuration is active.
	/// Call `applyEnterprisePolicy(with:)` before calling `refreshEnterprisePolicy(with:)`.
	case missingEnterpriseConfiguration
	
	/// The signed policy data is not a valid JWS format.
	/// Ensure the policy is a properly encoded JWS with header, payload, and signature separated by periods.
	case invalidJWSFormat
}
