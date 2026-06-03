// Copyright (c) 2026 AustinSoft.com

import CNPinning_Apple
import Foundation

class TestCNPinningURLSessionDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let pinningManager = session.cnPinningManager,
              pinningManager.validate(challenge: challenge, completionHandler: completionHandler)
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
    }
}
