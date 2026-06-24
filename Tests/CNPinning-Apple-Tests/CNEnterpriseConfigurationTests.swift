//  Copyright © 2026 AustinSoft.com. All rights reserved worldwide.
//  Created by Glenn L. Austin on 6/23/26

import Testing
import Foundation
@testable import CNPinning_Apple

struct CNEnterpriseConfigurationTests {
	@Test func enterpriseConfigDiscription() async throws {
		let enterprisePolicy = try CNEnterprisePolicy(
			issuedAt: Date(timeIntervalSince1970: 1_000_000),
			expirationDate: Date(timeIntervalSince1970: 2_000_000),
			configuration: [
				"*": .init(
					chainSet: [
						.init([
							.init(.exact, "Certificate Authority Name"),
							.init(.exact, "Certificate Intermediate 1"),
							.init(.exact, "Certificate Intermediate 2"),
							.init(.suffix, ".example.com"),
						])
					]
				)
			]
		)
		
		#expect(enterprisePolicy.description == "CNEnterprisePolicy(issuedAt: 1970-01-12 13:46:40 +0000, expires: 1970-01-24 03:33:20 +0000, configuration: [\"*\": CNEnterpriseConfiguration([CNChain([CNChainLink(.exact, \"Certificate Authority Name\"), CNChainLink(.exact, \"Certificate Intermediate 1\"), CNChainLink(.exact, \"Certificate Intermediate 2\"), CNChainLink(.suffix, \".example.com\")])])])")
	}
	
	@Test func enterpriseConfigMatchesHost() async throws {
		let enterprisePolicy = try CNEnterprisePolicy(
			issuedAt: Date(timeIntervalSince1970: 1_000_000),
			expirationDate: Date(timeIntervalSince1970: 2_000_000),
			configuration: [
				"sub.example.com": .init(
					chainSet: [
						.init([
							.init(.exact, "Certificate Authority Name"),
							.init(.exact, "Certificate Intermediate 1"),
							.init(.exact, "Certificate Intermediate 2"),
							.init(.suffix, ".example.com"),
						])
					]
				)
			]
		)
		
		let configuration = try #require(enterprisePolicy.getConfiguration(for: "sub.example.com", at: Date(timeIntervalSince1970: 1_500_000)))
		let expect = try #require(enterprisePolicy.configuration["sub.example.com"])
		#expect(configuration == .match(expect))
	}
	
	@Test func enterpriseConfigMatchesWildcard() async throws {
		let enterprisePolicy = try CNEnterprisePolicy(
			issuedAt: Date(timeIntervalSince1970: 1_000_000),
			expirationDate: Date(timeIntervalSince1970: 2_000_000),
			configuration: [
				"*": .init(
					chainSet: [
						.init([
							.init(.exact, "Certificate Authority Name"),
							.init(.exact, "Certificate Intermediate 1"),
							.init(.exact, "Certificate Intermediate 2"),
							.init(.suffix, ".example.com"),
						])
					]
				)
			]
		)
		
		let configuration = try #require(enterprisePolicy.getConfiguration(for: "sub.example.com", at: Date(timeIntervalSince1970: 1_500_000)))
		let expect = try #require(enterprisePolicy.configuration["*"])
		#expect(configuration == .wildcard(expect))
	}
	
	@Test func enterpriseConfigMatchesNothing() async throws {
		let enterprisePolicy = try CNEnterprisePolicy(
			issuedAt: Date(timeIntervalSince1970: 1_000_000),
			expirationDate: Date(timeIntervalSince1970: 2_000_000),
			configuration: [
				"example.com": .init(
					chainSet: [
						.init([
							.init(.exact, "Certificate Authority Name"),
							.init(.exact, "Certificate Intermediate 1"),
							.init(.exact, "Certificate Intermediate 2"),
							.init(.suffix, ".example.com"),
						])
					]
				)
			]
		)
		
		#expect(enterprisePolicy.getConfiguration(for: "sub.example.com", at: Date(timeIntervalSince1970: 1_500_000)) == nil)
	}

	@Test func enterpriseConfigOutsideWindowReturnsNil() throws {
		let enterprisePolicy = try CNEnterprisePolicy(
			issuedAt: Date(timeIntervalSince1970: 1_000_000),
			expirationDate: Date(timeIntervalSince1970: 2_000_000),
			configuration: [
				"*": .init(chainSet: [.init([.init(.suffix, ".example.com")])])
			]
		)
		// The policy gates on its own [1_000_000, 2_000_000) window: outside it, even the wildcard
		// yields no configuration.
		#expect(enterprisePolicy.getConfiguration(for: "sub.example.com", at: Date(timeIntervalSince1970: 2_000_000)) == nil)
		#expect(enterprisePolicy.getConfiguration(for: "sub.example.com", at: Date(timeIntervalSince1970: 999_999)) == nil)
	}

	@Test func enterpriseConfigEqualsNotMatching() async throws {
		let enterprisePolicy = try CNEnterprisePolicy(
			issuedAt: Date(timeIntervalSince1970: 1_000_000),
			expirationDate: Date(timeIntervalSince1970: 2_000_000),
			configuration: [
				"example.com": .init(
					chainSet: [
						.init([
							.init(.exact, "Certificate Authority Name"),
							.init(.exact, "Certificate Intermediate 1"),
							.init(.exact, "Certificate Intermediate 2"),
							.init(.suffix, ".example.com"),
						])
					]
				),
				"sub.example.com": .init(
					chainSet: [
						.init([
							.init(.exact, "Sub Certificate Authority Name"),
							.init(.exact, "Certificate Intermediate 1"),
							.init(.exact, "Certificate Intermediate 2"),
							.init(.suffix, ".example.com"),
						])
					]
				),
			]
		)
		
		let notMatching = try #require(enterprisePolicy.configuration["sub.example.com"])
		#expect(enterprisePolicy.getConfiguration(for: "example.com", at: Date(timeIntervalSince1970: 1_500_000)) != .match(notMatching))
	}
	
	@Test func configurationChainExactMatch() throws {
		let enterpriseConfiguration = try CNEnterpriseConfiguration(
			chainSet: [
				.init([
					.init(.exact, "Certificate Authority Name"),
					.init(.exact, "Certificate Intermediate 1"),
					.init(.exact, "Certificate Intermediate 2"),
					.init(.suffix, ".example.com"),
				])
			]
		)
		
		// Remember, names are in reverse order because that's how URLSession passes them to us!
		var names = try #require(enterpriseConfiguration.chainSet.first?.links.map(\.value)).reversed().map({ $0 })
		names.removeLast()
		names.append("www.example.com")
		#expect(names == ["Certificate Authority Name", "Certificate Intermediate 1", "Certificate Intermediate 2", "www.example.com"])
		// Remember, names are passed in reverse order because that's how URLSession passes them to us!
		#expect(enterpriseConfiguration.matches(names.reversed()))
		names.removeLast()
		names.append("example.com")
		#expect(enterpriseConfiguration.matches(names.reversed()) == false)
	}
	
	@Test func EnterpriseMatchTypeNoMatch() throws {
		let enterprisePolicyLeft = try CNEnterprisePolicy(
			issuedAt: Date(timeIntervalSince1970: 1_000_000),
			expirationDate: Date(timeIntervalSince1970: 2_000_000),
			configuration: [
				"example.com": .init(
					chainSet: [
						.init([
							.init(.exact, "Certificate Authority Name"),
							.init(.exact, "Certificate Intermediate 1"),
							.init(.exact, "Certificate Intermediate 2"),
							.init(.suffix, ".example.com"),
						])
					]
				)
			]
		)
		let enterprisePolicyRight = try CNEnterprisePolicy(
			issuedAt: Date(timeIntervalSince1970: 1_000_000),
			expirationDate: Date(timeIntervalSince1970: 2_000_000),
			configuration: [
				"*": .init(
					chainSet: [
						.init([
							.init(.exact, "Certificate Authority Name"),
							.init(.exact, "Certificate Intermediate 1"),
							.init(.exact, "Certificate Intermediate 2"),
							.init(.suffix, ".example.com"),
						])
					]
				)
			]
		)
		
		let left = try #require(enterprisePolicyLeft.configuration["example.com"])
		let right = try #require(enterprisePolicyRight.configuration["*"])
			
		#expect(CNEnterprisePolicy.MatchType.match(left) != CNEnterprisePolicy.MatchType.wildcard(right))
	}
	
	@Test func pinKeyIntValueInitFails() {
		#expect(CNEnterprisePolicy.PinKey(intValue: 0) == nil)
	}
	
	@Test func pinKeyIntValueValueNil() throws {
		let key = try #require(CNEnterprisePolicy.PinKey(stringValue: "Foo"))
		#expect(key.intValue == nil)
	}
}
