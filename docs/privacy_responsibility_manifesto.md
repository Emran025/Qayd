# Privacy, Responsibility, and Legal Positioning Manifesto

**Classification:** Legal-Technical Reference Document
**Revision:** 1.0 — April 2026
**Audience:** System Auditors · Legal Counsel · Regulatory Bodies · Institutional Partners · Data Protection Officers

---

## Preamble

This document establishes the privacy guarantees, responsibility boundaries, and legal positioning of Qayd as a cryptographically sovereign financial commitment platform. Unlike conventional privacy policies that enumerate organizational promises subject to revision, this manifesto describes structural properties — mathematical constraints baked into the system's architecture that cannot be relaxed by administrative decision, policy change, or executive override.

The privacy posture of Qayd is not a commitment that the organization *chooses* to honor. It is a technical condition that the organization *cannot* violate. This distinction is the foundation upon which every claim in this document rests.

---

## §1 — What the System Cannot Do

### 1.1 Structural Incapacities

The following limitations are not policy restrictions — they are architectural impossibilities enforced by the cryptographic design of the system. No software update, administrative action, or legal compulsion directed at the platform operator can circumvent them, because the platform does not possess the requisite cryptographic material.

**The system cannot read a user's financial data.** All financial records — vouchers, ledger entries, account balances, counterparty identities, transaction descriptions — reside in an SQLCipher-encrypted database on the user's device. The encryption passphrase is derived through PBKDF2 from a composite salt that incorporates a hardware-specific device identifier, a locally generated 32-byte random salt, and an optional server-issued salt. This derived key exists only in the device's platform-backed secure storage (Android Keystore or iOS Keychain). Neither the passphrase nor the constituent salts are transmitted to, stored by, or recoverable from the platform's servers.

**The system cannot forge a user's signature.** Digital signatures are produced using Ed25519 private keys derived from a BIP39 mnemonic phrase generated with 256 bits of cryptographically secure entropy. The private key never leaves the device. It is never transmitted during synchronization, never included in QR payloads, and never uploaded to the routing server. Producing a valid Ed25519 signature requires possession of the 32-byte private scalar — a computational barrier that renders forgery infeasible under all known mathematical frameworks.

**The system cannot determine the monetary value of any transaction it routes.** The synchronization layer transports `SyncNode` objects containing an opaque `encryptedPayload` field. The server dispatches these nodes based on sender and receiver identifiers, but the payload — which contains the financial substance of the transaction — is encrypted with keys the server does not hold. The server can observe that User A sent a synchronization event to User B at a given time; it cannot determine whether that event represents a five-dollar coffee or a five-million-dollar contract.

**The system cannot reconstruct a user's identity from server-side data alone.** The routing server maintains authentication tokens, user identifiers, and channel subscription metadata — the minimum necessary for message delivery. It does not store the user's Ed25519 public key (which is exchanged directly between counterparties via QR codes), the user's mnemonic phrase, the user's financial records, or any mapping between the user's server-side identifier and their cryptographic signing identity.

**The system cannot prevent a user from destroying their own data.** The `PanicWipeService` provides an irrevocable credential destruction mechanism that obliterates all key material — the mnemonic phrase, the derived key pair, the database encryption passphrase, the PIN, the clock guard state, and the identity file — from all storage locations simultaneously. The encrypted database file remains on disk but is rendered permanently inaccessible, because the passphrase has been destroyed. This capability is by design: it ensures that the user retains ultimate authority over the existence of their data.

**Ecosystem expansion cannot introduce new access capabilities.** Qayd is architected as a foundational component within the Accsystem enterprise accounting ecosystem. This structural relationship is forward-compatible and data-model-aligned, but it does not — and architecturally cannot — grant Accsystem or any other ecosystem participant access to encrypted user data, key material, or signing authority. The integration surface exists exclusively at the export layer: locally decrypted data, formatted on the user's device, transmitted by the user's choice. No ecosystem expansion, platform update, or institutional partnership can alter this boundary, because it is enforced by the same asymmetric key architecture that governs all other system guarantees. The keys remain solely in the user's custody; the platform — and by extension, the ecosystem — remains blind.

### 1.2 The Boundary of Server Knowledge

To be precise about what the routing infrastructure *does* know: it knows that a registered user with a given numeric identifier has authenticated via a valid JWT token. It knows that this user subscribes to a private WebSocket channel. It knows the timestamp, sender ID, receiver ID, and event type of each `SyncNode` routed through the system. It knows the delivery state of each node (pending, delivered, read).

It does not know the financial amount, the currency, the parties' names, the account classifications, the ledger entries, the descriptions, the attachments, or any other substantive datum contained within any transaction it has ever routed. This is not because the server *chooses* not to look — it is because the data is encrypted with keys the server has never possessed.

---

## §2 — Data Sovereignty by Cryptographic Design

### 2.1 The User as the Sole Data Controller

In Qayd's architecture, the user is not merely a "data subject" with rights that a platform operator must honor — the user is the exclusive data controller in the most literal, technical sense. The cryptographic keys that encrypt, decrypt, and sign all financial data are generated on the user's device, stored in the user's device-level secure enclave, and never shared with the platform. The BIP39 mnemonic — the root of the entire cryptographic identity — is shown to the user exactly once during setup and can be backed up through a user-managed process whose completion is tracked by a local `backupConfirmed` flag. If the user fails to preserve the mnemonic and subsequently loses access to their device, the platform cannot assist in recovery, because the platform never possessed the mnemonic.

This arrangement inverts the conventional data custody model. In traditional systems, the platform holds the user's data and grants the user access through authentication. In Qayd, the user holds the data and grants the platform nothing more than a routing address. The asymmetry is absolute: the user can revoke the platform's relevance entirely by choosing to exchange vouchers only through QR codes, SMS channels, or P2P direct connections — all of which operate without server intermediation while maintaining full cryptographic integrity.

### 2.2 Device-Bound Key Material

The cryptographic identity is bound to a specific physical device through two reinforcing mechanisms. First, the database encryption key derivation incorporates a hardware identifier obtained from the device's firmware-level identity (Android Build ID, iOS vendor identifier, Windows device GUID), ensuring that the derived passphrase is unique to the originating hardware. Second, the `IdentityFileStorage` encrypts the backup identity file using an AES-CBC key similarly derived from the hardware identifier, ensuring that even the backup file is device-bound: copying it to a different device yields undecryptable ciphertext.

This device-binding serves a dual purpose. For security, it ensures that theft of the identity file alone — without theft of the physical device — does not compromise the user's signing authority. For legal positioning, it creates an inherent connection between a cryptographic signature and a specific piece of hardware, strengthening the evidentiary linkage between a signed voucher and the device from which the signature was provably generated.

### 2.3 Key Rotation Without Authority Gaps

The system supports key rotation through a generational model tracked by a `keyGeneration` counter in the `MnemonicVault`. When a key rotation occurs, the previous public key is archived in the counterparty's key history list (distributed via `CounterpartyQrService` payloads). The `SignatureVerificationEngine` validates incoming signatures against both the current key and all historical keys, ensuring that legitimate commitments signed under prior key generations remain verifiable indefinitely. At no point does the platform intermediary participate in the key rotation process — it is an entirely bilateral operation between the user and their counterparties.

---

## §3 — Responsibility Boundaries

### 3.1 The Platform's Responsibility

The platform operates a routing infrastructure. Its responsibilities are limited to:

Maintaining the availability and integrity of the WebSocket relay service, ensuring that `SyncNode` objects reach their intended recipients within reasonable delivery timeframes. Authenticating users through secure token-based mechanisms to prevent unauthorized channel subscription. Providing a registration and identity resolution service (phone/email to user ID mapping) to enable initial counterparty discovery. Preserving undelivered `SyncNode` objects in a pending queue until the recipient's device comes online.

The platform accepts no responsibility for, and has no technical capacity to intervene in, the content of encrypted payloads, the correctness of user-generated financial records, the validity of digital signatures, or the accuracy of amounts, dates, or classifications recorded by users. These are the exclusive province of the user's device-local application logic and the user's own judgment.

This responsibility boundary is invariant under ecosystem expansion. Qayd's role as a foundational component within the Accsystem enterprise accounting ecosystem does not expand the platform's access to user data, nor does it create shared custodial obligations between Qayd and Accsystem. The routing infrastructure remains a routing infrastructure. The architectural relationship between Qayd and the broader ecosystem is one of data model compatibility and export-layer alignment — not of shared encryption contexts, delegated key custody, or server-side data federation.

### 3.2 The User's Responsibility

Because Qayd places cryptographic authority entirely in the user's hands, the user bears correspondingly exclusive responsibility for certain critical domains.

**Mnemonic custody.** The 24-word BIP39 mnemonic is the ultimate recovery instrument. If lost, the cryptographic identity is unrecoverable by any party, including the platform. The user is responsible for preserving this phrase through whatever backup mechanism they deem appropriate — the system tracks whether the user has confirmed the backup but does not enforce any specific storage method.

**Signature authorization.** Every Ed25519 signature produced by the system represents a legally significant act of consent. The user is responsible for reviewing the financial substance of a commitment before authorizing signature generation. Once signed, a commitment cannot be retroactively unsigned — it can only be countered through a reversal voucher, which itself becomes a permanent, signed record.

**Device security.** The cryptographic identity resides in the device's secure storage. The user is responsible for maintaining physical security of the device, setting a device-level PIN or biometric lock, and utilizing Qayd's application-level PIN (managed by `AppPinStorage`) as an additional access barrier. If a device is compromised by an adversary who gains access to the unlocked application, the platform has no mechanism to prevent unauthorized signature generation — it can only provide the `PanicWipeService` for post-compromise credential destruction.

**Counterparty verification.** When importing a counterparty's identity via QR code, the user is responsible for confirming that the QR code originates from the intended party. The system preserves the imported public keys as immutable identifiers, but it cannot independently verify that the person presenting the QR code is who they claim to be — this is an inherently human verification step that no cryptographic system can fully automate.

### 3.3 The Device's Responsibility

The device occupies an intermediate trust layer. It is responsible for providing platform-backed secure storage that resists extraction by other applications (Android Keystore, iOS Keychain). It is responsible for accurate timekeeping — a responsibility that Qayd reinforces through the `MonotonicClockGuard`, which detects backward clock manipulation exceeding the 60-second tolerance window for legitimate NTP corrections. It is responsible for the integrity of the hardware identifier used in key derivation. And it is responsible for the correct execution of the cryptographic primitives — Ed25519 signing, SHA-256 hashing, PBKDF2 derivation, AES-CBC encryption — upon which the entire system's guarantees depend.

---

## §4 — Legal Defensibility Derived from Mathematics

### 4.1 Signatures as Evidence, Not Records of Clicks

Qayd's digital signature mechanism is designed to produce artifacts with genuine evidentiary weight, not merely records of user interaction. A standard application might log that "User X clicked the 'Approve' button at timestamp T" — a record that depends on the integrity of the application's logging infrastructure and can be challenged on the basis that the button click was accidental, the timestamp was manipulated, or the logging was fabricated.

A Qayd signature, by contrast, is a self-validating cryptographic proof. It demonstrates that the holder of a specific Ed25519 private key — a key that is device-bound, mnemonic-derived, and never exposed to any third party — deliberately authorized a SHA-256 hash of a specific canonical payload containing a specific amount, currency, date, sender, receiver, and transaction identifier. Verifying this proof requires only the signer's public key and the standard Ed25519 verification algorithm — both of which are openly available. The verification can be performed by any party, at any time, without any involvement from the platform. The mathematical validity of the signature is independent of the platform's continued existence.

### 4.2 The Canonical Payload as a Tamper-Evident Seal

The canonical payload format (`QAYD_RECEIPT_V1|amount|currency|sender|receiver|date|uuid`) is deliberately designed to include every financially material field while excluding mutable metadata (descriptions, notes, tags). This means that the signature attests to the precise financial substance of the commitment — the who, what, when, and how much — while permitting each party to independently annotate their own records without invalidating the bilateral cryptographic seal.

Any alteration to the signed fields — even a single minor-unit change in the amount — produces a different SHA-256 hash, which in turn invalidates the signature. The tamper-evidence is not probabilistic; it is absolute. A modified payload *cannot* produce a valid signature unless the modifier possesses the signer's private key.

### 4.3 Non-Repudiation Through Structural Exclusivity

Non-repudiation in Qayd does not depend on trusted third-party attestation. It arises from the structural exclusivity of key possession. The Ed25519 private key is derived from a BIP39 mnemonic generated with 256 bits of entropy, stored only in the device's secure enclave, and optionally backed up in a device-bound encrypted file that cannot be decrypted on other hardware. No copy of the private key exists on any server, in any log, or in any backup system accessible to the platform operator.

Therefore, if a valid Ed25519 signature exists over a canonical payload, and the corresponding public key is registered as belonging to a specific counterparty, the logical inference is that the signature was produced by that counterparty's device. The signer cannot claim that the platform forged the signature (the platform never possessed the key). The signer cannot claim that the payload was altered after signing (the hash would mismatch). The signer cannot claim that the signature was produced accidentally (the signing flow requires explicit user action within the application). The only remaining defense — that the device was stolen or compromised — shifts the evidentiary burden to the signer, who must then account for the failure of their own device security.

### 4.4 The Platform as a Non-Custodial Neutral

The platform's structural inability to access user data creates a distinctive legal position. The platform cannot be described as a "data processor" in the conventional sense, because it does not process user financial data — it routes opaque ciphertext. It cannot be ordered to produce user financial records in response to legal process, because it does not possess them. It cannot be held liable for the accuracy or falsity of financial records it has never seen. Its legal exposure profile resembles that of a postal service more than that of a financial institution: it conveys sealed letters between identified correspondents without reading their contents.

This positioning is not a loophole — it is a deliberate architectural choice to eliminate the custodial liabilities that inevitably attach to platforms that centralize user financial data. By designing the system so that meaningful financial data never exists on the server in any form — encrypted or otherwise — the platform removes itself from the chain of custody entirely. This non-custodial posture is preserved unconditionally as Qayd evolves within the Accsystem enterprise ecosystem. Future interoperability between Qayd and Accsystem's institutional modules does not introduce server-side decryption, shared key escrow, or any mechanism that would alter the platform's status as a blind intermediary. The evidentiary strength of user signatures, the integrity of the non-repudiation chain, and the sovereignty of user-held data remain governed by the same cryptographic primitives regardless of ecosystem scope.

---

## §5 — Alignment with Data Protection Principles

### 5.1 Data Minimization

The platform collects and retains only the minimum data necessary for its routing function: user registration credentials, authentication tokens, delivery metadata, and channel subscription state. It does not collect, process, or store any financial data, transaction content, account classifications, counterparty identities, or cryptographic key pairs. This is not a minimization *policy* — it is a minimization *architecture*. The data simply never reaches the server.

### 5.2 Purpose Limitation

Server-side data exists for exactly one purpose: routing encrypted synchronization events between authenticated users. There is no secondary use, no analytical processing, no profiling, and no data monetization, because the data that would enable such activities — the decrypted financial substance of transactions — is architecturally inaccessible to the server.

### 5.3 Storage Limitation

Server-side `SyncNode` retention is bounded by the delivery lifecycle: once a node is delivered and acknowledged, its utility to the routing infrastructure is exhausted. The encrypted payload, even if retained for delivery reliability, reveals nothing about the financial content of the transaction.

Device-side data retention is entirely under the user's control. The user may export, back up, or destroy their local database at any time. The `PanicWipeService` provides a comprehensive, irrevocable destruction capability that eliminates all key material and renders the encrypted database permanently inaccessible.

### 5.4 Integrity and Confidentiality

Confidentiality is guaranteed by the layered encryption model: AES-256 (SQLCipher) for data at rest, Ed25519-based end-to-end encryption for data in transit, and platform-backed secure storage for key material. Integrity is guaranteed by the Ed25519 digital signature protocol: any modification to a signed payload is detectable by any party holding the signer's public key. These guarantees are mathematical, not administrative — they do not degrade with organizational changes, personnel turnover, or policy revisions.

### 5.5 User Rights by Default

The architecture renders many conventional data-subject rights moot by preemptively satisfying them. The right of access is inherently fulfilled because the user holds their own data on their own device. The right to erasure is fulfilled by the `PanicWipeService` and by the user's ability to simply delete the application and its data. The right to portability is fulfilled by the multi-format export pipeline (PDF, Excel) and by the self-contained nature of the local database. The right to restrict processing is fulfilled by the fact that the platform does not process user financial data at all.

These are not rights that the platform *grants* to the user. They are properties that the architecture *cannot take away*.

---

## Closing Statement

Qayd's privacy and responsibility model is grounded in a single architectural conviction: that the most trustworthy system is one that is structurally incapable of betraying its users. By placing cryptographic keys exclusively in the user's custody, encrypting all financial data at the device level, routing only opaque ciphertext through its servers, and signing every commitment with unforgeable Ed25519 signatures, Qayd eliminates the categories of breach, misuse, and compelled disclosure that afflict platforms built on centralized data custody.

As a foundational component within the Accsystem enterprise accounting ecosystem, Qayd carries these guarantees forward into institutional contexts. The ecosystem relationship is one of structural alignment — shared data models, compatible accounting primitives, and interoperable export formats — not of shared secrets. No ecosystem expansion, no institutional integration, and no future product evolution can weaken the guarantees described in this document, because those guarantees are not organizational promises. They are consequences of the system's cryptographic architecture — and they will hold for as long as the mathematics hold.
