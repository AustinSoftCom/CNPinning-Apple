# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Enterprise pinning support. A `CNPinningManager` constructed with an `authenticationHost` and a
  `policySigningKey` (a `SecKey`) can apply a signed enterprise pinning policy at runtime via
  `applyEnterprisePolicy(with:)`, replace it with `refreshEnterprisePolicy(with:)`, and drop it with
  `signOut()`. Enterprise-supplied chains are tried before the app-baked configuration; the
  `authenticationHost` is exempt from enterprise overrides, and `CNEnterprisePolicy` enforces its own
  `iat`/`exp` validity window, contributing its mappings only while valid (an expired or
  not-yet-valid policy is ignored). The active policy's `iat`/`exp` are exposed via
  `enterprisePolicyIssuedAt` and `enterprisePolicyExpiry`.
- `CNEnterpriseConfiguration` and `CNEnterprisePolicy` types describing an enterprise policy, plus
  the `CNPinningMatches` protocol adopted by both `CNConfiguration` and `CNEnterpriseConfiguration`.
- JWS verification of signed policies (`JWT`/`JWTHeader`) via `SecKeyVerifySignature`, supporting the
  RS256/384/512, ES256/384/512, and PS256/384/512 algorithms.
- New `CNPinningError` cases: `enterpriseNotConfigured`, `existingEnterpriseConfiguration`,
  `missingEnterpriseConfiguration`, and `invalidJWSFormat`.
- `Codable` conformances for `CNChain` and `CNChainLink`.

### Fixed

- Enterprise policy `iat`/`exp` are now decoded and encoded as JWT `NumericDate` values (seconds
  since the Unix epoch, RFC 7519) instead of `Foundation`'s default `Date` encoding (seconds since
  the 2001 reference date), so signed policies interoperate with standard JWT issuers and with
  CNPinning-Android.

### Changed

- `getConfiguration(for:)` now returns an ordered `[any CNPinningMatches]` (the enterprise
  configuration, when present, followed by the app-baked configuration) instead of a single optional
  `CNConfiguration`; an empty array means the host is not pinned.

### Removed

- Nothing yet

## [1.1.0] - 2026-06-10

### Added

- All initializers now reject configurations that enable ATS pinning, throwing
  CNParseError.atsConflict. Previously this conflict was detected only when initializing from
  Info.plist.
- Disallow empty strings in CNChainLink matcher values, throwing CNParseError.missingValue
  (e.g., 'exact value'), to prevent silently matching any name at that link in the chain.
- This CHANGELOG file.
- Updated README.md to include more documentation on the changes above. 


## [1.0.0] - 2026-02-15

### Added

- Initial reference implementation of Common Name certificate pinning, as described in
  the white paper at https://www.austinsoft.com/white-papers/CNPinning.pdf.
- CN-chain matching primitives: exact, prefix, prefixWithNumber, and suffix.
- Configuration via Info.plist and programmatic CNConfiguration.

[unreleased]: https://github.com/austinsoftcom/cnpinning-apple/compare/1.1.0...HEAD
[1.1.0]: https://github.com/AustinSoftCom/CNPinning-Apple/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/AustinSoftCom/CNPinning-Apple/releases/tag/1.0.0
