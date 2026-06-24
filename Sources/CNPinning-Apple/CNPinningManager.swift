// Copyright (c) 2026 AustinSoft.com

import Foundation
import Synchronization
@preconcurrency import Security

/**
 The main implementation of CNPinningManager.

 You create one of these to use commonName pinning on a connection. In your URLSessionDelegate or
 URLSessionTaskDelegate, you will call `validate` on the passed `URLAuthenticationChallenge`
 to allow CNPinningManager to continue or cancel the secure network connection.
 */
public final class CNPinningManager: Sendable, CustomStringConvertible {
	let configuration: [String: CNConfiguration]
	let descriptionOrder: [String]?
	let osCalls: OSCalls
	let authenticationHost: String?
	let policySigningKey: SecKey?
	let enterpriseConfigurations: Mutex<CNEnterprisePolicy?> = .init(nil)

	enum InitType {
		case infoPlist
		case configuration(descriptionOrder: [String]? = nil, configuration: [String: CNConfiguration])
	}

	/**
	 Initialize CNPinningManager from your application's Info.plist

	 Initialize CNPinningManager from the `CNPinningManager` entry in the
	 application's Info.plist, parses it-noting any problems, and then passing the
	 result to the main init, which will configure CNPinningManager.
	 */
	public convenience init() throws {
		try self.init(initType: .infoPlist, osCalls: OSCalls())
	}

	/**
	 Initialize CNPinningManager from your application's Info.plist with the authenticationHost and policySigningKey
	 
	 Initialize CNPinningManager from the `CNPinningManager` entry in the
	 application's Info.plist, parses it-noting any problems, and then passing the
	 result to the main init, which will configure CNPinningManager.
	 - Parameters:
	 - authenticationHost: The hostname for your authentication-only host
	 - policySigningKey:  The public key used to validate the additions to your pinning
	 */
	public convenience init(authenticationHost: String, policySigningKey: SecKey) throws {
		try self.init(
			initType: .infoPlist,
			authenticationHost: authenticationHost,
			policySigningKey: policySigningKey,
			osCalls: OSCalls())
	}

	convenience init(authenticationHost: String, policySigningKey: SecKey, osCalls: OSCalls) throws {
		try self.init(
			initType: .infoPlist,
			authenticationHost: authenticationHost,
			policySigningKey: policySigningKey,
			osCalls: osCalls)
	}

	/**
	 Initialize CNPinningManager with the specified configuration

	 Initialize CNPinningManager passing the specified configuration to the
	 main init, which will configure CNPinningManager.

	 - Parameters
	 - configuration: The CNConfiguration to use for this CNPinningManager
	 */
	public convenience init(configuration: [String: CNConfiguration]) throws {
		try self.init(initType: .configuration(configuration: configuration), osCalls: OSCalls())
	}

	/**
	 Initialize CNPinningManager with the specified configuration and enterprise support

	 Initialize CNPinningManager passing the specified configuration to the
	 main init, which will configure CNPinningManager, and enable enterprise
	 pinning via ``applyEnterprisePolicy(with:)``.

	 - Parameters:
	 - authenticationHost: The hostname for your authentication-only host, exempt from enterprise overrides
	 - policySigningKey: The public key used to validate signed enterprise policies
	 - configuration: The CNConfiguration to use for this CNPinningManager
	 */
	public convenience init(authenticationHost: String, policySigningKey: SecKey, configuration: [String: CNConfiguration]) throws {
		try self.init(
			initType: .configuration(configuration: configuration),
			authenticationHost: authenticationHost,
			policySigningKey: policySigningKey,
			osCalls: OSCalls())
	}

	convenience init(authenticationHost: String? = nil, policySigningKey: SecKey? = nil, configuration: [String: CNConfiguration], osCalls: OSCalls) throws {
		try self.init(
			initType: .configuration(configuration: configuration),
			authenticationHost: authenticationHost,
			policySigningKey: policySigningKey,
			osCalls: osCalls)
	}

	init(
		initType: InitType,
		authenticationHost: String? = nil,
		policySigningKey: SecKey? = nil,
		osCalls: OSCalls
	) throws {
		let configuration: [String: CNConfiguration]
		let descriptionOrder: [String]?
		switch initType {
		case .infoPlist:
			(descriptionOrder, configuration) = try Self.parseConfigurationDict(osCalls: osCalls)

		case .configuration(descriptionOrder: let passedDescriptionOrder, configuration: let passedConfiguration):
			// If we get a configuration, test whether ATS is enabled. This same test is
			// run in parseConfigurationDict(osCalls:) for the no-parameter constructor path.
			if Self.testForATSPinning(osCalls: osCalls) {
				throw CNParseError.atsConflict
			}
			descriptionOrder = passedDescriptionOrder
			configuration = passedConfiguration
		}

		self.osCalls = osCalls
		self.configuration = configuration
		self.descriptionOrder = descriptionOrder
		self.authenticationHost = authenticationHost
		self.policySigningKey = policySigningKey
	}

	convenience init(osCalls: OSCalls) throws {
		try self.init(initType: .infoPlist, osCalls: osCalls)
	}
	
	/// Configures enterprise pinning to support the additional pins that an
	/// enterprise can configure. Only call this after a successful login.
	///
	/// - Parameter signedPolicy: The signed JWT enterprise pinning configuration
	public func applyEnterprisePolicy(with signedPolicy: Data) throws {
		guard enterpriseConfigurations.withLock({ $0 }) == nil else {
			throw CNPinningError.existingEnterpriseConfiguration
		}
		try applyPolicy(with: signedPolicy)
	}
	
	/// Refreshes enterprise pinning to support the additional pins that an
	/// enterprise can configure.
	///
	/// - Parameter signedPolicy: The signed JWT enterprise pinning configuration
	public func refreshEnterprisePolicy(with signedPolicy: Data) throws {
		guard enterpriseConfigurations.withLock({ $0 }) != nil else {
			throw CNPinningError.missingEnterpriseConfiguration
		}
		try applyPolicy(with: signedPolicy)
	}
	
	/// Drops any active enterprise pinning policy, reverting to the app-baked configuration only.
	///
	/// Call this on logout. After signing out, ``applyEnterprisePolicy(with:)`` may be called again
	/// to install a new policy.
	public func signOut() {
		enterpriseConfigurations.withLock({ $0 = nil })
	}

	/// The issue date (the JWT `iat` claim) of the currently-active enterprise policy, or `nil` when
	/// no policy has been applied.
	public var enterprisePolicyIssuedAt: Date? {
		enterpriseConfigurations.withLock { $0?.issuedAt }
	}

	/// The expiration date (the JWT `exp` claim) of the currently-active enterprise policy, or `nil`
	/// when no policy has been applied.
	public var enterprisePolicyExpiry: Date? {
		enterpriseConfigurations.withLock { $0?.expirationDate }
	}

	func applyPolicy(with signedPolicy: Data) throws {
		guard authenticationHost != nil,
			  let policySigningKey else {
			throw CNPinningError.enterpriseNotConfigured
		}
		
		let jwt = JWT(from: signedPolicy, verifiedWith: policySigningKey)
		
		guard let payloadData = jwt.validatedPayload else {
			throw CNPinningError.invalidJWSFormat
		}
		
		let policy = try JSONDecoder().decode(CNEnterprisePolicy.self, from: payloadData)
		
		self.enterpriseConfigurations.withLock {
			$0 = policy
		}
	}

	static func testForATSPinning(osCalls: OSCalls) -> Bool {
		if let plist = osCalls.getInfoDictionary() {
			// Check to see if ATS has been configured for pinning
			if let atsConfigurationDict = plist["NSAppTransportSecurity"] as? [String: Any],
			   atsConfigurationDict["NSPinnedDomains"] as? [String: Any] != nil
			{
				return true
			}
		}
		return false
	}

	static func parseConfigurationDict(osCalls: OSCalls) throws -> ([String], [String: CNConfiguration]) {
		guard let plist = osCalls.getInfoDictionary(),
			  !plist.isEmpty else {
			throw CNParseError.noInfoPlist
		}
		// Check to see if ATS has been configured for pinning
		if testForATSPinning(osCalls: osCalls) {
			throw CNParseError.atsConflict
		}
		guard let pinningManagerDict = osCalls.getInfoDictionary()?["CNPinningManager"] as? [String: Any] else {
			throw CNParseError.missingValue("CNPinningManager")
		}
		guard let pinnedDomains = pinningManagerDict["PinnedDomains"] as? [String: Any] else {
			throw CNParseError.missingValue("PinnedDomains")
		}

		// Parse the Info.plist pins.
		var domainOrder: [String] = []
		var domainConfigurations: [String: CNConfiguration] = [:]
		for (domain, value) in pinnedDomains {
			guard let value = value as? [String: Any] else {
				throw CNParseError.invalidType(domain)
			}
			let configuration = try CNConfiguration(entry: value)
			domainConfigurations[domain] = configuration
			domainOrder.append(domain)
		}
		return (domainOrder, domainConfigurations)
	}

	func getConfiguration(for host: String) -> [any CNPinningMatches] {
		let baseMatch: CNConfiguration?
		if let exact = configuration[host] {
			baseMatch = exact
		} else {
			baseMatch = configuration
				.filter { domain, config in
					config.includesSubdomains && host.hasSuffix("." + domain)
				}
				.max(by: { $0.key.count < $1.key.count })?
				.value
		}
		
		// If we don't have a baseMatch for the host return an empty array
		guard let baseMatch else {
			return []
		}
		
		// baseMatch is now verified, so now we need to determine what to return.
		// The only special case at this point is if host matches authenticationHost.
		if let authenticationHost,
		   host == authenticationHost {
			return [baseMatch]
		}
		
		// The policy enforces its own [iat, exp) validity window, returning nil when expired or
		// not yet valid; an ignored policy leaves only the base match.
		let now = osCalls.getCurrentDate()
		let enterpriseMatch = enterpriseConfigurations.withLock {
			$0?.getConfiguration(for: host, at: now)
		}

		// At this point, we *might* have an enterprise match and we
		// do have a base match, so if enterpriseMatch is nil, only baseMatch is returned
		guard let enterpriseMatch else {
			return [baseMatch]
		}
		
		switch enterpriseMatch {
		case .match(let enterpriseConfiguration), .wildcard(let enterpriseConfiguration):
			return [enterpriseConfiguration, baseMatch]
		}
	}

	enum EvaluationResult {
		case notPinned
		case proceed
		case reject
	}

	private func evaluate(challenge: URLAuthenticationChallenge) -> EvaluationResult {
		// If there were no configurations to pin, this host isn't pinned.
		let configurations = getConfiguration(for: challenge.protectionSpace.host)
		if configurations.isEmpty {
			return .notPinned
		}
		
		// Check to see if we can even pin the host, if not then we should just reject
		// the connection-that's the "fail-secure" response.
		guard let trustWrapper = osCalls.getServerTrust(challenge),
			  let certChain = osCalls.getCertificateChain(trustWrapper)
		else {
			return .reject
		}
		
		// Build the list of commonNames of the certificates
		let commonNames: [String] = certChain.compactMap(osCalls.getCommonName)
		
		// Make sure we got all of the names for all of the certs, otherwise we can't check
		// we should "fail-secure."
		guard commonNames.count == certChain.count else {
			return .reject
		}
		
		// Get the configuration for this host, and the certChain from the challenge
		for configuration in configurations {
			// Did the commonName match a chain in this configuration? If so, then the pin
			// was successful.
			if configuration.matches(commonNames) {
				return .proceed
			}
		}
		
		// The pin didn't match, so we need to fail the connection.
		return .reject
	}

	/**
	 Validates the connection against the chains in this CNPinningManager.

	 Pass the `URLAuthenticationChallenge` and `completionHandler` from your
	 URLSessionDelegate `func urlSession(session:didReceive:completionHandler:)` or
	 URLSessionTaskDelegate `func urlSession(session:task:didReceive:completionHandler:)` to
	 allow CNPinningManager to validate the connection to the server, or let you know that the host was not pinned.

	 - Parameters
	 - challenge: the challenge passed to your URLSessionDelegate or URLSessionTaskDelegate
	 - completionHandler: the completion handler passed to your URLSessionDelegate or URLSessionTaskDelegate
	 - Returns true if CNPinningManager handled the validation, false to allow you to do additional checks before calling `completionHandler` yourself
	 */
	public func validate(challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Bool {
		switch evaluate(challenge: challenge) {
		case .notPinned:
			return false

		case .proceed:
			completionHandler(.performDefaultHandling, nil)
			return true

		case .reject:
			completionHandler(.cancelAuthenticationChallenge, nil)
			return true
		}
	}

	/**
	 Asynchronously validates the connection against the chains in this CNPinningManager.

	 Pass the `URLAuthenticationChallenge` from your
	 URLSessionDelegate `func urlSession(session:didReceive:)` or
	 URLSessionTaskDelegate `func urlSession(session:task:didReceive:)` to
	 allow CNPinningManager to validate the connection to the server, or let you know that the host was not pinned.

	 - Parameters
	 - challenge: the challenge passed to your URLSessionDelegate or URLSessionTaskDelegate
	 - Returns the result to return to the URLSession
	 - Throws `CNPinningError.notPinned` if the host is not pinned by the configuration.
	 */
	public func validate(challenge: URLAuthenticationChallenge) async throws -> (URLSession.AuthChallengeDisposition, URLCredential?) {
		switch evaluate(challenge: challenge) {
		case .notPinned:
			throw CNPinningError.notPinned

		case .proceed:
			return (.performDefaultHandling, nil)

		case .reject:
			return (.cancelAuthenticationChallenge, nil)
		}
	}

	public var description: String {
		// If we have a domainOrder, this was probably generated from a plist or the developer
		// defined an order.
		let domainOrderString: String
		let domainConfigurationMapArray: [String]
		if let descriptionOrder {
			domainOrderString = "[\"" + descriptionOrder.map(\.description).joined(separator: "\", \"") + "\"], "
			domainConfigurationMapArray = descriptionOrder.compactMap {
				guard let configuration = configuration[$0] else {
					return nil
				}
				return "\"\($0)\": \(configuration.description)"
			}
		} else {
			domainOrderString = ""
			domainConfigurationMapArray = configuration.sorted(by: { $0.key < $1.key }).map { "\"\($0.key)\": \($0.value.description)" }
		}

		return "CNPinningManager(\(domainOrderString)[\(domainConfigurationMapArray.joined(separator: ", "))])"
	}
}

extension URLSession {
    private nonisolated(unsafe) static var cnPinningManagerKey: UInt8 = 0

	/**
	 Convenience function to allow your to save and retrieve  a pinning configuration on your URLSession object.
	 */
    public var cnPinningManager: CNPinningManager? {
        get {
            objc_getAssociatedObject(self, &Self.cnPinningManagerKey) as? CNPinningManager
        }
        set {
            objc_setAssociatedObject(self, &Self.cnPinningManagerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
