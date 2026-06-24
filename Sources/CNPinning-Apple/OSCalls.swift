// Copyright (c) 2026 AustinSoft.com

import Foundation
import Security

/// This class is used in place of SecTrust when passing/returning values in the library. The
/// actual class used within the library is RealCNSecTrust, which derives from this, but this
/// allows you to write OSCalls using mock data.
/// I don't like that these are @unchecked Sendable, but I can't make them Sendable without
/// making them final, which means they can't be overridden.
class CNSecTrust: @unchecked Sendable {
}

/// This class is used in place of SecCertificate when passing/returning values in the library. The
/// actual class used within the library is RealCNSecCertificate, which derives from this, but this
/// allows you to write OSCalls using mock data.
/// I don't like that these are @unchecked Sendable, but I can't make them Sendable without
/// making them final, which means they can't be overridden.
class CNSecCertificate: @unchecked Sendable {
}

/// This class is used by the default OSCalls and pulls the trust object out of this.
/// I don't like that these are @unchecked Sendable, but I can't make them Sendable without
/// making their superclass Sendable, see the comment on CNSecTrust
final class RealCNSecTrust<T>: CNSecTrust, @unchecked Sendable {
    let trust: T

    init?(trust: T?) {
        guard let trust else { return nil }
        self.trust = trust
    }
}

/// This class is used by the default OSCalls and pulls the certificate object out of this.
/// I don't like that these are @unchecked Sendable, but I can't make them Sendable without
/// making their superclass Sendable, see the comment on CNSecCertificate
final class RealCNSecCertificate<T>: CNSecCertificate, @unchecked Sendable {
    let certificate: T

    init?(certificate: T?) {
        guard let certificate else { return nil }
        self.certificate = certificate
    }
}

/// Structure used to abstract away the OS calls when testing the library, so I can inject behaviors into the
/// library and drive the code for coverage of blue sky and all error conditions. By default, this will
/// initialize to using  the OS-level calls into Foundation and Security on Release builds.
struct OSCalls {
    let getInfoDictionary: @Sendable () -> [String: Any]?
    let getServerTrust: @Sendable (URLAuthenticationChallenge) -> CNSecTrust?
    let getCertificateChain: @Sendable (CNSecTrust) -> [CNSecCertificate]?
    let getCommonName: @Sendable (CNSecCertificate) -> String?

    /// The current wall-clock time, used to enforce an enterprise policy's validity window
    /// (`iat`/`exp`) when retrieving its mappings. Defaults to `Date()`; tests inject a fixed date
    /// to drive the expired / not-yet-valid paths deterministically.
    let getCurrentDate: @Sendable () -> Date

    /// This allows you to check parameters and drive the responses from the OS calls..
    init(
        getInfoDictionary: (@Sendable () -> [String: Any]?)? = nil,
        getServerTrust: (@Sendable (URLAuthenticationChallenge) -> CNSecTrust?)? = nil,
        getCertificateChain: (@Sendable (CNSecTrust) -> [CNSecCertificate]?)? = nil,
        getCommonName: (@Sendable (CNSecCertificate) -> String?)? = nil,
        getCurrentDate: (@Sendable () -> Date)? = nil
    ) {
        self.getInfoDictionary = getInfoDictionary ?? { Bundle.main.infoDictionary }
        self.getCurrentDate = getCurrentDate ?? { Date() }
        self.getServerTrust = getServerTrust ?? { RealCNSecTrust(trust: $0.protectionSpace.serverTrust) }
        self.getCertificateChain = getCertificateChain ?? {
            guard let trust = ($0 as? RealCNSecTrust<SecTrust>)?.trust else { return nil }
            guard let certificates = SecTrustCopyCertificateChain(trust),
                  let secCertificates = certificates as? [SecCertificate]
            else {
                return nil
            }

            let certs = secCertificates.compactMap(RealCNSecCertificate.init)
            guard certs.count == secCertificates.count else {
                return nil
            }
            return certs
        }
        self.getCommonName = getCommonName ?? {
            guard let certificate = ($0 as? RealCNSecCertificate<SecCertificate>)?.certificate else { return nil }
            var certCommonName: CFString?
            guard SecCertificateCopyCommonName(certificate, &certCommonName) == noErr,
                  let commonName = certCommonName as? String
            else {
                return nil
            }
            return commonName
        }
    }
}
