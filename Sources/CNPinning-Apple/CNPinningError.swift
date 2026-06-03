// Copyright (c) 2026 AustinSoft.com

import Foundation

/**
 Errors thrown when connecting to a server over a potentially-pinned connection
 */
public enum CNPinningError: Swift.Error, Equatable {
	/// The specified connection is not defined as pinned when calling `validate`
    case notPinned
}
