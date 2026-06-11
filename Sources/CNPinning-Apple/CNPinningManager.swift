// Copyright (c) 2026 AustinSoft.com

import Foundation

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
	 Initialize CNPinningManager with the specified configuration

	 Initialize CNPinningManager passing the specified configuration to the
	 main init, which will configure CNPinningManager.

	 - Parameters
	 - configuration: The CNConfiguration to use for this CNPinningManager
	 */
	public convenience init(configuration: [String: CNConfiguration]) throws {
		try self.init(initType: .configuration(configuration: configuration), osCalls: OSCalls())
	}

	convenience init(configuration: [String: CNConfiguration], osCalls: OSCalls) throws {
		try self.init(initType: .configuration(configuration: configuration), osCalls: osCalls)
	}

	init(initType: InitType, osCalls: OSCalls) throws {
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
	}

	convenience init(osCalls: OSCalls) throws {
		try self.init(initType: .infoPlist, osCalls: osCalls)
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

	func getConfiguration(for host: String) -> CNConfiguration? {
		if let exact = configuration[host] {
			return exact
		}

		return configuration
			.filter { domain, config in
				config.includesSubdomains && host.hasSuffix("." + domain)
			}
			.max(by: { $0.key.count < $1.key.count })?
			.value
	}

	enum EvaluationResult {
		case notPinned
		case proceed
		case reject
	}

	private func evaluate(challenge: URLAuthenticationChallenge) -> EvaluationResult {
		// Get the configuration for this host, and the certChain from the challenge
		guard let configuration = getConfiguration(for: challenge.protectionSpace.host) else {
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

		// Did the commonName match a chain in this configuration? If so, then the pin
		// was successful.
		if configuration.matches(commonNames) {
			return .proceed
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
