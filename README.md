# CNPinning-Apple
Certificate **Common Name (CN) pinning** for Apple platforms.

[![Swift](https://img.shields.io/badge/Swift-6.3-orange?style=flat-square)](https://img.shields.io/badge/Swift-6.3-orange?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-macOS_iOS_tvOS_watchOS_visionOS-yellowgreen?style=flat-square)](https://img.shields.io/badge/Platforms-macOS_iOS_tvOS_watchOS_visionOS_Android_JVM-yellowgreen?style=flat-square)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-Orange?style=flat-square)

> Looking for the Android version? See [CNPinning-Android](https://github.com/AustinSoftCom/CNPinning-Android)

`CNPinning-Apple` lets a `URLSession` reject TLS connections unless the server's
certificate chain presents the Common Names you expect. Instead of pinning a
public key or a certificate's SHA-256 hash (which break the moment a certificate
is rotated), you pin against the **Common Names of the certificates in the
chain** — using exact, prefix, numeric-suffix, or suffix matching so that
routine certificate renewals (e.g. `R10` → `R11`, `Apple Public Server ECC CA 1 - G3`)
don't break your app.

Validation always runs *in addition to* the system's normal TLS evaluation: a
connection only succeeds when both the OS trusts the chain **and** the chain's
Common Names match one of your pinned chains. The library is **fail-secure** —
anything it cannot verify *for the specified configuration* is rejected.

> For the design rationale, threat model, and how this compares to public-key
> and certificate-hash pinning, see the
> [white paper](https://www.austinsoft.com/white-papers/CNPinning.pdf).

---

## Table of contents

- [How it works](#how-it-works)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Configuration via Info.plist](#configuration-via-infoplist)
- [Programmatic configuration](#programmatic-configuration)
- [Match types](#match-types)
- [Discovering a server's CN chain](#discovering-a-servers-cn-chain)
- [Subdomain handling](#subdomain-handling)
- [Validation behavior](#validation-behavior)
- [Async/await API](#asyncawait-api)
- [Enterprise pinning](#enterprise-pinning)
- [Errors](#errors)
- [Security notes](#security-notes)
- [Testing](#testing)
- [License](#license)

---

## How it works

1. You describe, per domain, one or more **certificate chains** you are willing
   to trust. A chain is an ordered list of "links," one per certificate, written
   **root → intermediate(s) → leaf** order (the order you read a chain top-down).
2. At connection time your `URLSession` hands the delegate a TLS challenge containing
   the server's certificate chain.
3. `CNPinningManager` extracts the Common Name from each certificate, then checks
   whether the presented chain matches **all** the links of **any** chain you
   defined for that host, as specified within each link's configuration.
   - The number of certificates presented must equal the number of links in a
     chain. Every certificate is checked — including the leaf.
4. If a chain matches → the connection proceeds with default handling. If it does
   not → the connection is cancelled.

> **Note on ordering:** developers define chains root → leaf because that's how
> humans read them, but `URLSession` delivers the chain leaf → root. The library
> reverses your definition internally so the two line up. You always write
> root → leaf.

### Development note

`URLSession` caches responses on-device via the `urlCache` on its `URLSessionConfiguration`.
A cached response is returned without a new TLS handshake — so no challenge
reaches the delegate, and no pinning occurs. Building your `URLSession`
with an `ephemeral` `URLSessionConfiguration`, at least during development,
avoids this and will save you uncounted time tracking down why a host isn't being pinned.

### Unpinned hosts

CNPinning applies pinning only to hosts you explicitly configure. Connections to
hosts without a configured pin set proceed with the platform's normal TLS
validation — they are **allowed**, not blocked. This matches the behavior of
Apple's and Android's built-in pinning and standard pinning libraries: pinning
*adds* constraints to the hosts you choose to pin; it does **not** restrict connections
to only-pinned hosts.

A consequence to be aware of: if a host you intend to pin is misconfigured — a
hostname typo, a configuration that doesn't load, a pin set not applied to that
host — connections to it are *allowed* (unpinned), not blocked. Pinning misconfigurations
fail open. Verify that your pin sets are actually applied to the hosts you intend to
protect; do not assume a host is pinned without confirming its configuration is
loaded and matched.

---

## Requirements

| Platform  | Minimum |
|-----------|---------|
| macOS     | 12.0    |
| iOS       | 15.0    |
| tvOS      | 15.0    |
| watchOS   | 8.0     |
| visionOS  | 1.0     |

- Swift 6 language mode (`swift-tools-version: 6.3`).

---

## Installation

### Swift Package Manager (Xcode)

In Xcode: **File → Add Package Dependencies…**, enter the repository URL, and add
the **CNPinning-Apple** library product to your app target.

### Swift Package Manager (Package.swift)

```swift
dependencies: [
    .package(url: "https://github.com/austinsoftcom/CNPinning-Apple.git", from: "1.1.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "CNPinning-Apple", package: "CNPinning-Apple")
        ]
    )
]
```

Then `import CNPinning_Apple` (note the underscore — Swift replaces the hyphen in
the module name).

---

## Quick start

There are three pieces: a **pinning manager**, a **`URLSessionDelegate`** that
calls it, and a **`URLSession`** that carries the manager.

### 1. A delegate that consults the pinning manager

```swift
import Foundation
import CNPinning_Apple

final class PinningURLSessionDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // If there's no manager, or the manager handled the challenge, we're done.
        guard let pinningManager = session.cnPinningManager,
              pinningManager.validate(challenge: challenge, completionHandler: completionHandler) else {
            // Host is not pinned (or no manager). Choose your policy here — this
            // example refuses anything that isn't explicitly pinned.
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
    }
}
```

### 2. A session that owns a pinning manager

```swift
import CNPinning_Apple

let pinnedSession: URLSession = {
    do {
        // Reads the pinning configuration from your app's Info.plist.
        let pinningManager = try CNPinningManager()
        let delegate = PinningURLSessionDelegate()

        let session = URLSession(
            configuration: .default,
            delegate: delegate,
            delegateQueue: nil
        )
        session.cnPinningManager = pinningManager  // attach the manager to the session
        return session
    } catch {
        fatalError("Unable to initialize the pinned URLSession: \(error)")
    }
}()
```

### 3. Use the session normally

```swift
pinnedSession.dataTask(with: URL(string: "https://austinsoft.com/")!) { data, response, error in
    // `error` is URLError(.cancelled) and `data` is nil when pinning rejects the connection.
}.resume()
```

`session.cnPinningManager` is an associated object on `URLSession` provided by the
library — set it once and the delegate retrieves it on every challenge.

---

## Configuration via Info.plist

Most apps configure pinning declaratively in **Info.plist** and create the
manager with `try CNPinningManager()`. The structure is:

```
CNPinningManager (Dictionary)
└─ PinnedDomains (Dictionary)
   └─ <host> (Dictionary)
      ├─ includesSubdomains (Boolean)
      └─ chainSet (Array of chains)
         └─ <chain> (Array of links, root → leaf)
            └─ <link> (Dictionary)
               ├─ type  (String: exact | prefix | prefixWithNumber | suffix)
               └─ value (String)
```

Example pinning `captive.apple.com` and `austinsoft.com`:

```xml
<key>CNPinningManager</key>
<dict>
    <key>PinnedDomains</key>
    <dict>
        <key>captive.apple.com</key>
        <dict>
            <key>includesSubdomains</key>
            <false/>
            <key>chainSet</key>
            <array>
                <!-- one chain, written root → leaf -->
                <array>
                    <dict>
                        <key>type</key>   <string>exact</string>
                        <key>value</key>  <string>DigiCert Global Root G</string>
                    </dict>
                    <dict>
                        <key>type</key>   <string>prefixWithNumber</string>
                        <key>value</key>  <string>Apple Public Server ECC CA 1 - G</string>
                    </dict>
                    <dict>
                        <key>type</key>   <string>suffix</string>
                        <key>value</key>  <string>.apple.com</string>
                    </dict>
                </array>
            </array>
        </dict>

        <key>austinsoft.com</key>
        <dict>
            <key>includesSubdomains</key>
            <false/>
            <key>chainSet</key>
            <array>
                <array>
                    <dict>
                        <key>type</key>   <string>prefixWithNumber</string>
                        <key>value</key>  <string>ISRG Root X</string>
                    </dict>
                    <dict>
                        <key>type</key>   <string>prefixWithNumber</string>
                        <key>value</key>  <string>R</string>
                    </dict>
                    <dict>
                        <key>type</key>   <string>suffix</string>
                        <key>value</key>  <string>austinsoft.com</string>
                    </dict>
                </array>
            </array>
        </dict>
    </dict>
</dict>
```

Notes:
- `chainSet` is a **set of chains, which are arrays**. List more than one chain
  when a host may be served from different certificate authorities (e.g. during
  a CA migration) — any **chain** matching the trust chain is enough.
- `includesSubdomains` is **required** in Info.plist (omitting it throws
  `CNParseError.missingValue("includesSubdomains")`).
- If a link omits `type`, it defaults to `exact` (and a warning is logged to
  stderr in DEBUG builds).

---

## Programmatic configuration

You can also build the manager in code — useful for tests, for configuration
fetched at runtime, or if you simply prefer not to use Info.plist.

```swift
import CNPinning_Apple

let pinningManager = try CNPinningManager(
	configuration: [
		"austinsoft.com": try CNConfiguration(
			includesSubdomains: false,
			[
				CNChain([                              // written root → leaf
					CNChainLink(.prefixWithNumber, "ISRG Root X"),
					CNChainLink(.prefixWithNumber, "R"),
					CNChainLink(.exact, "austinsoft.com"),
				])
			]
		)
	]
)
```

> **NOTE:** You can configure both a domain and a specific host (e.g. `apple.com`
>          and `www.apple.com`) with different chains; an exact host match always
>          wins over a `includesSubdomains` match (see [Subdomain handling](#subdomain-handling)).

### Building blocks

| Type | Purpose |
|------|---------|
| `CNPinningManager` | Holds all per-host configurations and performs validation. |
| `CNConfiguration`  | One host's settings: `includesSubdomains` + one or more chains. |
| `CNChain`          | One acceptable certificate chain, written root → leaf. |
| `CNChainLink`      | A single certificate's match rule: a `LinkType` and a `value`. |

`CNConfiguration` rejects an empty `chainSet` (`CNParseError.noChainsDefined`)
and configurations that have duplicate chains (`CNParseError.duplicateChain(index)`).

---

## Match types

Each link matches one certificate's Common Name with one of these
`CNChainLink.LinkType` values:

| Type               | Matches when the CN…                                              | Example value | Matches | Doesn't match |
|--------------------|------------------------------------------------------------------|---------------|---------|---------------|
| `exact`            | equals the value exactly                                         | `austinsoft.com` | `austinsoft.com` | `www.austinsoft.com` |
| `prefix`           | begins with the value                                            | `DigiCert C` | `DigiCert C4` | `DigiCert ` |
| `prefixWithNumber` | begins with the value, and the remainder is **all digits** (≥1) | `R` | `R10`, `R11` | `R`, `RX` |
| `suffix`           | ends with the value                                             | `.apple.com` | `www.apple.com` | `apple.com` |

`prefixWithNumber` is the key to surviving certificate rotation: CAs commonly
roll names like `R10` → `R11` or `Apple Public Server ECC CA 1 - G3` → `… - G4`.
Pin the stable prefix and let the trailing generation number float.

---

## Discovering a server's CN chain

To pin a host you need the Common Names of every certificate in its chain, in
root → leaf order. The repository ships a helper, **`printPins.py`**, that
connects to a host and prints exactly that — one Common Name per line, already in
the order you write a `CNChain`.

### Running the script

```sh
python3 printPins.py <hostname>              # one Common Name per line (default)
python3 printPins.py <hostname> --format plist   # ready-to-paste Info.plist fragment
```

Requirements:
- **Python 3** (uses only the standard library).
- **`openssl`** on your `PATH` — the script shells out to `openssl s_client` to
  fetch the chain and to `openssl x509` to read each certificate's subject.

The script connects to `<hostname>` on port **443** and prints the Common Name of
each certificate in the chain, **root → leaf**, one per line. It also fills in the
true root: if the topmost certificate the server sends was issued by a root that
*wasn't* transmitted (common, since clients already hold roots), that root's
Common Name is printed first.

### Example

```sh
$ python3 printPins.py austinsoft.com
ISRG Root X1
R13
austinsoft.com
```

Read top-to-bottom this is root → intermediate → leaf — the same order a
`CNChain` is written. Translate each line into a link, choosing match types that
tolerate routine certificate renewals:

```swift
CNChain([
    CNChainLink(.prefixWithNumber, "ISRG Root X"),   // ISRG Root X1, X2, …
    CNChainLink(.prefixWithNumber, "R"),             // R10, R11, …
    CNChainLink(.exact, "austinsoft.com"),           // the leaf CN
])
```

Guidelines when translating:
- **Include every line the script prints** (leaf included) — the link count must
  equal the number of certificates the server presents, or the chain never
  matches.
- Prefer `prefixWithNumber` / `prefix` / `suffix` over `exact` for CA
  certificates so renewals don't break your app; reserve `exact` for values you
  control and expect to be stable (often the leaf).
- If the host might be served by more than one CA, run the script periodically
  and capture each possibility as a separate chain in the `chainSet`.

### Generating an Info.plist fragment

`--format plist` does the translation for you: it prints a `<key>/<dict>` entry,
ready to paste directly inside `CNPinningManager > PinnedDomains` in your app's
Info.plist. It applies the same heuristic described above — a trailing run of
digits becomes a `prefixWithNumber` link on the stable prefix; everything else is
pinned `exact`.

```sh
$ python3 printPins.py austinsoft.com --format plist
	<key>austinsoft.com</key>
	<dict>
		<key>includesSubdomains</key>
		<false/>
		<key>chainSet</key>
		<array>
			<array>
				<dict>
					<key>type</key>
					<string>prefixWithNumber</string>
					<key>value</key>
					<string>ISRG Root X</string>
				</dict>
				<dict>
					<key>type</key>
					<string>prefixWithNumber</string>
					<key>value</key>
					<string>R</string>
				</dict>
				<dict>
					<key>type</key>
					<string>exact</string>
					<key>value</key>
					<string>austinsoft.com</string>
				</dict>
			</array>
		</array>
	</dict>
```

Pass `--includes-subdomains` to set `includesSubdomains` to `true` in the output
(it defaults to `false`).

The fragment reflects only the single chain the host currently presents, with
conservative match types. **Review it before shipping** — for example, you may
want to relax a leaf entry to a `suffix` match, or add a second chain for the
host's other key type (see below).

**Roots and intermediates change too.** Every certificate in the chain — including
the root — must match a link, and CA certificate names are not permanent. When a
CA rotates a root or intermediate, re-run `printPins.py` and add the new chain to
the `chainSet` (keeping the old one) so connections keep working across the
transition until the old hierarchy is retired.

> **Why prefix matching instead of a certificate/key hash?** Certificate
> lifetimes are collapsing — Let's Encrypt leaf certificates last up to 100 days
> (with a ~6-day short-lived option), and the CA/Browser Forum's maximum drops to
> 47 days in March 2029. A hash or key pin potentially breaks on every renewal;
> pinning the stable CA-name prefix survives rotation while still rejecting an
> unexpected authority. The full rationale, threat model, and trade-offs are in the
> [design white paper](https://www.austinsoft.com/white-papers/CNPinning.pdf).

---

## Subdomain handling

When resolving the configuration for a host, `CNPinningManager`:

1. Uses an **exact** host match if one exists (regardless of `includesSubdomains`).
2. Otherwise, among configurations whose `includesSubdomains` is `true`, picks the
   one whose domain is a suffix of the host (`host` ends with `.` + `domain`),
   preferring the **longest** (most specific) matching domain.

So with `apple.com` (`includesSubdomains: true`) and `www.apple.com`
(`includesSubdomains: true`) both configured, a request to `sub.www.apple.com`
resolves to the `www.apple.com` configuration because it's the more specific
suffix.

A host with **no** matching configuration is treated as *not pinned* (see below).

---

## Validation behavior

The completion-handler API returns a `Bool` indicating whether the manager
**handled** the challenge:

```swift
func validate(
    challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
) -> Bool
```

| Situation | Return value | `completionHandler` called with | Meaning |
|-----------|--------------|---------------------------------|---------|
| Host is not pinned | `false` | *(not called)* | You decide what to do (default handling or cancel). |
| Chain matches | `true` | `.performDefaultHandling` | Proceed with normal OS trust evaluation. |
| Cannot get trust / chain / Common Names | `true` | `.cancelAuthenticationChallenge` | **Fail-secure** reject. |
| Chain does not match | `true` | `.cancelAuthenticationChallenge` | Pin failed; reject. |

Because `validate` does **not** call the completion handler for unpinned hosts,
your delegate must decide the policy for hosts you didn't pin. Two common choices:

```swift
// Strict: refuse anything not explicitly pinned.
guard let manager = session.cnPinningManager,
      manager.validate(challenge: challenge, completionHandler: completionHandler) else {
    completionHandler(.cancelAuthenticationChallenge, nil)
    return
}
```

```swift
// Permissive: pin the hosts you listed, fall back to the OS for everything else.
guard let manager = session.cnPinningManager else {
    completionHandler(.cancelAuthenticationChallenge, nil)
    return
}
if !manager.validate(challenge: challenge, completionHandler: completionHandler) {
    completionHandler(.performDefaultHandling, nil)
}
```

---

## Async/await API

For Swift concurrency, use the throwing async variant:

```swift
func validate(
    challenge: URLAuthenticationChallenge
) async throws -> (URLSession.AuthChallengeDisposition, URLCredential?)
```

- Matched chain → returns `(.performDefaultHandling, nil)`.
- Match failed or unverifiable → returns `(.cancelAuthenticationChallenge, nil)`.
- Host not pinned → throws `CNPinningError.notPinned` (so you can decide the
  fallback policy in a `catch`).

```swift
do {
    let (disposition, credential) = try await manager.validate(challenge: challenge)
    completionHandler(disposition, credential)
} catch CNPinningError.notPinned {
    completionHandler(.performDefaultHandling, nil)   // or .cancelAuthenticationChallenge
}
```

---

## Enterprise pinning

An enterprise can extend an app's pinning at runtime with a **signed policy**, without an app
update — useful when a managed device must trust a corporate TLS-inspection chain. Build the manager
with an `authenticationHost` (the login host, exempt from enterprise overrides so a policy fetched
from it can never re-pin it) and a `policySigningKey` (the `SecKey` public key every policy must
verify against):

```swift
import CNPinning_Apple

// From Info.plist:
let manager = try CNPinningManager(
    authenticationHost: "auth.example.com",
    policySigningKey: enterprisePublicKey   // a SecKey
)

// …or with a programmatic configuration:
let manager = try CNPinningManager(
    authenticationHost: "auth.example.com",
    policySigningKey: enterprisePublicKey,
    configuration: [ /* app-baked pins */ ]
)
```

After a successful login, hand the manager the signed policy you fetched (the raw JWS bytes):

```swift
try manager.applyEnterprisePolicy(with: signedPolicy)   // first time (throws if one is already active)
try manager.refreshEnterprisePolicy(with: signedPolicy) // replace an active policy
manager.signOut()                                       // drop the policy (e.g. on logout)
```

An applied policy contributes its mappings only while the current time is within its `iat`/`exp`
window; once expired (or not yet valid) it is ignored during evaluation, falling back to the
app-baked pins. The active policy's window is available via `manager.enterprisePolicyIssuedAt` and
`manager.enterprisePolicyExpiry` (both `Date?`, `nil` when no policy is applied).

The policy is a **JWS** (RS256/384/512, ES256/384/512, or PS256/384/512) whose verified payload is
JSON: an `iat`/`exp` pair plus one entry per host (or the `"*"` wildcard), each an array of chains in
the same root-to-leaf shape used elsewhere. `iat`/`exp` are JWT `NumericDate` claims — **seconds
since the Unix epoch** (RFC 7519):

```json
{
  "iat": 1718000000,
  "exp": 1718600000,
  "*": [
    [ { "type": "exact",  "value": "Enterprise Root CA" },
      { "type": "suffix", "value": ".example.com" } ]
  ]
}
```

When a host is pinned, an enterprise configuration (an exact host match, else the `"*"` wildcard) is
tried **before** the app-baked configuration, so either an app chain *or* an enterprise chain may
satisfy the pin. Verification uses `SecKeyVerifySignature`; ECDSA signatures use the ASN.1/DER (X9.62)
encoding, which matches CNPinning-Android, so one signed policy verifies on both platforms.

---

## Errors

### `CNParseError` — thrown while building a configuration

| Case | Cause |
|------|-------|
| `noInfoPlist` | No Info.plist is available (or it is empty) when constructing the manager from `try CNPinningManager()`. |
| `atsConflict` | App Transport Security is also configured for pinning (`NSAppTransportSecurity` → `NSPinnedDomains`), which would conflict with CN pinning. |
| `missingValue(String)` | A required key is missing (`CNPinningManager`, `PinnedDomains`, `includesSubdomains`, `chainSet`, or a link's `value`). |
| `invalidType(String)` | A pinned-domain entry isn't a dictionary. |
| `invalidLinkType(String)` | A link's `type` isn't one of the four supported values. |
| `noChainsDefined` | A configuration's `chainSet` is empty. |
| `duplicateChain(Int)` | The same chain appears twice in a `chainSet` (index of the duplicate). |

### `CNPinningError` — thrown during async validation and enterprise policy application

| Case | Cause |
|------|-------|
| `notPinned` | The challenged host has no matching pinned configuration. |
| `enterpriseNotConfigured` | `applyEnterprisePolicy`/`refreshEnterprisePolicy` was called on a manager built without an `authenticationHost` and `policySigningKey`. |
| `existingEnterpriseConfiguration` | `applyEnterprisePolicy` was called while a policy is already active — call `signOut()` first, or use `refreshEnterprisePolicy`. |
| `missingEnterpriseConfiguration` | `refreshEnterprisePolicy` was called before any policy was applied. |
| `invalidJWSFormat` | The signed policy is not a valid JWS, or its signature does not verify against the `policySigningKey`. |

---

## Security notes

- Pinning runs **on top of** the system's TLS evaluation — a successful pin
  returns `.performDefaultHandling`, so the OS still validates expiry, revocation,
  hostname, and trust. Pinning can never *loosen* the OS checks; it only adds to them.
- The library is **fail-secure**: a missing server trust, an unreadable or incomplete
  chain, or a certificate in the chain without a readable Common Name all result
  in rejection. Use `printPins.py` to be certain your chain is complete.
- Plan for rotation. Prefer `prefixWithNumber`/`prefix`/`suffix` for CA links, and
  list multiple chains in a `chainSet` so a CA migration doesn't require an app
  update.
- CNPinning validates at the TLS handshake; responses served from the
  (bundleID-keyed) URLCache for a URLSession are returned without a
  handshake and thus without re-running the pin evaluation. This is
  correct (the cached response was pin-validated on its original
  fetch), but a consumer whose security model requires every response
  to be pin-validated should account for it (e.g., disable or limit
  URLCache for pinned endpoints, or use an ephemeral configuration
  for security-critical requests).

See the [white paper](https://www.austinsoft.com/white-papers/CNPinning.pdf) for the
complete threat model and the reasoning behind these trade-offs.

---

## Testing

The library abstracts every system call behind an internal `OSCalls` struct
(fetching the Info.plist, the server trust, the certificate chain, and each
Common Name). This makes the matching logic fully testable with injected,
deterministic data — see the project's `Tests` directory, which exercises parsing,
each match type, subdomain resolution, fail-secure paths, and live end-to-end
pinning against a real host.

```sh
swift test
```

A runnable SwiftUI example app lives in
[`Examples/TestCNPinningApp`](Examples/TestCNPinningApp): it loads its pinning
configuration from `Info.plist` and makes a pinned request when you tap **Test**.

---

## License

MIT License. Copyright © 2026 AustinSoft.com. See [LICENSE.txt](LICENSE.txt).
