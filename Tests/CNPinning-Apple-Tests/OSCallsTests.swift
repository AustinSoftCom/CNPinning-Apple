// Copyright (c) 2026 AustinSoft.com

@testable import CNPinning_Apple
import Foundation
import Testing

// MARK: OSCalls tests

final class TestProtocolSender: NSObject, URLAuthenticationChallengeSender, Sendable {
    func use(_: URLCredential, for _: URLAuthenticationChallenge) {
        #expect(Bool(false))
    }

    func continueWithoutCredential(for _: URLAuthenticationChallenge) {
        #expect(Bool(false))
    }

    func cancel(_: URLAuthenticationChallenge) {
        #expect(Bool(false))
    }
}

func buildAuthenticationChallenge(for hostname: String) -> URLAuthenticationChallenge {
    let space = URLProtectionSpace(host: hostname, port: 443, protocol: nil, realm: nil, authenticationMethod: nil)

    return URLAuthenticationChallenge(
        protectionSpace: space,
        proposedCredential: nil,
        previousFailureCount: 0,
        failureResponse: nil,
        error: nil,
        sender: TestProtocolSender()
    )
}

struct OSCallsTests {
    /// This test exists to verify the code for RealCNSecTrust
    @Test func osCallsRealCNSecTrust() throws {
        let trust = try #require(RealCNSecTrust(trust: " "))
        #expect(trust.trust == " ")
    }

    /// This test exists to verify the code for RealCNSecTrust
    @Test func osCallsRealCNSecCertificate() throws {
        let certificate = try #require(RealCNSecCertificate(certificate: " "))
        #expect(certificate.certificate == " ")
    }

    //	@Test func osCallsRealCNSecCertificate() throws {
    //		#expect(RealCNSecCertificate(certificate: nil) != nil)
    //	}
//
    //	@Test func osCallsLoadInfoPlist() throws {
    //		let osCalls = OSCalls.make()
    //		let info = try #require(osCalls.getInfoDictionary())
    //		// These are settings that seem to be default values for testing
    //		if let atsTesting = info["NSAppTransportSecurity"] as? [String: Any] {
    //			#expect((atsTesting["NSAllowsArbitraryLoads"] as? Bool) == true)
    //			#expect(atsTesting["NSPinnedDomains"] == nil)
    //		}
    //	}
//
    //	@Test func osCallsGetServerTrust() throws {
    //		let osCalls = OSCalls.make()
    //		#expect(osCalls.getServerTrust(buildAuthenticationChallenge(for: "www.austinsoft.com")) == nil)
    //	}
//
    //	@Test func osCallsGetCertificateChain() throws {
    //		let osCalls = OSCalls.make()
    //		#expect(osCalls.getCertificateChain(nil) == nil)
    //	}
//
    //	@Test func osCallsGetCommonName() throws {
    //		let osCalls = OSCalls.make()
    //		#expect(osCalls.getCommonName(nil) == nil)
    //	}
}
