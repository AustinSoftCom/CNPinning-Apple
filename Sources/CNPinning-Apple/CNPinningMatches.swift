//  Copyright © 2026 AustinSoft.com. All rights reserved worldwide.
//  Created by Glenn L. Austin on 6/23/26

import Foundation

protocol CNPinningMatches: Equatable {
	func matches(_ commonNames: [String]) -> Bool
}
//
//extension CNPinningMatches {
//	var eraseToAnyCNPinningMatches: AnyCNPinningMatches {
//		AnyCNPinningMatches(match: self)
//	}
//}
//
//struct AnyCNPinningMatches: Equatable {
//	let matcher: any CNPinningMatches
//	
//	init(match: any CNPinningMatches) {
//		self.matcher = match
//	}
//	
//	func matches(_ commonNames: [String]) -> Bool {
//		matcher.matches(commonNames)
//	}
//	
//	static func == (lhs: AnyCNPinningMatches, rhs: AnyCNPinningMatches) -> Bool {
//		lhs.matcher == rhs.matcher
//	}
//}
