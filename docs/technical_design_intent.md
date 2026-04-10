# Technical Design Intent & System Philosophy of Qayd

**Classification:** Architectural Reference Document
**Revision:** 1.0 — April 2026
**Audience:** System Auditors · Legal Reviewers · Senior Engineers · Institutional Partners

---

## Preamble

Qayd is not an application in the conventional sense. It is a trust infrastructure — a cryptographically sovereign environment in which financial commitments between parties are created, signed, witnessed, and preserved with the same evidentiary discipline expected of notarized instruments. Architected as a foundational component within the broader Accsystem enterprise accounting ecosystem, Qayd is designed not merely to facilitate transactions but to produce records that are mathematically defensible, temporally anchored, and structurally incapable of unilateral falsification. While Qayd operates as a fully autonomous and independently functional system today, its data models, cryptographic protocols, and accounting primitives are deliberately shaped for forward-compatible alignment with institutional-grade accounting infrastructure — an alignment that is structural, not operationally coupled, and that at no point compromises the cryptographic sovereignty described throughout this document.

This document articulates the technical design intent behind each of Qayd's foundational subsystems. It is addressed to those who must evaluate the system's fitness for environments where financial records carry legal weight: auditors assessing data integrity guarantees, legal reviewers evaluating evidentiary admissibility, engineers integrating with institutional accounting infrastructure, and partners seeking assurance that the platform's privacy posture is a consequence of its mathematics, not its policy.

---

## §1 — Architecture as a Blind Carrier

### 1.1 The Zero-Knowledge Posture

Qayd's server infrastructure is architecturally precluded from accessing the financial substance of any transaction. The system operates as a *blind carrier*: it routes encrypted payloads between authenticated endpoints without possessing the cryptographic material necessary to decrypt them. This is not a policy commitment subject to future revision — it is a structural property enforced by the asymmetric key architecture itself.

The routing layer receives, stores, and delivers `SyncNode` objects — opaque containers whose `encryptedPayload` field holds ciphertext that only the designated sender and receiver can process. The server authenticates channel membership through token-based authorization and Pusher-protocol handshakes over private WebSocket channels (scoped as `private-user.sync.{userId}`), but at no point does it possess session keys, derive content keys, or decrypt payload bodies. The distinction is fundamental: the server knows *who* is communicating and *when*, but is structurally blind to *what* is communicated and *how much* is exchanged.

### 1.2 End-to-End Encryption and Device-Level Key Sovereignty

All user financial data resides within an SQLCipher-encrypted database (`qayd_finance.db`) whose passphrase is derived through a layered entropy model. The `HardwareBackedEncryptionKeyProvider` computes the database decryption key via PBKDF2, combining a locally generated cryptographic salt (32 bytes from `Random.secure()`), a server-issued salt when available, and a stable hardware identifier unique to the physical device. The derived key is cached in platform-backed secure storage (Android Keystore / iOS Keychain), ensuring that even physical extraction of the database file yields only ciphertext without the originating device.

The cryptographic identity itself — a BIP39 mnemonic phrase generated from 256 bits of entropy — is the root of all signing authority. From this mnemonic, the system deterministically derives an Ed25519 key pair through PBKDF2-SHA512 seed derivation, producing a 32-byte private scalar and corresponding public key. The mnemonic is persisted in the `MnemonicVault` within platform secure storage, and a redundant AES-CBC encrypted copy is written to a device-bound identity file by `IdentityFileStorage`, whose encryption key is itself derived from the hardware identifier. This dual-persistence model ensures survivability across application reinstallation while maintaining device-binding: the identity file, even if copied, cannot be decrypted on a different device.

### 1.3 Implications for Trust and Legal Robustness

The blind carrier architecture produces a system in which the platform operator cannot be compelled to produce user financial data, because it does not possess it. This is not a jurisdictional defense — it is a mathematical one. For the user, this means that their financial records are sovereign: no server breach, administrative subpoena directed at the platform, or insider threat can expose the substance of their transactions. For institutional partners, it means that integration with Qayd does not create a new custodial data liability. The platform routes commitments; it does not warehouse secrets.

---

## §2 — Digital Identity and the Non-Repudiation Engine

### 2.1 Cryptographic Signatures as the Foundation of Agreement

In Qayd, consent to a financial commitment is not represented by a boolean field or a timestamp of button interaction. It is expressed as a 64-byte Ed25519 digital signature computed over a deterministic canonical payload. The `ReceiptSigningService` constructs this payload from the immutable financial facts of the transaction — amount in minor currency units, ISO 4217 currency code, sender phone, receiver phone, ISO 8601 date, and receipt UUID — concatenated in a versioned, pipe-delimited format (`QAYD_RECEIPT_V1|...|...`). This canonical string is then hashed with SHA-256, and the resulting digest is signed using the signer's Ed25519 private key.

The resulting `DigitalSignature` value object encapsulates three elements: the 64-byte signature, the 32-byte signer public key, and the SHA-256 payload hash. Each voucher carries up to two such signatures — `senderSignatureHex` and `receiverSignatureHex` — with corresponding public keys, representing the independent cryptographic consent of each party. The `AgreementStatus` enum distinguishes between `underRequest` (no valid signature), `accepted` (verified against an authorized key), `rejected` (explicit refusal), and `unverified` (signature present but unmatched).

### 2.2 Cross-Vector Verification and Key Continuity

The `SignatureVerificationEngine` implements a multi-vector verification protocol that defends against key rotation confusion and identity spoofing. When an incoming voucher arrives — whether via the WebSocket sync channel, QR code scan, or SMS parsing — the engine resolves the sender's identity through phone and email lookup against the local account registry. It then retrieves the full array of authorized public keys for that counterparty: the current active key and all historical keys preserved through rotation events. Verification proceeds by reconstructing the canonical `SignableReceipt` payload with identical parameters, hashing it, and attempting signature validation against each authorized key in priority order — current key first, then historical keys in sequence.

This cascading verification ensures that legitimate signatures produced before a key rotation event remain verifiable indefinitely, while simultaneously ensuring that a signature produced by a revoked or unknown key is flagged as `unverified`. The system maintains no central key directory; key exchange occurs through direct QR-based counterparty import via `CounterpartyQrService`, which transfers the current public key and full key history in a base64-encoded, versioned payload. The imported key material is marked as strictly read-only — the importing party may modify the counterparty's display name but cannot alter phone, email, or cryptographic identifiers.

### 2.3 Temporal Integrity and Anti-Tamper Controls

The `MonotonicClockGuard` provides defense against system clock manipulation by persisting the UTC epoch of every significant database write operation in platform secure storage. On application start, the guard compares the current system time against the last known-good timestamp; a discrepancy exceeding 60 seconds of negative drift triggers a tamper detection flag. This mechanism ensures that the temporal dimension of signed payloads — the ISO 8601 date embedded in every canonical payload — cannot be retroactively falsified through clock rollback without detection.

### 2.4 Evidentiary Strength

The non-repudiation architecture produces records that satisfy three properties essential for legal defensibility. First, *authenticity*: each signature is bound to a specific Ed25519 private key that only the signer's device possesses, making fabrication by third parties computationally infeasible. Second, *integrity*: the signature covers the SHA-256 hash of the canonical payload, meaning any alteration of the amount, currency, date, parties, or UUID invalidates the signature. Third, *non-repudiation*: the signer cannot plausibly deny having authorized the transaction, because producing the signature requires possession of the private key — which is device-bound, mnemonic-derived, and never transmitted to the server.

---

## §3 — Tripartite State Synchronization

### 3.1 The Dual-Party Agreement Protocol

Every Qayd voucher exists simultaneously in the state spaces of two independent parties — the sender and the receiver — with the routing server acting as a stateless digital witness. The `Voucher` entity maintains two orthogonal state dimensions: the creator's workflow state (`VoucherState`: draft → confirmed → settled) and the bilateral agreement status (`AgreementStatus` for both sender and receiver). The sender's status is set to `accepted` at creation time — the act of creating and signing the voucher constitutes implicit consent. The receiver's status begins as `underRequest` and transitions to `accepted` only upon successful cryptographic signature attachment, or to `rejected` upon explicit refusal with a stated reason.

This separation of concerns is architecturally significant. A voucher in `confirmed` state with `receiverStatus: underRequest` represents a commitment that is internally ratified by the creator but not yet bilaterally authenticated. Only when both parties hold `accepted` status does the voucher achieve full documentary completeness — the digital equivalent of a dual-signed instrument.

### 3.2 Handshake-Based Finality and the SyncNode Protocol

State transitions are propagated between parties through the `SyncNode` messaging protocol, a typed event system carried over authenticated WebSocket channels. Each `SyncNode` contains a strongly typed event discriminator (`SyncEventType`: claim, acceptance, rejection, withdrawal, settlement, tripartiteRequest, and others) and an encrypted payload. The server routes these nodes without inspecting their content — it dispatches events to the target user's private channel and tracks delivery state (`pending`, `delivered`, `read`) but never decrypts the inner payload.

The receiver's acceptance or rejection generates a counter-event: an `acceptance` node carrying the receiver's own Ed25519 signature over the same canonical payload, or a `rejection` node carrying the reason for refusal. Upon receipt, the originating party's client verifies the incoming signature through the `SignatureVerificationEngine`, updates the local agreement status, and — if both parties are now `accepted` — transitions the voucher lifecycle to its terminal state. This handshake model ensures that finality is always bilateral; neither party can unilaterally declare a commitment complete.

### 3.3 Mutation Invalidation and the Re-Signing Lifecycle

The `Voucher` entity enforces strict mutability controls. Once a voucher transitions from `draft` to `confirmed`, the `updateDraft` method throws an `ImmutableEntityException` — the record is cryptographically sealed and may no longer be altered. Corrections to confirmed vouchers are handled through the threaded financial interaction model: a new voucher is created carrying an `originVoucherId` reference to the original, effectively functioning as a correction or reversal rather than an in-place mutation. This approach preserves the integrity of the original signature chain while providing a documented audit trail of amendments.

For vouchers still in draft state, any material modification (amount, currency, counterparty, date) invalidates the existing signature chain because the canonical payload will have changed. The creator must re-sign the modified draft, and the counterparty must re-evaluate and re-sign the new commitment. The system does not silently propagate modifications — it requires fresh cryptographic consent for every substantive change.

### 3.4 Tripartite Intermediary Transfers

Qayd extends the bilateral model to support tripartite transfer flows through the `TripartiteMeta` value object. When a mediating party (C) facilitates a transfer from source (A) to beneficiary (B), two linked vouchers are created: a receipt leg (A→C) and a payment leg (C→B), bound by a shared `transferGroupId`. The payment leg carries a `parentReceiptHash` — the SHA-256 hash of the receipt leg's canonical payload — creating a cryptographic chain that proves the outgoing payment is backed by the incoming receipt. The `isContingent` flag locks the second leg until the first achieves confirmation, preventing unbacked disbursement.

---

## §4 — Reactive Accounting Engine

### 4.1 Double-Entry Compliance as Behavioral Control

Qayd does not merely record transactions — it enforces the fundamental invariant of double-entry accounting as a structural constraint. The `EntryGenerator` service produces exactly two `LedgerEntry` objects for every confirmed voucher: a debit line and a credit line sharing a common `TransactionId`, with the sides determined by voucher type. For receipts, the affected account is debited and the counterparty credited; for payments, the inverse. The `LedgerEntry` entity is declared as `final class` with a private constructor — once created, it is immutable. Corrections are accomplished exclusively through reversal entries, never through mutation.

This design ensures that the ledger is an append-only, algebraically balanced log. No user action, no application logic, and no administrative intervention can produce an unbalanced entry or retroactively alter a posted line. The audit trail is not a feature layered atop the data model — it *is* the data model.

### 4.2 Stream-Based Balance Computation

The `BalanceCalculator` computes per-currency signed balances from the raw ledger lines using normal balance rules: debit-nature accounts accumulate as debits minus credits, credit-nature accounts as credits minus debits. This computation operates over the full set of ledger entries for a given account, producing a `Map<CurrencyCode, int>` of balances in minor units with no intermediate caching or denormalized totals.

Balance recomputation is triggered reactively through Bloc-based state management: creation, confirmation, or modification of any voucher emits state changes that cascade to dependent financial reporting Cubits — Trial Balance and Balance Sheet generators — which re-aggregate from the source ledger entries. This stream-based architecture ensures that reported balances are always consistent with the current ledger state, eliminating the class of "stale cache" discrepancies that plague systems relying on pre-computed balance fields.

### 4.3 Multi-Currency Integrity

The `Money` value object enforces currency-aware arithmetic at the type level. All amounts are stored as minor units (cents, fils) to eliminate floating-point imprecision. The `BalanceCalculator` segregates its aggregation by `CurrencyCode`, producing independent balance computations for each currency in which an account has activity. This per-currency treatment extends through the entire reporting pipeline — trial balance lines and balance sheet components carry discrete currency breakdowns rather than coerced single-currency totals.

---

## §5 — Physical-Digital Bridges

### 5.1 Signed QR Payloads

The `VoucherQrService` serializes voucher data into compact, base64-encoded JSON payloads suitable for rendering as QR codes. The v2 payload format embeds the full cryptographic signature chain — sender signature hex, sender public key, and signer phone — alongside the financial facts. Upon scanning, the receiving party's client extracts both the transaction parameters and the cryptographic proof, enabling offline signature verification without any server round-trip.

The QR encoding performs automatic role inversion: if the scanned payload represents a payment from the sender's perspective, the scanner's client presents it as a receipt. This symmetry ensures that both parties can independently generate verifiable QR representations of the same underlying commitment from their respective viewpoints.

### 5.2 SMS Receipt Parsing and Out-of-Band Verification

The `SmsReceiptListener` interface defines a secondary ingestion channel for financial commitments received as structured SMS messages. Incoming messages matching the Qayd receipt format are parsed into `IncomingReceipt` objects carrying the `SignableReceipt` payload, the sender's signature hex, and the signer's public key. These receipts pass through the same `SignatureVerificationEngine` as QR and WebSocket payloads, ensuring uniform cryptographic verification regardless of the transport channel.

This multi-channel approach is architecturally significant for inclusivity. In environments where internet connectivity is intermittent or absent, the SMS channel provides a degraded-but-cryptographically-complete path for exchanging signed commitments. The signature verification process is entirely local — it requires only the sender's public key (obtained via prior QR-based key exchange) and the canonical payload reconstruction algorithm. No network connectivity is required to validate the authenticity of a received commitment.

### 5.3 P2P Direct Synchronization

For scenarios requiring real-time bilateral exchange without server intermediation, `VoucherQrService` supports P2P connection establishment through `qayd://p2p?ip=...&port=...&pk=...` deep links. This channel enables WiFi Direct synchronization between devices, with the embedded public key providing the cryptographic anchor for mutual authentication. The P2P channel is functionally equivalent to the server-mediated WebSocket channel in terms of payload format and verification requirements — the only difference is the transport layer.

---

## §6 — Enterprise Compatibility and the Accsystem Bridge

### 6.1 ERP-Compliant Data Modeling

Qayd's internal data model is designed for structural compatibility with institutional accounting systems — and specifically, for forward-compatible integration with the Accsystem enterprise accounting platform, of which Qayd is a foundational component. The Chart of Accounts abstraction supports hierarchical account classification with `AccountClassification` types spanning assets, liabilities, equity, revenue, and expenses — the five fundamental account categories of any GAAP/IFRS-compliant system. Accounts carry `AccountNature` (debit or credit), enabling the `BalanceCalculator` to apply normal balance rules that map directly to standard trial balance and balance sheet presentations.

The `EntryGenerator` produces ledger entries that are structurally identical to the journal entries of an enterprise general ledger: each entry carries a transaction identifier, account reference, entry side (debit/credit), amount with currency, voucher reference, and timestamp. This structural correspondence is not accidental — it is designed so that Qayd's local ledger can be exported to or synchronized with Accsystem's general ledger, or any conforming ERP system, without semantic transformation. The alignment is at the data model level: shared account classification taxonomies, compatible entry structures, and consistent currency-aware arithmetic ensure that a Qayd-originated voucher can flow into an enterprise journal with zero information loss.

### 6.2 Lossless Export Pipeline

The system provides multi-format export capabilities through dedicated PDF and Excel generators. Trial balance and balance sheet reports are rendered as both interactive UI components and exportable documents, with the export pipeline consuming the same `TrialBalanceLine` and balance sheet data models used for on-screen presentation. This single-source-of-truth approach guarantees that exported reports are numerically identical to the live display — no rounding differences, no format-conversion artifacts, no semantic drift between the screen and the document.

### 6.3 From Personal to Institutional

Qayd's architecture anticipates a spectrum of usage contexts — from individual users tracking personal receivables and payables, through small businesses managing their counter-party ledgers, to institutional deployments requiring integration with the Accsystem ERP platform and other established enterprise systems. The server-side API follows RESTful patterns with policy-based authorization, paginated responses, and service-delegated business logic — conventions chosen specifically because they align with enterprise integration expectations and mirror the API architecture of the broader Accsystem ecosystem.

The cost center and dimensional analysis infrastructure (`CostCenter`, `CostCenterDimension`) provides the multi-axis classification capability expected by institutional accounting: the ability to allocate transactions across departments, projects, regions, and other organizational axes. Combined with the collateral management subsystem (`Collateral`, `CollateralRevaluation`), Qayd offers a data model that can evolve from a personal commitment tracker into a fully institutional financial instrument registry without requiring structural migration.

### 6.4 Ecosystem Integration and Cryptographic Sovereignty Preservation

Qayd's position as a foundational component of the Accsystem ecosystem raises a question that this document must address directly: does ecosystem integration compromise the cryptographic guarantees described in §1 through §5?

The answer is no, by architectural necessity. The integration surface between Qayd and Accsystem is defined exclusively at the data model and export layer — account classifications, ledger entry structures, trial balance aggregations, and report formats. These are structural outputs that the user's device produces locally from the decrypted database. At no point does ecosystem compatibility require the server infrastructure — whether Qayd's routing layer or Accsystem's enterprise platform — to access decrypted user data, hold user key material, or participate in the signing process.

The bridge between Qayd and Accsystem is, by design, a *user-initiated, device-local export operation*, not a server-to-server data pipeline. The user decides what to export, the user's device performs the decryption and formatting, and the resulting output — whether a PDF, an Excel file, or a structured data payload — is transmitted by the user through whatever channel they choose. The platform merely ensures that the local data structures are semantically compatible with the destination system's expectations. This architecture guarantees that ecosystem expansion cannot introduce shared key custody, server-side decryption, or any erosion of the blind carrier posture — because the integration point exists entirely within the user's own device, below the encryption boundary.

---

## Closing Architectural Statement

Qayd's architecture is designed around a single organizing principle: that the trustworthiness of a financial record should be derived from its mathematical properties, not from the reputation of the institution that hosts it. Every subsystem — from the blind carrier network, through the Ed25519 signing protocol, to the immutable double-entry ledger — is shaped by this principle. This principle does not weaken as Qayd evolves within the Accsystem ecosystem; it strengthens, because the same cryptographic guarantees that protect an individual user's personal ledger will protect an institution's enterprise journal entries with identical mathematical rigor.

The system does not ask its users to trust it. It asks them to verify.
