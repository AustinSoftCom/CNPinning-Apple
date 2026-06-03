// Copyright (c) 2026 AustinSoft.com

import CNPinning_Apple
import SwiftUI

@main
struct TestCNPinningApp: App {
    static let pinnedSession: URLSession = {
        do {
            let pinningManager = try CNPinningManager()
            let delegate = TestCNPinningURLSessionDelegate()

            let configuration: URLSessionConfiguration = .default
#if DEBUG
			configuration.urlCache = nil		// Necessary evil when *testing* pinning, not necessary for production
#endif
            let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
            session.cnPinningManager = pinningManager
            return session
        } catch {
            fatalError("Unable to initialize the pinnedSession URLSession: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
