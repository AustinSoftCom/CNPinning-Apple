# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Nothing yet

### Fixed

- Nothing yet

### Changed

- Nothing yet

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
