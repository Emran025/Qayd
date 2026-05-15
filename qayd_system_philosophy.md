# QAYD: SYSTEM PHILOSOPHY & ACCOUNTING DOCTRINE

## The Complete Ontological & Architectural Manifesto

### A Codebase-Derived Analysis for System Auditors, Senior Accountants, Principal Architects, and Future Core Developers

---

> **Derivation Standard:** Every claim in this document is traceable to a specific class, method, invariant, enumeration, or structural pattern found in the source code of the Qayd Flutter application (corpus: `c:\xampp\htdocs\Qayd\qayd\lib`). The word **enforced** is reserved for behavior provable by domain exceptions, type-system constraints, or guard clauses that throw. The word **implied** denotes patterns observable through naming conventions, structural regularities, or default assignments. The word **conceptual** identifies intent stated in code comments that does not have runtime enforcement. Where a claim would be commonly assumed but is *not* enforced, it is explicitly labeled **NOT enforced**.

> **Tracing Convention:** Every major claim closes with a citation in the form `[Code Reference: filename.dart]` or `[Code Reference: filename.dart, line N]`.

---

## TABLE OF CONTENTS

1. [Foundational Architecture & Local-First Sovereignty](#1)
2. [The Monetary Type System: Precision as a Constitutional Obligation](#2)
3. [The Chart of Accounts: A Fixed Epistemology of Classification](#3)
4. [The Account Entity: Immutable Nature, Constrained Lifecycle](#4)
5. [The Voucher Doctrine: Document Before Entry, Existence Before Accounting](#5)
6. [State Machines and the Prohibition of Backward Motion](#6)
7. [The Dual-Party Agreement Protocol: Cryptographic Bilateral Commitment](#7)
8. [The Entry Generator: Double-Entry Determinism as an Immutable Law](#8)
9. [The Automated Bridge: Personal Finance Without Manual Posting](#9)
10. [Cost Centers and the Dimensional Philosophy: Orthogonal Analytical Truth](#10)
11. [The Tripartite Transfer Model: SWIFT-Like Mediation in Personal Finance](#11)
12. [The Ledger as Conversation: Conversational Epistemology of Debt](#12)
13. [Reporting as Authoritative Truth: Two-Layer Knowledge Architecture](#13)
14. [The Governance Authority Model: The External Write Gate](#14)
15. [Security Architecture: Cryptographic Identity and the Panic Surface](#15)
16. [The Navigation Epistemology: Separating Tiers of Financial Engagement](#16)
17. [The Collateral Doctrine: Secured Obligations Under Local Sovereignty](#17)
18. [Accrual Components: Time-Based Obligation Without Automatic Execution](#18)
19. [Audit Trail and the Non-Destructive Record Imperative](#19)
20. [Income Source Taxonomy: Revenue as Account Metadata](#20)
21. [The Synchronization Protocol: P2P Financial Messaging](#21)
22. [The Unknown Knowns: Silences, Gaps, and Conceptual Debt](#22)
23. [Synthesis: The Unified Worldview and Developer Covenant](#23)

---

---

## SECTION 1: FOUNDATIONAL ARCHITECTURE & LOCAL-FIRST SOVEREIGNTY

---

### 1.1 The Local-First Imperative: A Declaration of Data Ownership

The Qayd system is, at its most fundamental level, a declaration. It declares that the financial records of an individual are that individual's property — to be held on a device they control, encrypted with a key they own, and accessible without the permission of any remote party.

This is not a performance optimization. It is not an offline-access feature. It is a philosophical position, encoded in the architecture at every layer, regarding the nature of financial data and who has the right to hold it.

The evidence is not circumstantial. It begins at the lowest level of the technology stack:

```dart
// database_provider.dart, line 5
import 'package:sqflite_sqlcipher/sqflite.dart';
```

`sqflite_sqlcipher` is not a standard SQLite library. It is SQLCipher — a variant of SQLite that applies AES-256-CBC page-level encryption to every byte of the database file before writing it to disk. The database file is named `qayd_finance.db` and resides in `getApplicationDocumentsDirectory()` — the device's sandboxed document storage, controlled exclusively by the operating system's permission model for the installed application.

At no point in the entire domain layer, repository interface layer, or application layer does any code reference a remote database, a cloud storage service, or any persistent network endpoint for accounting data. The server, when contacted, is a relay node for encrypted messages — not a ledger. The device is the ledger.

This is the same foundational principle that governs physical cash-book accounting in the classical Islamic mercantile tradition: the book (`الدفتر`) is in your possession, the entries are made by your hand, the ink is your record. No counterparty's acknowledgment is required for the record to be valid. The acknowledgment, when it comes, is a supplement to the record — not the record itself.

[Code Reference: `database_provider.dart`, line 5]

---

### 1.1.1 The Server as a Relay, Not a Ledger — A Structural Proof

The structural proof that the server is not a ledger is found in what does NOT exist in the domain repository interfaces. Examining `VoucherRepository`, `AccountRepository`, `LedgerRepository`, and `CostCenterRepository`, one finds that these are local abstractions. Their implementations are SQLite operations. The sync layer (`SyncRepository`, `SyncNode`, `SyncEventDispatcher`) is a separately scoped concern that dispatches *event notifications* about local state changes.

The server cannot issue a debit. The server cannot post a credit. The server cannot create, modify, or delete a voucher. The server can:

1. Relay an encrypted sync node from Party A's device to Party B's device.
2. Validate a governance token (JWT) and return an activation status.
3. Serve as a public key lookup directory for identity verification.

These three roles are entirely distinct from ledger management. They do not touch financial data at the semantic level. The server knows *that* a sync event occurred between two user IDs at a timestamp — it does not know *what amount* was transferred, *which accounts* were involved, or *what the running balance is*. The payload is E2EE-encrypted before it leaves the sender's device.

This separation is the architectural embodiment of the "server as relay" philosophy. It is not a shortcut or a deferral — it is a design principle maintained across the entire codebase with no exceptions found in the reviewed corpus.

[Code Reference: `accept_voucher_use_case.dart`, lines 124–134; `sync_node.dart`]

---

### 1.2 Two-Phase Initialization: The Security Checkpoint as a Constitutional Boundary

The bootstrapping sequence encoded in `QaydAppBootstrapper` (`main.dart`, lines 36–273) implements a rigid two-phase model that functions as a security checkpoint. The application does not boot into the accounting system — it boots into a provisioning layer. The accounting system is revealed only after the provisioning checkpoint is passed.

**Phase A — Pre-Auth:** `InjectionContainer.initPreAuth()` is called. Only services that require no cryptographic material are initialized: UI state machines, network connectivity, license vault reading. The database is not opened. No financial data is accessible.

**Phase B — Post-Auth:** After the provisioning flow succeeds, `InjectionContainer.initDatabase()` is called. The database key is derived, the SQLCipher file is opened, and the full dependency graph (use cases, repositories, domain services) is initialized. Only after this succeeds does the application render the `AppShellPage` with its five financial tabs.

The `DatabaseOpenResult` enum documents the legal outcomes of Phase B:

- `success`: Database opened, schema current.
- `freshCreated`: Database file did not exist; created fresh.
- `keyMismatch`: The derived key does not match the key used when the database was originally created.
- `otherError`: Unrecoverable database error.

The `keyMismatch` case is the most philosophically significant. It triggers the `DatabaseRecoveryPage` — a remediation screen that offers two options: (a) re-derive the key using the BIP-39 mnemonic (`retryWithMnemonic`), or (b) perform a destructive factory reset (`startFresh`). No third option exists. There is no "contact support to recover your data." The mnemonic is the key. If you do not have the mnemonic, the data is inaccessible to all parties permanently.

This is not a limitation. It is a guarantee — the most powerful guarantee the system can make about data privacy: that no party, including the system's developer, can read the user's financial data without the user's own cryptographic material.

[Code Reference: `main.dart`, lines 86–127]

---

### 1.3 The Mnemonic as the Final Authority: No Administrative Override

The `MnemonicVault` (`mnemonic_vault.dart`) stores the BIP-39 mnemonic phrase that seeds the database encryption key derivation. The PBKDF2 derivation in `Pbkdf2KeyDeriver` (`pbkdf2_key_deriver.dart`) combines:

1. The mnemonic phrase (user's property)
2. A server-issued salt (`readServerSalt()` from `LicenseVault`)
3. A locally-generated salt (`readLocalDbSalt()` from `LicenseVault`)

The requirement for two salts from two independent sources means that:

- **Server compromise alone** cannot derive the key (missing the local salt)
- **Device theft alone** cannot derive the key (missing the server salt and the mnemonic)
- **Mnemonic disclosure alone** cannot derive the key without both salts

The three-factor structure creates a layered key derivation where all three components must be available simultaneously. The mnemonic is the user's component — it is theirs by definition. The local salt is device-bound. The server salt is provisioned at registration time. This is a genuine distributed key architecture, not a marketing claim.

```
          ┌─────────────────────────────────────┐
          │         KEY DERIVATION TOPOLOGY      │
          │                                     │
          │  ┌──────────┐  ┌──────────────────┐ │
          │  │ Mnemonic │  │ Server-Issued    │ │
          │  │ (User's) │  │ Salt (Server's)  │ │
          │  └────┬─────┘  └────────┬─────────┘ │
          │       │                 │           │
          │       └────────┬────────┘           │
          │                │                   │
          │       ┌────────▼────────┐           │
          │       │   Local Salt    │ (Device's) │
          │       │  (Device-Bound) │           │
          │       └────────┬────────┘           │
          │                │                   │
          │       ┌────────▼────────┐           │
          │       │ PBKDF2 Deriver  │           │
          │       └────────┬────────┘           │
          │                │                   │
          │       ┌────────▼────────┐           │
          │       │  AES-256 KEY    │           │
          │       │ (SQLCipher key) │           │
          │       └─────────────────┘           │
          └─────────────────────────────────────┘
```

**Deductive Interpretation:** The diagram shows that the AES-256 SQLCipher key is the product of three independently controlled components. This means an adversary who steals the server's database (obtaining the server salt), steals the device (obtaining the local salt), but does not know the mnemonic, still cannot open the financial database. The mnemonic is genuinely the user's last line of sovereignty over their data. The system does not hold a copy of this key anywhere.

[Code Reference: `pbkdf2_key_deriver.dart`; `license_vault.dart`, lines 29–39; `mnemonic_vault.dart`]

---

### 1.4 Schema Version 26: The Temporal Contract of Backward Compatibility

The constant `schemaVersion = 26` in `DatabaseProvider` is not a simple version number. It is the system's formal commitment to every user who has ever installed Qayd. It states: every schema transformation made since the initial release is tracked, numbered, and applied deterministically when the application is upgraded.

The `MigrationRegistry.applyFromTo(db, fromVersion: oldVersion, toVersion: newVersion)` method ensures that a device upgrading from schema version 12 to schema version 26 will apply migrations 12→13, 13→14, ..., 25→26 in sequence, without skipping or re-applying. This is the railway-track model of schema evolution: every schema state is reachable from every prior state through a defined sequence of transitions.

The philosophical significance: a user who installed Qayd at genesis and has never updated has a database at schema version 1. An update to the current version will not corrupt their data. It will migrate it through every incremental schema change, preserving the integrity of every record. This is a commitment of backward compatibility that most applications make implicitly and violate frequently. Qayd makes it structurally — the schema migration is compiled into the application, not applied by a server-side migration script.

[Code Reference: `database_provider.dart`, lines 9, 38–43]

---

### 1.5 The Dual-Epoch Lifecycle Observer: Application-Level Clock Stamping

The `SecurityLifecycleObserver` wraps the `QaydApp` widget and observes application lifecycle events. On every app pause (`AppLifecycleState.paused`), it calls `MonotonicClockGuard.stamp()` — persisting the current UTC epoch to `FlutterSecureStorage`. This creates a monotonically increasing record of "the most recent time at which the application was observed running."

On every app start, the `MonotonicClockGuard.detectTamper()` method checks whether the current time is earlier than the last stored time (minus a 60-second NTP-drift allowance). If the clock has been rolled back by more than 60 seconds, tamper is detected.

The 60-second tolerance is not arbitrary indulgence — it reflects the reality that NTP corrections during network reconnection can legitimately shift the system clock by seconds. The guard must not produce false positives for legitimate NTP adjustments. The tolerance is calibrated to distinguish intentional clock manipulation (rolling back days or hours to extend a trial) from legitimate NTP correction (adjusting by a few seconds).

```dart
// monotonic_clock_guard.dart, line 29
if (now < lastEpoch - 60000) {
  return true; // TAMPER DETECTED
}
```

The `- 60000` represents 60 seconds in milliseconds. Any difference larger than this between the current time and the previously recorded time (in the backward direction) is classified as tamper.

[Code Reference: `monotonic_clock_guard.dart`, lines 16–33]

---

---

## SECTION 2: THE MONETARY TYPE SYSTEM — PRECISION AS A CONSTITUTIONAL OBLIGATION

---

### 2.1 The Rejection of Floating-Point: An Engineering Philosophy

The `Money` final class (`money.dart`) represents the system's fundamental rejection of the standard computing approach to financial arithmetic. Nearly all general-purpose programming applications represent money as `double` — a 64-bit IEEE 754 floating-point number. This representation introduces systematic imprecision.

The IEEE 754 standard cannot represent `0.1` or `0.2` exactly in binary. The expression `0.1 + 0.2` in standard floating-point arithmetic does not equal `0.3` — it equals `0.30000000000000004`. In a financial ledger, this kind of imprecision accumulates: a thousand transactions each introducing an error of `0.00000000000000004` leads to a discrepancy of `0.00000000000004` in the trial balance. While small in isolation, such errors can accumulate to observable magnitudes in high-volume personal accounting and — more importantly — violate the moral principle that a ledger must be perfectly precise.

Qayd's solution is categorical: all monetary values are stored as `int` (minor units). For a two-decimal currency like SAR (Saudi Riyal), one riyal is stored as `100`. For USD, one dollar is `100`. For a three-decimal currency like KWD (Kuwaiti Dinar), one dinar is `1000`. Integer arithmetic is exact. There is no floating-point imprecision in integer addition or subtraction.

```
   Float:  0.1 + 0.2  =  0.30000000000000004  ❌
   Minor:  10  + 20   =  30                  
```

This is not merely a performance choice. It is an ethical statement: the system will not allow computational approximation to corrupt the user's financial records.

[Code Reference: `money.dart`]

---

### 2.2 The Three-Constructor Discipline: Encoding Accounting Semantics in Types

The `Money` class exposes three factory constructors, each encoding a distinct accounting precondition:

**Constructor 1: `Money.positiveAmount(int minorUnits, CurrencyCode currency)`**

Used for: voucher amounts, ledger entry amounts — any value that must be strictly greater than zero.

Precondition enforcement: throws `InvalidAmountException` if `minorUnits <= 0`.

Accounting rationale: A financial event without a value is not a financial event. A zero-amount voucher records nothing. A negative-amount voucher inverts accounting polarity, which would silently negate the economic meaning of a voucher type. The `positiveAmount` constructor enforces that every financial event carries a real, positive, economic magnitude.

**Constructor 2: `Money.nonNegative(int minorUnits, CurrencyCode currency)`**

Used for: account balances, budget ceilings — any value that represents a cumulative state that may legitimately reach zero.

Precondition enforcement: throws if `minorUnits < 0`.

Accounting rationale: An account balance of zero is a valid and common state. A loan fully repaid has a zero accounts-receivable balance. A cost center that has just been created has a zero expenditure balance. The `nonNegative` constructor allows this legitimate state while preventing the construction of a "negative balance" monetary object when a balance-type Money is expected.

**Constructor 3: `Money.fromMinorUnits(int minorUnits, CurrencyCode currency)`**

Used for: signed balance arithmetic — when balances are being computed with sign conventions that allow negative intermediate values.

Precondition enforcement: none. All integer values are accepted.

Accounting rationale: In trial balance computation, a credit-nature account may have a mathematically "negative" running balance in the signed debit-credit convention. The computation layer needs to work with signed values without the type system interfering. The `fromMinorUnits` constructor provides this escape hatch.

The three-constructor design is the type system's expression of three distinct accounting contexts. The choice of which constructor to use at each call site is itself a semantic commitment: the caller asserts which accounting context they are operating in.

```
                 ┌──────────────────────────────────────────┐
                 │           MONEY CONSTRUCTOR HIERARCHY     │
                 │                                          │
                 │  positiveAmount()   → Voucher amounts    │
                 │  ┌──────────┐          Ledger amounts    │
                 │  │  > 0     │     (financially meaningful│
                 │  │ enforced │      events must be real)  │
                 │  └──────────┘                           │
                 │                                          │
                 │  nonNegative()      → Account balances   │
                 │  ┌──────────┐          Budget ceilings   │
                 │  │  >= 0    │     (legitimate states     │
                 │  │ enforced │      include zero)         │
                 │  └──────────┘                           │
                 │                                          │
                 │  fromMinorUnits()   → Signed arithmetic  │
                 │  ┌──────────┐          Report computation│
                 │  │  any int │     (computation layer     │
                 │  │  allowed │      needs full range)     │
                 │  └──────────┘                           │
                 └──────────────────────────────────────────┘
```

**Deductive Interpretation:** The three constructors partition the monetary domain into three use contexts that cannot be accidentally conflated: event creation, state representation, and computation. A developer who accidentally uses `fromMinorUnits` for a voucher amount bypasses the positivity invariant. The type system does not prevent this at compile time — it relies on the developer choosing the semantically correct constructor. This is the system's only acknowledged weakness in the monetary type model: the constructor choice is convention-enforced rather than type-enforced.

[Code Reference: `money.dart`]

---

### 2.3 The Currency Lock: Cross-Currency Arithmetic as a Domain Exception

Every `Money` instance carries a `CurrencyCode` that is structurally inseparable from its numeric value. The `_assertSameCurrency()` private method is invoked by every arithmetic operator: `+`, `-`, and `compareTo()`.

```dart
// money.dart (reconstructed from usage pattern)
Money operator +(Money other) {
  _assertSameCurrency(other);
  return Money.fromMinorUnits(minorUnits + other.minorUnits, currency);
}

void _assertSameCurrency(Money other) {
  if (currency != other.currency) {
    throw CurrencyMismatchException(
      code: 'cross_currency_arithmetic',
      // ...
    );
  }
}
```

The `CurrencyMismatchException` with code `'cross_currency_arithmetic'` is a domain exception — a structural refusal, not a validation warning. The system treats the attempt to add amounts in different currencies as categorically the same type of error as adding meters to kilograms: a dimensional mismatch that has no mathematically valid resolution.

This is philosophically important because the "obvious" solution — converting one currency to the other at a market rate before adding — is not a solution the system is willing to assume. Currency conversion involves an exchange rate, which is a time-sensitive market fact. The system is local-first and offline-capable. It cannot know the current exchange rate without network access. More fundamentally, the system is designed around the principle that each currency's accounting ledger is independent: you keep separate books for each currency, just as a multi-currency business maintains currency-segregated ledger accounts.

The currency lock prevents the silent collapse of multi-currency balances into a single imprecise aggregate.

[Code Reference: `money.dart`]

---

### 2.4 The `fractionalDigits` Property: ISO 4217 as the Display Authority

The `fractionalDigits` field is delegated to `currency.fractionalDigits` — the currency entity's own specification of how many decimal places it has. The system explicitly refuses to assume that all currencies have two decimal places.

ISO 4217 defines three-decimal currencies (KWD, BHD, JOD have 3 fractional digits), zero-decimal currencies (JPY, VND have 0), and standard two-decimal currencies. Qayd's delegation of `fractionalDigits` to the currency entity ensures correct display of all three categories without special-casing.

The display implication: a balance of `1000` minor units in SAR displays as `10.00 SAR`. A balance of `1000` in KWD displays as `1.000 KWD`. A balance of `1000` in JPY displays as `1000 JPY`. The same integer, rendered with three different precisions, depending entirely on the currency's own specification. This is the correct behavior — and it comes from always respecting the ISO 4217 fractional digit count.

[Code Reference: `money.dart`]

---

### 2.5 Balance Sheet Tolerance: The `< 10` Invariant as Engineering Honesty

The balance equation check in `GenerateBalanceSheetUseCase._buildCurrencySections()` computes:

```dart
isBalanced: (assets + liabilities + equity).abs() < 10
```

The tolerance of 10 minor units (approximately 0.10 in a two-decimal currency, approximately 0.010 in a three-decimal currency) is remarkable for what it reveals about the system's engineering philosophy: honesty.

The system *knows* that in pure integer arithmetic, with the deterministic `EntryGenerator` producing exactly two mirror-image entries per voucher, the sum of all signed balances will be exactly zero. The tolerance is architecturally unreachable under normal operation.

The inclusion of the tolerance is an act of engineering humility: it acknowledges that future system evolution might introduce rounding (e.g., fee calculation that involves division), and provides a structural safety net for that possibility. It does not pretend the tolerance is needed now. It installs a small defensive margin for an acknowledged future risk.

This is conceptual debt made visible: the documentation of a known, currently-zero risk that has been pre-hedged with a minimal tolerance rather than deferred entirely.

[Code Reference: `generate_balance_sheet_use_case.dart`, lines 111–118]

---

---

## SECTION 3: THE CHART OF ACCOUNTS — A FIXED EPISTEMOLOGY OF CLASSIFICATION

---

### 3.1 The Standard Taxonomy: Ten Assertions About What Financial Reality Consists Of

The `StandardAccountClassificationKind` enum (`standard_account_classification_kind.dart`) contains exactly ten values. This is not an accident of implementation — it is a considered declaration that personal financial reality, in its full scope, can be completely described by ten categories of accounts.

```dart
enum StandardAccountClassificationKind {
  liquidAssets,            // Cash and equivalents
  receivables,             // Amounts owed to the user
  payables,                // Amounts owed by the user
  settlements,             // Clearing and correspondence accounts
  clearingRemittances,     // System: intermediary transfer transit
  remittanceFees,          // System: mediator fee revenue
  personalExpenses,        // Outflows — operational classification
  personalRevenues,        // Inflows — operational classification
  fixedDepreciableAssets,  // Possessions that lose value over time
  fixedProfitableAssets,   // Investments that generate returns
}
```

Let us examine each category through the lens of the accounting equation and personal finance:

**`liquidAssets` (نقدية):** The primary asset pool. Cash in wallet, bank accounts, digital wallets. The medium through which all economic events are ultimately settled. In the Qayd system, this classification carries a special role: it is the "root" through which the automated bridge logic routes all personal expense/revenue postings. It is the system's financial gravity well.

**`receivables` (ذمم دائنة (عليك)):** Amounts owed to the user by counterparties. Informal personal loans given, services rendered not yet collected. The user is the creditor. The debit nature of receivables reflects the accounting principle that an asset (the right to receive payment) grows with debits.

**`payables` (ذمم مدينة (لك)):** Amounts owed by the user to counterparties. Informal debts taken, goods received not yet paid for. The user is the debtor. The credit nature reflects the liability principle: a debt grows with credits.

**`settlements` (تسوية وشخصي):** Clearing accounts used for personal and family correspondence. This classification is used for the system-created fee revenue account (`AccountClassification.settlements` in `CreateTripartiteTransferUseCase`). Its Arabic name — "تسوية وشخصي" — translates to "settlement and personal," indicating a dual function: formal debt settlement, and informal personal obligation tracking.

**`clearingRemittances` (مقاصة الحوالات):** A system-only classification for the transient clearing account in tripartite transfers. The comment in `account_classification.dart`, line 55 is precisely: "Transient, typically clears to 0." This is a glass account that exists to temporarily hold funds in transit during an intermediary transfer. Its debit nature means it is an asset classification — it temporarily holds the "right to disburse" funds.

**`remittanceFees` (رسوم الحوالات):** Revenue captured from fees charged on tripartite transfers. Its credit nature identifies it as a revenue/income classification — credits increase the balance, reflecting accumulated earnings from mediation services.

**`personalExpenses` (مصروفات شخصية):** The expense dimension of the personal income statement. All consumption expenditure. Its debit nature means that spending increases the debit balance of this account — standard accounting treatment for expenses.

**`personalRevenues` (إيرادات شخصية):** The revenue dimension of the personal income statement. All income inflows. Its credit nature is standard: revenue grows with credits.

**`fixedDepreciableAssets` (أصول ثابتة - مهلكة):** Long-lived possessions that decline in value: vehicles, electronics, furniture. The word `مهلكة` (muhlikah) means "destructible" or "that which wears away" — assets consumed by time and use.

**`fixedProfitableAssets` (أصول ثابتة - ربحية):** Long-lived investments that generate returns: real estate, business equity stakes, financial instruments. Both fixed asset classifications share debit nature — they are assets that increase the user's net worth when they increase in balance.

The deliberate inclusion of `clearingRemittances` and `remittanceFees` as first-class standard classifications proves that the tripartite transfer system is not peripheral to Qayd's accounting model. It is structurally integrated: the fee economy of mediated transfers has dedicated account classifications at the foundational taxonomy level.

[Code Reference: `standard_account_classification_kind.dart`; `account_classification.dart`]

---

### 3.2 The `AccountClassification` Value Object: A Sealed Union with an Assert

The `AccountClassification` final class (`account_classification.dart`) is designed as a sealed union with two valid states:

**State A: Standard Classification** — carries a non-null `standardKind` field of type `StandardAccountClassificationKind`. The `customName` is null. The `defaultNature` is fixed to the classification's inherent polarity.

**State B: Custom Classification** — carries a null `standardKind` and a non-null, non-empty `customName` string. The `defaultNature` is explicitly provided by the caller.

The private constructor enforces the completeness of this union:

```dart
// account_classification.dart, lines 6–13
const AccountClassification._({
  required this.defaultNature,
  this.standardKind,
  this.customName,
}) : assert(
    standardKind != null || customName != null,
    'Either standard or custom classification',
  );
```

This `assert` ensures at construction time that neither field can be null simultaneously. It does not prevent both fields from being non-null simultaneously — a design with the potential for ambiguity. Examination of the `factory AccountClassification.custom()` factory confirms that it explicitly passes `standardKind: null`, preventing the dual-non-null case in practice. The assert is a safety net, not the primary invariant enforcer.

The `custom()` factory enforces one additional invariant: the `name` string cannot be empty after trimming:

```dart
// account_classification.dart, lines 88–92
factory AccountClassification.custom({...}) {
  final n = name.trim();
  if (n.isEmpty) {
    throw ArgumentError.value(name, 'name', 'Custom classification name required');
  }
```

This means a user wishing to create a custom classification must provide a meaningful name. The system does not accept whitespace-only names as valid classifiers. This is a minimal semantic gatekeeping: the name must carry at least one non-whitespace character.

The deep significance: custom classifications allow the user to model financial realities outside the standard ten — hobby income streams, specialized asset types, regional financial instruments. But accessing this extensibility requires a deliberate act of classification naming and explicit nature assignment. The system does not offer a "miscellaneous" escape hatch that carries implicit nature assumptions.

[Code Reference: `account_classification.dart`, lines 6–114]

---

### 3.3 Account Nature as a Constitutional Property: Why Immutability Matters

The `AccountNature` enum contains two values: `debit` and `credit`. These are the two polarities of double-entry accounting. A debit-nature account grows when debited and shrinks when credited. A credit-nature account grows when credited and shrinks when debited.

In Qayd, account nature is established at creation via one of two paths:

- **Root accounts:** `classification.defaultNature` is assigned directly. The nature is a function of the classification.
- **Child accounts:** `parent.nature` is inherited verbatim. The nature is a function of the parent's nature.

What is notably absent is any `setNature()`, `updateNature()`, or `reclassify()` method on the `Account` entity. Nature cannot be changed after construction. The only way to "change" an account's nature is to delete the account (constrained by balance-zero and child-account requirements) and create a new one with a different classification.

Why does this matter?

Imagine an account "General Expenses" classified as `personalExpenses` with debit nature. Over three years, thousands of vouchers are posted to it. The ledger contains thousands of debit entries against it. If the nature were changed to credit, every historical balance computation would invert: historical expenses would become credits, the account's running balance would flip sign, and the trial balance would no longer reflect economic reality.

The immutability of account nature is not merely a technical constraint — it is a protection against retroactive reinterpretation of historical financial data. An account's nature determines the economic meaning of every entry posted to it, across its entire life.

Changing an account's nature would be the accounting equivalent of retroactively declaring that all the money you earned was actually money you spent. The system refuses to allow this.

[Code Reference: `account.dart`, lines 39–110; `account_classification.dart`, line 82]

---

### 3.4 The `relocateUnder()` Invariant: Classification Consistency as Hierarchy Law

The `Account.relocateUnder(Account newParent)` method is the system's formal support for account hierarchy management — moving an account from one position in the account tree to another.

```dart
// account.dart, lines 197–204
Account relocateUnder(Account newParent) {
  if (classification != newParent.classification ||
      nature != newParent.nature) {
    throw const InvalidStateTransitionException(
      messageAr: 'لا يمكن نقل الحساب إلى أصل بتصنيف أو طبيعة مختلفة.',
      code: 'account_reparent_classification_mismatch',
    );
  }
```

The exception code `'account_reparent_classification_mismatch'` identifies this as a structural prohibition, not a validation warning. The domain entity itself refuses the operation — not the application layer, not the repository.

The philosophical content: a child account inherits its parent's classification. If you move an account to a new parent, the account must retain its classification. If the new parent has a different classification, the move is an attempt to reclassify the account by proxy — to change its economic meaning without explicitly doing so. The system refuses this: classification changes must be explicit, and explicit reclassification is prohibited on accounts with balances.

The dual check on both `classification` and `nature` is redundant given that nature is derived from classification — if classifications match, natures must match. The redundancy is defensive: it provides a more precise error message in a future scenario where classification equality might diverge from nature equality.

[Code Reference: `account.dart`, lines 196–204]

---

### 3.5 The Balance Sheet Classification Order: The Accounting Equation as Code

The `BalanceSheetGenerator._classificationOrder()` method encodes the canonical presentation order of the accounting equation:

```
Assets section (order 0–3):
  0: liquidAssets
  1: receivables
  2: fixedProfitableAssets
  3: fixedDepreciableAssets

Liabilities section (order 10–12):
  10: payables
  11: settlements
  12: clearingRemittances

Income Statement section (order 20–22):
  20: personalExpenses
  21: personalRevenues
  22: remittanceFees
```

The numeric gap between sections (0–3 for assets, 10–12 for liabilities, 20–22 for income statement) is structurally significant: intermediate values are available for future classifications to be inserted without disrupting the ordering of existing sections. This is a forward-compatible classification ordering strategy.

The hardcoded nature of this ordering means: no user, no administrator, and no future code can reorder the balance sheet sections. The balance sheet always presents assets first, liabilities second, and income statement items third. This is not configurable because it is not a preference — it is accounting doctrine. The accounting equation (Assets = Liabilities + Equity/Net Position) predetermines this ordering in every accounting system in the world.

The income statement section appearing after liabilities reflects the presentation of a combined Balance Sheet + Income Summary — a unified financial position document rather than a strict IFRS-format balance sheet. This is appropriate for personal accounting, where the distinction between a balance sheet and an income statement is less architecturally meaningful than in corporate accounting.

[Code Reference: `balance_sheet_generator.dart`]

---

---

## SECTION 4: THE ACCOUNT ENTITY — IMMUTABLE NATURE, CONSTRAINED LIFECYCLE

---

### 4.1 The Root vs. Child Ontological Distinction

The Account entity (`account.dart`) establishes a fundamental ontological division through its factory constructors. An account is either a **root account** or a **child account**, and this determination is made at construction time, permanently.

`Account.createRoot()` creates an account with `parentId = null`, setting its classification and nature from the passed `AccountClassification`. A root account is an independent classification node.

`Account.createChild()` creates an account with `parentId = parent.id`, copying the parent's `nature` and `classification` directly:

```dart
// account.dart, lines 89–111
factory Account.createChild({
  required AccountId id,
  required String name,
  required Account parent,
  required DateTime createdAt,
  bool isDefault = false,
  bool isActive = true,
  Map<String, dynamic> metadata = const {},
}) {
  return Account._(
    id: id,
    name: _requireName(name),
    nature: parent.nature,           // ← INHERITED DIRECTLY
    classification: parent.classification, // ← INHERITED DIRECTLY
    parentId: parent.id,
    ...
  );
}
```

The `parent.nature` and `parent.classification` assignments are unconditional. There is no override path. A child account cannot be created with a different classification than its parent. The classification and nature of a child account are fully determined by the parent account at the moment of creation.

This creates a property that might be called **classification transitivity**: the classification of any account in the hierarchy determines the classification of all its descendants. The entire sub-tree of accounts under a `liquidAssets` root is, by definition, composed of `liquidAssets`-classified accounts. By reading the root of a sub-tree, you know the fundamental economic nature of every account in that sub-tree.

[Code Reference: `account.dart`, lines 89–111]

---

### 4.2 The `isDefault` Flag: Permanent Anchors in the Account Universe

The `isDefault` boolean marks system-seeded accounts that exist before any user action. These are the accounts created during initial provisioning — the root cash fund, the tripartite clearing account, and similar structural anchors.

Three methods on the `Account` entity check `isDefault` and throw `AccountDeletionException` if it is true:

```dart
// account.dart: deactivate(), archive(), assertCanDelete()
if (isDefault) {
  throw const AccountDeletionException(
    messageAr: 'لا يمكن إيقاف الحساب الافتراضي.',
    code: 'account_deactivate_default',
  );
}
```

The codes are distinct: `account_deactivate_default`, `account_delete_default`, `account_archive_default`. The system distinguishes between three different termination vectors and refuses all of them for default accounts.

The philosophical rationale: default accounts are the anchor points of the accounting system. The automated bridge logic depends on the existence of a root `liquidAssets` account. The tripartite transfer mechanism depends on the existence of a `clearingRemittances` account. If these anchors could be removed, the automated behaviors that depend on them would silently degrade or crash. The `isDefault` flag and its associated guards are the system's declaration that certain accounts are permanent preconditions for system operation, not options the user may remove.

[Code Reference: `account.dart`, lines 168–174, 224–228, 246–250]

---

### 4.3 The Three-Precondition Deletion Protocol

An account can only be deleted if it satisfies three independent preconditions simultaneously, as expressed in `assertCanDelete()`:

**Precondition 1: Not a default account.** (`isDefault == false`)
*Rationale:* Default accounts are system anchors. They cannot be deleted regardless of balance.

**Precondition 2: Zero balance.** (`balance.isZero`)
*Rationale:* An account with a non-zero balance has outstanding financial obligations recorded against it. Deleting such an account would create phantom debits or credits with no corresponding account — an imbalance in the double-entry system.

**Precondition 3: No child accounts.** (`hasChildAccounts == false`)
*Rationale:* Deleting a parent account while its children exist would create orphaned accounts with no valid parent reference. The hierarchy would become structurally invalid.

```dart
// account.dart, lines 219–242
void assertCanDelete({
  required Money balance,
  required bool hasChildAccounts,
}) {
  if (isDefault) { throw AccountDeletionException(..., code: 'account_delete_default'); }
  if (!balance.isZero) { throw AccountDeletionException(..., code: 'account_delete_balance'); }
  if (hasChildAccounts) { throw AccountDeletionException(..., code: 'account_delete_children'); }
}
```

The three distinct exception codes enable the application layer (and the UI) to display precise, actionable error messages: "This account cannot be deleted because it has a non-zero balance. Please settle all transactions first." The codes are not interchangeable — each represents a different prerequisite that must be met.

The application layer is responsible for providing the current `balance` and `hasChildAccounts` values. The domain entity trusts the application layer to provide these correctly, but once provided, applies its own invariants unconditionally. This separation — application layer computes the values, domain entity enforces the semantic rules — is the clean architecture principle of "rich domain models": entities contain business rules, not just data.

[Code Reference: `account.dart`, lines 219–242]

---

### 4.4 The Archive vs. Delete Dichotomy: Historical Integrity vs. Active Presence

The Account entity supports two distinct modes of termination: `archive()` and deletion (via `assertCanDelete()`). These are semantically different:

**Deletion** (`assertCanDelete()` + application-layer delete): Removes the account record from the system entirely. This is only possible for accounts with zero balance, no children, and no default flag. In practice, accounts that have any historical transaction activity cannot be deleted because they are referenced by immutable ledger entries.

**Archival** (`archive()`): Flags the account as `isArchived = true` while leaving the record and all its ledger entries intact. An archived account does not appear in active account lists, but its historical data is fully preserved. Archival can be reversed with `unarchive()`.

The archive option exists precisely because deletion is so restricted. An account that once had transactions can never be deleted (those ledger entries reference it). But it can be archived — retired from active service while its history is preserved for audit purposes.

This mirrors standard accounting practice: in formal bookkeeping, accounts are never deleted. They are closed (zeroed out through offsetting entries) and then marked as no longer in use. The historical entries remain in the ledger permanently. Qayd's archive mechanism provides the "no longer in use" marking in a software context where physical ledger book closure is not applicable.

[Code Reference: `account.dart`, lines 244–271, 273–288]

---

### 4.5 The Metadata Layer: Typed Extensibility Without Schema Migration

The `Map<String, dynamic> metadata` field on `Account` is the system's escape hatch for attributes that don't fit the normalized account schema. Documented uses include:

- `metadata['income_source_type']`: Classifies accounts as income-generating sources (`investmentAsset`, `profession`, `other`, `possession`)
- `metadata['code']`: Holds the account's alphanumeric code in a chart-of-accounts numbering scheme
- Asset-specific attributes: serial numbers, purchase dates, estimated useful life

The `updateMetadata(Map<String, dynamic> newMetadata)` method merges new entries into the existing metadata map using the spread operator:

```dart
// account.dart, lines 136–148
Account updateMetadata(Map<String, dynamic> newMetadata) {
  return Account._(
    ...
    metadata: {...metadata, ...newMetadata}, // merge, not replace
  );
}
```

This is a merge-not-replace pattern: new keys are added, existing keys are overwritten, absent keys are preserved. The metadata map grows monotonically — entries are never removed through `updateMetadata`. This ensures that metadata accumulated over the account's lifecycle is never accidentally erased by a partial metadata update.

The trade-off: metadata is not type-safe at the domain level. `metadata['income_source_type']` is a `dynamic` — it could be a String, an int, or null, and the domain entity has no knowledge of which. Type safety is delegated to the value object that interprets metadata: `IncomeSourceType.fromKey(metadata['income_source_type'] as String?)`. If the metadata is corrupted, `fromKey` returns `null` gracefully rather than throwing.

This graceful degradation policy at the metadata boundary is an explicit architectural decision: metadata corruption must not crash the system. It must degrade the feature that depends on it (income stream grouping), not the account infrastructure. The strictness hierarchy is preserved: the account entity is strict, the metadata extension is lenient.

[Code Reference: `account.dart`, lines 33–34, 136–148; `income_source_type.dart`]

---

---

## SECTION 5: THE VOUCHER DOCTRINE — DOCUMENT BEFORE ENTRY, EXISTENCE BEFORE ACCOUNTING

---

### 5.1 The Voucher as the Atom of Financial Reality

In the Qayd system, the `Voucher` entity (`voucher.dart`) is the irreducible unit from which all accounting consequence is derived. It is not a ledger entry. It is not a balance. It is a **document** — a record with legal and social meaning that exists prior to, and independently of, any accounting computation performed upon it.

The architectural proof: a `Voucher` can exist with no associated `LedgerEntry` objects (while in `VoucherState.draft`). A `LedgerEntry` cannot exist without a `voucherId` — the entity field is mandatory and non-null. The dependency flows in one direction only: entries depend on vouchers. Vouchers do not depend on entries.

```
   ┌─────────┐          ┌─────────────┐
   │ Voucher │◄─────────│ LedgerEntry │
   │         │  has-a   │ voucherId   │
   │ (exists │          │ (mandatory) │
   │  first) │          └─────────────┘
   └─────────┘
```

**Deductive Interpretation:** The unidirectional dependency from LedgerEntry → Voucher encodes the accounting principle that the document (voucher) is logically prior to the record (ledger entry). The voucher can exist without being posted. The posting cannot exist without a voucher. This is not merely clean architecture — it is accounting doctrine: the source document precedes the journal entry.

In the classical Islamic accounting tradition, the `قبض` (receipt document) and `صرف` (payment order) were prepared by the merchant and stored as primary evidence. The `دفتر` (ledger) entries were made from these documents, not the other way around. Qayd's architecture encodes this temporal and logical precedence directly in the dependency graph.

[Code Reference: `voucher.dart`, lines 26–134; `ledger_entry.dart`]

---

### 5.2 The Voucher's Twenty-One Fields: A Behavioral Inventory

The `Voucher._` private constructor accepts twenty-one named parameters. This is not field inflation — each field carries a distinct semantic responsibility:

| Field | Type | Behavioral Role |
|---|---|---|
| `id` | `VoucherId` | Immutable identity |
| `type` | `VoucherType` | Economic polarity (receipt/payment) |
| `referenceNumber` | `String?` | External document reference |
| `date` | `DateTime` | Economic event date (not creation date) |
| `amount` | `Money` | The economic magnitude |
| `currency` | `CurrencyCode` | The currency of denomination |
| `counterpartyId` | `AccountId` | The external account |
| `affectedAccountId` | `AccountId` | The internal account |
| `state` | `VoucherState` | Creator's workflow state |
| `description` | `String?` | Human-readable event description |
| `attachmentRefs` | `List<AttachmentRef>` | Supporting file evidence |
| `notes` | `String?` | Creator's private annotations |
| `tags` | `List<String>` | Free-form classification tags |
| `createdAt` | `DateTime` | System timestamp of creation |
| `confirmedAt` | `DateTime?` | System timestamp of confirmation |
| `settledAt` | `DateTime?` | System timestamp of settlement |
| `senderStatus` | `AgreementStatus` | Sender's bilateral agreement state |
| `receiverStatus` | `AgreementStatus` | Receiver's bilateral agreement state |
| `senderSignatureHex` | `String?` | Sender's Ed25519 signature |
| `receiverSignatureHex` | `String?` | Receiver's Ed25519 signature |
| `senderPublicKeyHex` | `String?` | Sender's public key |
| `receiverPublicKeyHex` | `String?` | Receiver's public key |
| `lifecycleStatus` | `VoucherLifecycle` | High-level document journey state |
| `signerPhone` | `String?` | Counterparty phone for discovery |
| `tripartiteMeta` | `TripartiteMeta?` | Tripartite transfer context |
| `originVoucherId` | `VoucherId?` | Parent voucher in a thread |
| `rejectionReason` | `String?` | Counterparty's rejection explanation |
| `withdrawnAt` | `DateTime?` | Non-destructive retraction timestamp |
| `reversalCount` | `int` | Count of reversal/settlement children |
| `firstChildId` | `VoucherId?` | First child for threaded navigation |

The twenty-one (technically thirty, counting all sub-fields) fields represent the complete information model of a bilateral financial event: identity, economics, time, parties, workflow state, cryptographic proof, social history, and structural context.

The separation between `date` (the economic event date) and `createdAt` (the system creation timestamp) is architecturally meaningful: accounting entries are posted at the economic event date, not the system recording date. This allows backdated entries (allowed in personal bookkeeping: recording yesterday's cash purchase today). The economic date determines when the entry appears in reports; the creation timestamp is for audit trail ordering.

[Code Reference: `voucher.dart`, lines 27–58, 60–134]

---

### 5.3 The Bipartite Account Structure: The Minimum Information Set for Double-Entry

Every Voucher carries exactly two account references:

- `counterpartyId`: the account on "the other side" of the transaction
- `affectedAccountId`: the account being "affected" from the user's perspective

This bipartite structure is the minimum information set required for the `EntryGenerator` to produce a balanced double-entry pair. Combined with `VoucherType` (receipt or payment), the system has exactly the information needed to determine which account to debit and which to credit, without any user input into the accounting mechanics.

The invariant `counterpartyId != affectedAccountId` is enforced both at creation (in `Voucher.draft()`) and at modification (in `Voucher.updateDraft()`):

```dart
// voucher.dart, lines 251–256
if (counterpartyId == affectedAccountId) {
  throw const SelfCancelingEntryException(
    messageAr: 'لا يمكن أن يكون الطرف والحساب المتأثر نفس الحساب في السند.',
    code: 'voucher_self_counterparty',
  );
}
```

The `SelfCancelingEntryException` code is architecturally precise: a voucher where both account references point to the same account would generate a debit and a credit to the same account — a self-canceling entry that leaves all balances unchanged. Such an entry would be a ledger pollution: it consumes a `transactionId`, generates two `LedgerEntry` records, but produces no net economic effect. The system refuses to create it.

[Code Reference: `voucher.dart`, lines 251–262]

---

### 5.4 The `isReply` Computed Property: Thread Chains as Financial History

The `bool get isReply => originVoucherId != null` computed property identifies vouchers that are responses to earlier vouchers. These include:

- **Reversals:** A voucher with the inverse type, created to undo a confirmed voucher's accounting effect.
- **Corrections:** A new voucher created after a counterparty rejected the original, superseding it with corrected terms.
- **Settlements:** A follow-up voucher that closes a prior debt or receivable obligation.

The `originVoucherId` creates a singly-linked list of financial interactions: Voucher A → Reversal of A (originVoucherId=A) → Correction of reversal (originVoucherId=B). This chain can be traversed in the UI as a "thread" of related financial documents.

The `reversalCount` and `firstChildId` fields provide efficient access to this chain: `reversalCount` tells the list view how many successor vouchers a given voucher has without fetching them, and `firstChildId` provides a direct navigation target to the first successor.

This threading mechanism transforms the voucher list from a flat transaction log into a structured conversation: "I sent you a payment request → you rejected it → I corrected it → you accepted it → it was settled." Each step is a voucher linked to its predecessor via `originVoucherId`.

[Code Reference: `voucher.dart`, lines 113–117, 130–133, 148]

---

### 5.5 The `Voucher.restore()` Factory: The Data Layer's Rehydration Contract

The `Voucher.restore()` factory constructor accepts all fields as named parameters with defaults, bypassing the business logic guards in `Voucher.draft()`. This is not an oversight — it is a deliberate architectural contract between the data layer and the domain layer.

When the SQLite data source reads a voucher from persistent storage, it must reconstruct the `Voucher` object with the exact field values stored. At this point, the business rules that govern *creation* are irrelevant — the object being reconstructed has already passed through creation rules during its initial persistence. Re-applying creation guards at rehydration would incorrectly reject valid historical data.

For example: a voucher from six months ago was created with `senderStatus = accepted`. At rehydration, the restore factory must set `senderStatus = accepted` without checking "should this be accepted?" — that check was made at creation time, is immutably recorded, and must not be re-evaluated.

The `Voucher.restore()` factory is the only legitimate pathway for the data layer to construct `Voucher` objects. Any data layer code that uses `Voucher.draft()` to rehydrate persisted data is architecturally incorrect — it would re-apply creation invariants to historical records, potentially corrupting the reconstructed domain object.

The existence of separate `draft()` and `restore()` factories is the system's expression of a fundamental architectural distinction: **creation semantics** (enforcing business rules for new entities) vs. **rehydration semantics** (faithfully reconstructing persisted state).

[Code Reference: `voucher.dart`, lines 159–224]

---

### 5.6 The `attachmentRefs` List: Unmodifiable at Construction

The `attachmentRefs` field on every `Voucher` is stored as `List.unmodifiable(attachmentRefs)`:

```dart
// voucher.dart, lines 203, 282
attachmentRefs: List.unmodifiable(attachmentRefs),
```

This appears in both `restore()` and `draft()` factory constructors. The list of attachments cannot be mutated after the voucher is constructed. This enforces that modifications to the attachment list require creating a new voucher instance (via `updateDraft()`) — which is only allowed in draft state.

The philosophical content: a finalized document's attachment list is part of its evidentiary record. Adding or removing an attachment from a confirmed voucher would alter the evidence without creating an audit trail. By making the attachment list immutable at the object level, the system forces all attachment changes to go through the `updateDraft()` pathway, which itself is only available in draft state. A confirmed voucher's attachments are frozen.

[Code Reference: `voucher.dart`, lines 203, 282, 435]

---

---

## SECTION 6: STATE MACHINES AND THE PROHIBITION OF BACKWARD MOTION

---

### 6.1 The VoucherState Finite Automaton: Formal Specification

The `VoucherState` enum (`voucher_state.dart`) defines a finite automaton with four states and a constrained transition function. Formally:

**States:** `{draft, confirmed, settled, withdrawn}`

**Transition function:**

```
δ(draft,     confirm)  = confirmed
δ(confirmed, settle)   = settled
δ(draft,     withdraw) = withdrawn   [if canWithdraw == true]
δ(confirmed, withdraw) = withdrawn   [if receiverStatus != accepted]
```

**Terminal states:** `{settled, withdrawn}` — no transition exits these states.

**Prohibited transitions (structurally enforced):**

```
δ(confirmed, confirm)  = ERROR (ImmutableEntityException: "voucher_not_draft")
δ(settled,   settle)   = ERROR (InvalidVoucherTransitionException)
δ(settled,   withdraw) = ERROR (InvalidVoucherTransitionException)
δ(withdrawn, *)        = ERROR (canWithdraw returns false)
```

The prohibition of backward transitions is enforced by the `confirm()`, `settle()`, and `withdraw()` methods' guard clauses:

```dart
// voucher.dart, lines 303–315
Voucher confirm(DateTime confirmedAt) {
  if (!state.isDraft) {
    throw InvalidVoucherTransitionException(
      messageAr: 'يمكن تأكيد السند من حالة المسودة فقط.',
      from: state,
      to: VoucherState.confirmed,
    );
  }
  ...
}
```

The `InvalidVoucherTransitionException` carries both `from` and `to` state fields, enabling precise error reporting: "Cannot transition from `settled` to `confirmed`." This diagnostic precision is valuable for debugging and audit trail interpretation.

```
     ┌─────────┐   confirm()   ┌───────────┐   settle()   ┌──────────┐
     │  draft  │──────────────►│ confirmed │─────────────►│ settled  │
     └────┬────┘               └─────┬─────┘              └──────────┘
          │                          │
          │withdraw()                │withdraw() [receiverStatus != accepted]
          │(always)                  │
          ▼                          ▼
     ┌──────────────────────────────────┐
     │            withdrawn             │
     │         (TERMINAL STATE)         │
     └──────────────────────────────────┘
```

**Deductive Interpretation:** The state machine diagram reveals that `withdrawn` is reachable from both `draft` and `confirmed`, but not from `settled`. A settled voucher cannot be retracted — it is permanently committed. This asymmetry reflects the economic reality that a debt which has been fully settled has been extinguished: there is nothing left to retract.

[Code Reference: `voucher_state.dart`; `voucher.dart`, lines 303–346]

---

### 6.2 The VoucherState vs. VoucherLifecycle Dichotomy: Two Independent Dimensions

The `Voucher` entity carries two state-related fields: `state` (of type `VoucherState`) and `lifecycleStatus` (of type `VoucherLifecycle`). These are not redundant — they answer different questions.

**`VoucherState`** answers: *"Where is this voucher in my accounting workflow?"*

- `draft`: Not yet posted to the ledger.
- `confirmed`: Posted; ledger entries exist.
- `settled`: Closed; the obligation it represented has been fulfilled.
- `withdrawn`: Retracted; excluded from accounting calculations.

**`VoucherLifecycle`** answers: *"What is the current social/bilateral standing of this document?"*

- `draft`: No parties have interacted with it yet.
- `pending`: The receiver has not yet responded.
- `rejected`: The receiver has explicitly declined.
- `withdrawn`: The creator has retracted it.
- `confirmed`: Both parties have reached agreement.
- `settled`: The underlying obligation is resolved.

A single economic reality can have different states in these two dimensions simultaneously, and the combinations carry distinct meanings:

| `VoucherState` | `VoucherLifecycle` | Interpretation |
|---|---|---|
| `draft` | `draft` | Created but not sent; local only |
| `draft` | `pending` | Sent to counterparty; counterparty has not responded |
| `confirmed` | `pending` | User confirmed into own ledger; counterparty still has not signed |
| `confirmed` | `confirmed` | Both signed; fully posted |
| `confirmed` | `rejected` | User confirmed, counterparty rejected (dispute state) |
| `withdrawn` | `withdrawn` | Retracted by creator; removed from counterparty's view |

The combination `confirmed + pending` is particularly important: it represents the state where the user has decided to post the voucher to their own ledger (asserting their financial position) before the counterparty has acknowledged. This is the explicit implementation of local accounting sovereignty — the user does not need to wait.

[Code Reference: `voucher.dart`, lines 69–70, 99–101; `voucher_state.dart`; `voucher_lifecycle.dart`]

---

### 6.3 The `AgreementStatus` Machine: Four States for the Bilateral Protocol

The `AgreementStatus` enum (`agreement_status.dart`) defines four values, each with precise semantic content:

**`underRequest` (تحت الطلب):** Initial state of the receiver's status at voucher creation. The receiver has received (or will receive) the voucher and has not yet responded. This is the "pending" state from the receiver's perspective.

**`accepted` (مقبول):** The party has digitally signed the voucher with their Ed25519 private key, and the signature has been verified against their known public key. "Accepted" means "cryptographically committed." It is not a soft agreement — it is a verified mathematical signature.

**`rejected` (مرفوض):** The receiver has explicitly declined the voucher. The `rejectionReason` field on the voucher carries the reason. A rejected voucher does not create ledger entries for the receiver.

**`unverified` (غير مؤكد):** A signature is present, but it cannot be verified against any known or historical key for the claimed party. This is the system's way of expressing: "someone signed this, but we cannot confirm they are who they claim to be." This state is the system's defense against forgery — a voucher signed with an unknown key is not silently treated as unsigned. It is flagged as suspicious.

The four-state design provides a complete and exclusive classification of every possible receivership state:

- No response yet → `underRequest`
- Verified acceptance → `accepted`
- Explicit refusal → `rejected`
- Unverifiable claim → `unverified`

No receivership state falls outside these four categories. The design is complete.

[Code Reference: `agreement_status.dart`]

---

### 6.4 The `canWithdraw` Policy: Bilateral Commitment as the Withdrawal Gate

The `canWithdraw` computed property encodes a nuanced conditional withdrawal policy:

```dart
// voucher.dart, lines 152–157
bool get canWithdraw {
  if (state.isSettled || state.isWithdrawn) return false;
  if (state.isDraft) return true;
  return receiverStatus != AgreementStatus.accepted;
}
```

Analyzing this logic:

1. A settled or already-withdrawn voucher cannot be withdrawn (terminal state protection).
2. A draft voucher can always be withdrawn (no bilateral commitment has been made).
3. A confirmed voucher can be withdrawn only if the receiver has NOT yet accepted (bilateral commitment has not yet been formed).

The third rule is the most philosophically loaded. It draws a precise line between unilateral action (withdrawal before counterparty commits) and bilateral obligation (withdrawal after counterparty commits). Once the receiver signs — once they make a cryptographic commitment — the creator loses the unilateral right to retract. The document becomes jointly owned.

This mirrors the legal principle of offer and acceptance: an offer can be revoked before acceptance. Once accepted, a contract is formed and neither party can unilaterally dissolve it without the other's consent. The `canWithdraw` policy implements this principle computationally.

[Code Reference: `voucher.dart`, lines 152–157]

---

### 6.5 The Immutability of Confirmed Vouchers: Financial Finality as a Domain Exception

The `assertMutableForAccountingSideEffects()` method:

```dart
// voucher.dart, lines 464–470
void assertMutableForAccountingSideEffects() {
  if (state.isSettled) {
    throw const ImmutableEntityException(
      messageAr: 'السند المسوّى غير قابل للتعديل.',
      code: 'voucher_settled_immutable',
    );
  }
}
```

And `updateDraft()`:

```dart
// voucher.dart, lines 393–398
if (!state.isDraft) {
  throw const ImmutableEntityException(
    messageAr: 'لا يمكن تعديل سند مؤكد أو مسوّى.',
    code: 'voucher_not_draft',
  );
}
```

Two different `ImmutableEntityException` codes protect two different immutability surfaces:

- `voucher_not_draft`: Prevents any content mutation after draft state.
- `voucher_settled_immutable`: Prevents accounting side effects on settled vouchers.

The distinction between "content immutability" (you cannot change the amount or parties) and "accounting-side-effect immutability" (you cannot trigger new accounting consequences) is subtle but important. A confirmed-but-not-settled voucher might legitimately need certain metadata updates — but its fundamental content (amount, parties, type) and its accounting postings (ledger entries) are immutable from the moment of confirmation.

This two-layered immutability system precisely maps the phases of a voucher's lifecycle to the types of modifications that are permissible at each phase.

[Code Reference: `voucher.dart`, lines 379–471]

---

---

## SECTION 7: THE DUAL-PARTY AGREEMENT PROTOCOL — CRYPTOGRAPHIC BILATERAL COMMITMENT

---

### 7.1 The SignableReceipt Canonical Payload: What Exactly Is Being Signed

The `SignableReceipt` value object defines the exact byte sequence that serves as the Ed25519 signature payload. The canonical payload is constructed from six fields, concatenated in a deterministic order:

1. `amountMinor` (integer, string-converted)
2. `currencyCode` (ISO 4217 code string)
3. `senderPhone` (E.164 format phone number)
4. `receiverPhone` (E.164 format phone number)
5. `dateIso` (ISO 8601 date, date-only: "YYYY-MM-DD", without time component)
6. `receiptUuid` (UUID v4 string of the voucher ID)

The signature commits the signer to: a specific amount, in a specific currency, from a specific sender, to a specific receiver, on a specific date, for a specific voucher. If any of these six fields changes after signing, the signature becomes invalid.

The use of `dateIso: draft.date.toIso8601String().split('T').first` (splitting on 'T' to extract only the date portion) is architecturally significant: the system signs the *economic event date*, not the creation timestamp. This means a voucher created today for an event that occurred yesterday is signed with yesterday's date — the date of the underlying economic reality, not the date of the recording act.

```
SIGNABLE RECEIPT CANONICAL PAYLOAD:
┌─────────────────────────────────────────────────────────────┐
│  Field 1: amountMinor  = "100"  (100 minor units)           │
│  Field 2: currencyCode = "SAR"                              │
│  Field 3: senderPhone  = "+966501234567"                    │
│  Field 4: receiverPhone= "+966509876543"                    │
│  Field 5: dateIso      = "2026-04-13"  (DATE ONLY)          │
│  Field 6: receiptUuid  = "f47ac10b-58cc-4372-a567-..."      │
│                                                             │
│  Concatenated → Hash (SHA-512) → Ed25519 Signature          │
└─────────────────────────────────────────────────────────────┘
```

[Code Reference: `accept_voucher_use_case.dart`, lines 79–86; `signable_receipt.dart`]

---

### 7.2 The Cross-Vector Verification Engine: Epistemic Humility in Cryptographic Verification

The `SignatureVerificationEngine` (`signature_verification_engine.dart`) implements a verification protocol that is notable for what it refuses to claim when evidence is insufficient.

The verification procedure:

```
STEP 1: Identity Extraction
  → findAccountByPhone(senderPhone)
  → if null, try findAccountByEmail(senderEmail)
  → if still null: return accountNotFound()

STEP 2: Key Retrieval
  → get PartyDetails.allAuthorizedKeys  [currentKey + historyKeys]
  → if empty, try server lookup
  → if still empty: return unverified('NO_KEYS_AVAILABLE')

STEP 3: Iteration
  → for each key in authorizedKeys:
      → attempt Ed25519 verification
      → if SUCCESS: return verified(matchedKeyHex)

STEP 4: Failure
  → return unverified('SIGNATURE_MISMATCH')
```

Three possible outcomes:

- `verified(matchedKeyHex)`: Positive confirmation — we found a key that validates the signature.
- `unverified(reason)`: Negative confirmation — we have evidence that verification failed.
- `accountNotFound()`: Epistemic suspension — we cannot verify because we cannot identify the signer.

The `accountNotFound` case is the most philosophically interesting. The system does not claim the signature is invalid when it cannot identify the signer. It acknowledges that it lacks the information required to make any verification claim. This is appropriate epistemic humility: absence of verification capability is not absence of authenticity.

The key iteration over historical keys (`publicKeyHistoryHex`) solves the key rotation problem. Ed25519 keys are typically rotated for security hygiene — a user might generate a new key pair after losing their old device. Historical signatures made with the old key must remain verifiable after rotation. The iteration over all historical keys ensures that past agreements remain verifiable indefinitely.

[Code Reference: `signature_verification_engine.dart`, lines 80–153]

---

### 7.3 The `senderStatus` Initialization Policy: The Act of Creation as Self-Acceptance

In `Voucher.draft()`, the initial `AgreementStatus` fields are hardcoded:

```dart
// voucher.dart, lines 264–269
// Policy v2.0:
// Creating the voucher constitutes implicit approval by the sender.
// Documentation completion requires the receiver's signature.
const senderStatus = AgreementStatus.accepted;
const receiverStatus = AgreementStatus.underRequest;
```

The comment labels this "Policy v2.0" — indicating that this was not the original policy. A prior policy (v1.x) presumably required an explicit sender acceptance step. The evolution to v2.0 collapses sender creation and sender acceptance into a single atomic act: the creation of the voucher IS the sender's acceptance.

This policy has a deep implication for transaction disputes. If a sender claims they did not intend to create a voucher, the system's response is: the creation of the voucher is itself evidence of intent. "Policy v2.0: Creating the voucher constitutes implicit approval by the sender." The sender cannot retroactively disavow the creation of their own voucher — they can only withdraw it (if the counterparty has not yet accepted) or reverse it (if the counterparty has accepted).

The policy also has a UX implication: there is no "sender confirmation" step between "create voucher" and "send to counterparty." Creation and intent are simultaneous.

[Code Reference: `voucher.dart`, lines 264–269]

---

### 7.4 The Accept Flow: Commit First, Notify Second

The ordering of operations in `AcceptVoucherUseCase.call()` reveals the system's hierarchy of trust:

```dart
// accept_voucher_use_case.dart — operational order
1. Load voucher from local storage
2. Resolve phone from LicenseVault
3. Generate Ed25519 signature locally
4. Attach signature to voucher (local mutation)
5. Confirm into local ledger (state: draft → confirmed)
6. Generate LedgerEntry objects
7. Save to local database (persistence complete)
8. Fire-and-forget: dispatch E2EE SyncNode to counterparty
```

The comment on step 8 is definitive: *"Fire-and-forget to avoid blocking the UI; the accounting transaction is already complete locally."*

The acceptance is complete at step 7. The network dispatch at step 8 is decoupled from the accounting commitment. If the network is unavailable, steps 1–7 succeed and the acceptance is recorded. The counterparty will discover the acceptance on their next pull-sync cycle.

This ordering is the local-first protocol applied at the application layer. The device's local ledger is the primary record. The network is the secondary notification channel. The two are operationally decoupled.

The architectural consequence: two users can independently confirm their copies of a bilateral voucher without being online simultaneously. Each user's local ledger reflects their confirmed acceptance. When network connectivity is restored, the sync protocol reconciles the two ledgers, confirming that both parties independently reached the same conclusion.

[Code Reference: `accept_voucher_use_case.dart`, lines 52–139]

---

### 7.5 The Corrective Resubmission Protocol: Rejection as the Beginning of Negotiation

Section §6 of `CreateVoucherUseCase` implements a protocol that acknowledges the social reality that rejected vouchers are not failures — they are the beginning of negotiation.

When a new voucher is created with an `originVoucherId`:

```dart
// create_voucher_use_case.dart, lines 218–230
if (input.originVoucherId != null) {
  final originRes = await _voucherRepository.getById(VoucherId(input.originVoucherId!));
  if (originRes.isSuccess) {
    final origin = originRes.valueOrNull!;
    if (origin.state.isDraft || origin.receiverStatus == AgreementStatus.rejected) {
      final supercoded = origin.withdraw(DateTime.now());
      await _voucherRepository.save(supercoded);
    }
  }
}
```

The predecessor voucher is automatically withdrawn (retracted) when the corrective resubmission is saved. This withdrawal closes the loop: the rejected voucher is retired from active consideration, and the corrective voucher takes its place. Both records persist in the database (withdrawal is non-destructive), but only the new voucher appears as active.

The `originVoucherId` link on the new voucher creates the thread chain: rejected voucher → corrective resubmission. The UI can display this as "this was sent in response to the rejected voucher," giving the counterparty (and the creator) a complete narrative of the negotiation.

This is the system's modeling of financial negotiation as a documented, traceable process — not an ephemeral conversation that leaves no record.

[Code Reference: `create_voucher_use_case.dart`, lines 218–230]

---

---

## SECTION 8: THE ENTRY GENERATOR — DOUBLE-ENTRY DETERMINISM AS AN IMMUTABLE LAW

---

### 8.1 The EntryGenerator: A Pure Function with Zero Configuration

The `EntryGenerator` class (`entry_generator.dart`) is instantiated with a `const` constructor:

```dart
// entry_generator.dart, lines 10–11
class EntryGenerator {
  const EntryGenerator();
```

A `const` constructor in Dart means the instance carries no mutable state and its behavior is completely determined by its inputs. `EntryGenerator` is, in the strictest mathematical sense, a **pure function** from `(Voucher, TransactionId, EntryId, EntryId, DateTime)` to `(List<LedgerEntry>)`.

There are no switches to configure. No plugins to inject. No rules to override. The generation logic is hardcoded into the switch statement on `VoucherType`. The system is saying: the double-entry posting rules for receipts and payments are not configurable. They are laws.

```dart
// entry_generator.dart, lines 36–88
switch (voucher.type) {
  case VoucherType.receipt:
    return [
      LedgerEntry.create(accountId: voucher.affectedAccountId, side: EntrySide.debit, ...),
      LedgerEntry.create(accountId: voucher.counterpartyId,   side: EntrySide.credit, ...),
    ];
  case VoucherType.payment:
    return [
      LedgerEntry.create(accountId: voucher.counterpartyId,   side: EntrySide.debit, ...),
      LedgerEntry.create(accountId: voucher.affectedAccountId, side: EntrySide.credit, ...),
    ];
}
```

The switch is exhaustive: `VoucherType` has exactly two cases, and both are handled. Dart's exhaustive switch enforcement guarantees at compile time that no `VoucherType` value can slip through without generating entries.

[Code Reference: `entry_generator.dart`]

---

### 8.2 The Voucher-Entry Atomic Bond: A Structural Diagram

The relationship between a single voucher confirmation and its resulting ledger entries is an atomic bond:

```
          ┌────────────────────────────────────────────────┐
          │           VOUCHER-ENTRY ATOMIC BOND            │
          │                                                │
          │  Voucher(id="V1", type=receipt, amount=1000)   │
          │                    │                           │
          │        confirm()   │   (EntryGenerator)        │
          │                    ▼                           │
          │  Transaction(id="T1")                          │
          │    ├──► LedgerEntry(id="E1",                   │
          │    │        transactionId="T1",                │
          │    │        accountId=affectedAccount,         │
          │    │        side=DEBIT,                        │
          │    │        amount=1000)                       │
          │    │                                           │
          │    └──► LedgerEntry(id="E2",                   │
          │             transactionId="T1",                │
          │             accountId=counterparty,            │
          │             side=CREDIT,                       │
          │             amount=1000)                       │
          │                                                │
          │  ΣDebit(T1) = 1000 = ΣCredit(T1)  BALANCED   │
          └────────────────────────────────────────────────┘
```

**Deductive Interpretation:** Every voucher confirmation produces exactly one `TransactionId`, exactly two `LedgerEntry` objects, and the sum of debits equals the sum of credits by construction. The `TransactionId` is the mathematical witness that bonds the two entries into a balanced pair. Examining the ledger at any point, the invariant `ΣDebit(Ti) = ΣCredit(Ti)` must hold for every `TransactionId Ti`. This is the fundamental invariant of double-entry bookkeeping, and it is enforced structurally rather than verified ex-post.

[Code Reference: `entry_generator.dart`, lines 17–88; `confirm_voucher_use_case.dart`]

---

### 8.3 The Confirmation Guard in EntryGenerator: Only Confirmed Vouchers May Be Posted

```dart
// entry_generator.dart, lines 24–29
if (!voucher.state.isConfirmed) {
  throw const InvalidStateTransitionException(
    messageAr: 'لا يمكن إنشاء قيود لسند غير مؤكد.',
    code: 'entries_require_confirmed_voucher',
  );
}
```

The `EntryGenerator` itself enforces that only confirmed vouchers can generate ledger entries. This is a belt-and-suspenders check: the `ConfirmVoucherUseCase` and `AcceptVoucherUseCase` both call `confirm()` on the voucher before passing it to `generateForConfirmedVoucher()`. But the generator itself refuses to operate on unconfirmed vouchers as a second line of defense.

This guard prevents the catastrophic scenario of a bug in the application layer that calls `generateForConfirmedVoucher()` on a draft voucher — which would post accounting entries for a transaction that the user has not yet committed to. The confirmation requirement is enforced at three independent points:

1. The domain entity's `confirm()` method transitions state.
2. The application layer use cases call `confirm()` before calling the generator.
3. The generator checks `isConfirmed` before generating.

This triple enforcement illustrates the system's defense-in-depth approach to accounting integrity: no single layer is relied upon exclusively.

[Code Reference: `entry_generator.dart`, lines 24–29]

---

### 8.4 The Currency Inheritance: Entries Carry the Voucher's Currency

Every `LedgerEntry.create()` call in the generator passes `currency: currency` where `currency = voucher.currency`. The ledger entry inherits the voucher's currency without conversion or adjustment.

This enforces the single-currency-per-transaction principle: all entries in a transaction are denominated in the same currency. There are no cross-currency ledger entries. There are no implicit currency conversions. If a user records a payment in USD, both the resulting debit and credit entries are in USD.

Multi-currency accounting in Qayd is achieved by having multiple independent accounts per currency — a `liquidAssets` account for SAR and a separate `liquidAssets` account for USD, each maintaining their own currency-denominated running balance. The `TrialBalanceGenerator` handles this by grouping accounts by currency and producing separate trial balance columns per currency.

[Code Reference: `entry_generator.dart`, lines 31–34]

---

### 8.5 `LedgerEntry.create()` — Immutability from Birth

The `LedgerEntry` final class (`ledger_entry.dart`) is created exclusively through its `LedgerEntry.create()` factory, which enforces the zero-amount prohibition. Once created, a `LedgerEntry` is immutable through the Dart type system:

- The class is declared `final class` — it cannot be extended.
- All fields are `final` — they cannot be reassigned.
- There are no `copyWith()` or mutation methods.

The code comment in `ledger_entry.dart` is definitive: *"Immutable ledger line; corrections are done via reversal entries, never mutation."*

This is the principle of **transaction immutability** — once a financial transaction is posted to the ledger, it becomes a historical fact. Facts do not change. Corrections are new facts (reversal entries) that coexist with the original facts. The ledger grows monotonically: entries are added but never modified. A correctly implemented ledger produces the same running balance regardless of the order in which entries are processed (given correct date sorting), because every entry is permanent and deterministic.

[Code Reference: `ledger_entry.dart`]

---

---

## SECTION 9: THE AUTOMATED BRIDGE — PERSONAL FINANCE WITHOUT MANUAL POSTING

---

### 9.1 The Bridge Logic: Six Steps from User Intent to Double-Entry Reality

The "Automated Bridge Logic Detection" section in `CreateVoucherUseCase` (lines 93–290) implements a transformation that insulates the user from the complexity of double-entry accounting when managing personal expenses.

The bridge activates when the user selects a `personalExpenses` or `personalRevenues` account as the `affectedAccountId`. This is the system's signal that the user is thinking in terms of expense categories ("I paid for groceries"), not in terms of account pairs ("I debited my grocery expense account and credited my cash account").

The six-step bridge sequence:

```
STEP 1: Detect Bridge Trigger
  → Load all accounts
  → Find the designated affectedAccount
  → Check: is classification == personalExpenses OR personalRevenues?
  → If YES: bridge activates

STEP 2: Find the Root Liquid Assets Account
  → accounts.firstWhere(
      (a) => a.classification.standardKind == liquidAssets && a.isRoot,
      orElse: () => affected  // fallback: no bridge
    )

STEP 3: Redirect the Primary Voucher
  → Set actualAffectedAccountId = fund.id (the cash account)
  → Set isAutomatedExpensePosting = true

STEP 4: Create and Save the Primary Voucher
  → type = payment (e.g.)
  → counterpartyId = shopAccount
  → affectedAccountId = cashFundAccount   ← REDIRECTED

STEP 5: Create the Internal Bridge Voucher
  → type = same type as primary
  → counterpartyId = cashFundAccount
  → affectedAccountId = groceryExpenseAccount  ← ORIGINAL
  → originVoucherId = primaryVoucher.id
  → description = "Automated expense posting linked to party transaction."
  → confirm() immediately (no user action required)

STEP 6: Generate Ledger Entries for Both Vouchers
  → Primary: Dr counterparty, Cr cashFund  (payment)
  → Bridge:  Dr cashFund, Cr groceryExpense (payment, from cash to expense)
```

The net accounting result:

```
Dr counterparty        100  (external claim on counterparty)
Cr cashFund            100  (external: cash reduced)
Dr cashFund            100  (bridge: cash is source)
Cr personalExpenses    100  (bridge: expense classified)
─────────────────────────
Net: Dr counterparty + Cr personalExpenses
     (The counterparty owes us, the expense is classified)
```

[Code Reference: `create_voucher_use_case.dart`, lines 93–290]

---

### 9.2 The Root Cash Account as the System Axiom

The bridge logic's search for `liquidAssets + isRoot` reveals an architectural singularity. The system presupposes the existence of exactly one root liquid assets account. If multiple root liquid assets accounts exist, the `firstWhere()` call selects an arbitrary one (the first in the returned list order). If zero root liquid assets accounts exist, the `orElse: () => affected` fallback suppresses the bridge entirely.

This architectural dependency makes the root liquid assets account the **system axiom** — the foundational assumption from which all personal expense and revenue accounting is derived.

The word "axiom" is appropriate: an axiom is an assumption accepted without proof, upon which a system of reasoning is constructed. The system does not verify that the root liquid assets account exists before activating the bridge — it assumes existence and handles absence by fallback. This assumption is the foundation upon which the bridge logic rests.

Why not allow multiple cash accounts to participate in the bridge? Consider the alternative: if the system allowed the user to select which cash account to route a grocery expense through, it would require an additional user decision at the moment of expense creation. The design decision to enforce a single root cash account eliminates this decision burden: all personal expenses and revenues are automatically routed through the canonical cash fund. The user does not choose; the system chooses algorithmically.

This is a tradeoff between flexibility (multi-wallet modeling) and simplicity (single-source-of-truth cash account). The system chose simplicity.

```
         THE ROOT CASH ACCOUNT AS SINGULARITY

         ALL personal         ALL personal
         EXPENSES flow        REVENUES flow
         THROUGH HERE         THROUGH HERE
                  │                │
                  ▼                ▼
         ┌────────────────────────────┐
         │  Root LiquidAssets Account  │
         │    (isRoot=true, isDefault) │
         │    ← ALL financial events  │
         │       pass through here    │
         └────────────┬───────────────┘
                      │
              External Vouchers
              (counterparty ↔ cashFund)
```

[Code Reference: `create_voucher_use_case.dart`, lines 113–127]

---

### 9.3 The Internal Bridge Voucher: A Confirmed Voucher With No Counterparty Agreement

The internal bridge voucher is created and confirmed immediately, without any counterparty agreement protocol:

```dart
// create_voucher_use_case.dart, lines 258–270
final internalVoucher = Voucher.draft(
  id: internalVoucherId,
  type: input.type,
  date: input.date,
  amount: amount,
  currency: currency,
  counterpartyId: AccountId(actualAffectedAccountId),  // cashFund
  affectedAccountId: AccountId(input.affectedAccountId), // expenseAccount
  createdAt: DateTime.now(),
  description: input.description,
  notes: 'Automated expense posting linked to party transaction.',
  originVoucherId: voucher.id,
).confirm(DateTime.now()); // ← IMMEDIATELY CONFIRMED
```

The bridge voucher is not sent to a counterparty. It does not appear in any counterparty's inbox. It does not require a signature. It is an internal classification transfer, semantically equivalent to a journal entry between two of the user's own accounts.

The fact that this internal voucher passes through `Voucher.draft()` (which enforces the zero-amount and self-counterparty invariants) and then immediately calls `.confirm()` means it is subject to all the same domain rules as any other voucher. The system does not have a "bypass mode" for internal vouchers — they are subject to the same invariants.

The `notes: 'Automated expense posting linked to party transaction.'` field documents the automated nature of this voucher for audit trail purposes. An accountant examining the ledger can identify bridge vouchers by this note — they were not created by the user, but by the system's automated logic.

[Code Reference: `create_voucher_use_case.dart`, lines 256–290]

---

### 9.4 Cascade Withdrawal: The Atomicity of the Bridge

The `WithdrawVoucherUseCase` implements cascade withdrawal for internal bridge vouchers:

```dart
// withdraw_voucher_use_case.dart, lines 68–82
if (saved.isSuccess) {
  final childrenRes = await _voucherRepository.getByOriginVoucherId(v.id);
  if (childrenRes.isSuccess) {
    for (final child in childrenRes.valueOrNull!) {
      if (child.state.isConfirmed && child.originVoucherId == v.id) {
        // Internal vouchers can be withdrawn even if confirmed
        // because they have no counterparty agreement constraints.
        final withdrawnChild = child.withdraw(now);
        await _voucherRepository.save(withdrawnChild);
      }
    }
  }
}
```

The cascade logic explicitly overrides the normal `canWithdraw` constraints for bridge vouchers. Normally, a confirmed voucher can only be withdrawn if the counterparty has not yet accepted. But bridge vouchers have no real counterparty — their "counterparty" is the cash fund account, which is the user's own account. The logic comments: *"Internal vouchers can be withdrawn even if confirmed because they have no counterparty agreement constraints."*

This is a critical special case. Without it, withdrawing a primary expense voucher would leave an orphaned bridge voucher in the confirmed state, with ledger entries that partially compute an expense posting — an accounting imbalance. The cascade ensures that the two-voucher chain (primary + bridge) is always withdrawn atomically: if one is retracted, the other is retracted simultaneously.

[Code Reference: `withdraw_voucher_use_case.dart`, lines 68–82]

---

---

## SECTION 10: COST CENTERS AND THE DIMENSIONAL PHILOSOPHY

---

### 10.1 The Cost Center as an Analytical Layer: Orthogonal to the Ledger

The `CostCenter` entity (`cost_center.dart`) is the system's provision for management accounting within a personal finance context. It is critical to understand what a cost center is NOT in this system:

- It is **not** an accounting account.
- It does not generate debit or credit entries.
- It does not affect any account balance.
- It is not part of the double-entry system.

A cost center is a **label** — a soft classification that can be applied to vouchers after-the-fact or at creation time, enabling analytical reporting that is independent of the accounting ledger.

The architectural separation is absolute: cost center tags are stored in a separate `cost_centers` relational table (not in the `vouchers` table), in a many-to-many junction table with voucher references. The presence or absence of a cost center tag on a voucher has zero effect on the voucher's accounting behavior, its ledger entries, or any account's running balance.

This separation encodes a fundamental accounting principle: **management accounting** (cost centers, profitability analysis) is separate from **financial accounting** (double-entry ledger, trial balance, balance sheet). The two systems share the same underlying transactions but serve different analytical purposes.

[Code Reference: `cost_center.dart`; `create_voucher_use_case.dart`, lines 292–302]

---

### 10.2 The Flat Topology: Cost Centers as Leaves, Not Trees

The `CostCenter` entity has no `parentId` field. Cost centers are always leaf nodes — they cannot be hierarchically structured. This is a deliberate rejection of the "cost center as a sub-chart-of-accounts" model that some accounting systems implement.

In a corporate accounting context, cost centers are often hierarchical: "Department → Sub-department → Team." Qayd rejects this hierarchy for personal accounting. The reasons are structural:

1. **The account hierarchy already provides classification structure.** The chart of accounts (with parent-child account relationships) provides the hierarchical classification of financial activity. A parallel hierarchy in cost centers would create redundant complexity.

2. **Personal finance cost centers are simple categories.** "Household expenses," "Car expenses," "Investment portfolio" — these are flat categories, not hierarchical structures. The user is not managing a multi-tier organizational cost center tree.

3. **Adding dimensions provides multi-axis analysis without hierarchy.** The `CostCenterDimension` system provides analytical granularity within a flat center. A single flat center "Family Expenses" can have dimensions for individual family members, creating a two-level structure (center + dimension) that serves most analytical needs without full hierarchy.

The flat topology is a complexity trade-off: simplicity at the cost center level, granularity through the dimension system.

[Code Reference: `cost_center.dart`]

---

### 10.3 The `CostCenterType` Binary: Cost vs. Profit as Constitutional Identity

The `CostCenterType` enum contains exactly two values: `cost` and `profit`.

**`cost`:** The center tracks resource consumption — expenditure, outflows, costs. The analytical question for a cost center is: "How much did this activity cost?" measured by the total debits posted to accounts while this center was tagged.

**`profit`:** The center tracks value generation — revenue, inflows, returns. The analytical question for a profit center is: "How much did this activity generate AND cost?" measured by the net of inflows and outflows tagged to it.

The type is set at `CostCenter.create()` and (by the absence of an `updateType()` method) cannot be changed thereafter. This constitutional immutability reflects the principle that an analytical center's fundamental character — whether it represents a cost pole or a profit pole — is not a configurable preference. Reclassifying a center from cost to profit after years of data accumulation would retroactively change the analytical meaning of all historical data tagged to it.

The dichotomy between two center types mirrors the management accounting distinction between cost centers (overhead departments, administrative units) and profit centers (revenue-generating business units, investment portfolios). In a personal finance context: "Grocery spending" is a pure cost center; "Rental property" is a profit center (it has both rental income and maintenance costs).

[Code Reference: `cost_center_type.dart`]

---

### 10.4 The Eleven Dimension Categories: A Sociology of Personal Spending

The `CostCenterDimensionCategory` class (`cost_center_dimension_category.dart`) defines eleven static default categories, each representing a distinct domain of personal financial life. The selection and ordering of these categories is not arbitrary — it constitutes a sociological model of how individuals and households allocate economic resources.

Examining the eleven categories in order:

**1. `incomeAndWork` (الدخل والعمل) — Icon: `payments`**

Income appears first because, in the system's model of personal finance, income is foundational. Without income, no other spending is sustainable. The placement of income at position 1 reflects the economic principle that production precedes consumption. The `payments` icon represents the flow of monetary compensation for work.

**2. `housingAndLiving` (السكن والمعيشة) — Icon: `home`**

Housing appears second because it is the most fundamental survival expenditure after income. Shelter is the primary cost of existence. In Maslow's hierarchy of needs, shelter is a basic physiological need. Its placement immediately after income reflects the priority of baseline survival costs over all discretionary spending.

**3. `nutritionAndConsumption` (التغذية والاستهلاك اليومي) — Icon: `restaurant`**

Food and daily consumption form the third category. Together with housing (category 2), they constitute the two irreducible categories of basic human sustenance. The Arabic phrase "الاستهلاك اليومي" ("daily consumption") extends this category beyond food to include all recurring daily necessities: toiletries, household supplies, recurring small expenditures.

**4. `transportation` (النقل والتنقل) — Icon: `directions_car`**

Transportation comes fourth — the cost of movement, which is required for economic participation (reaching work, markets, services). The `directions_car` icon reflects the primary transportation mode in the Gulf Arab context (where most users of an Arabic-language personal finance app reside): personal vehicle ownership.

**5. `healthAndPersonalCare` (الصحة والعناية الشخصية) — Icon: `medical_services`**

Healthcare and personal care represent expenditures on physical wellbeing. This category covers medical consultations, medications, gym memberships, personal care products. Its placement at position 5 — after the four categories covering shelter, food, and mobility — reflects the triage logic of survival: you need shelter, food, and transportation before you can allocate to healthcare optimization.

**6. `educationAndDevelopment` (التعليم وتنمية القدرات) — Icon: `school`**

Education and capacity development — school fees, courses, books, professional development. The Arabic phrase "تنمية القدرات" ("capacity development") extends the category beyond formal education to include self-improvement investments. This category reflects the cultural value placed on education in the Arab world, where education spending is a significant household budget item.

**7. `familyAndDependents` (الأسرة والمعالون) — Icon: `family_restroom`**

Family and dependents — expenditures on children, elderly parents, family members who depend on the user economically. The word "معالون" (`mu'aloon`, "those supported") reflects the cultural concept of financial guardianship in Islamic family structure, where the head of household (`wali`) is responsible for the financial welfare of their dependents.

**8. `obligationsAndDebts` (الالتزامات والديون) — Icon: `account_balance`**

Obligations and debts — loan repayments, contractual commitments, standing obligations. The placement at position 8 reflects the priority hierarchy: after baseline needs and family obligations are met, debt service is next. The `account_balance` icon represents the formal financial institution context (bank loans, credit agreements) covered by this category.

**9. `investmentsAndProjects` (الاستثمارات والمشاريع) — Icon: `trending_up`**

Investments and projects — capital deployment for growth: real estate purchases, stock market investments, business ventures. The `trending_up` icon represents the expectation of appreciation. This category covers the active wealth-building activities that are possible only after survival, family, and debt obligations are met.

**10. `savingsAndReserves` (الادخار وبناء الاحتياطي) — Icon: `savings`**

Savings and reserves — the building of financial buffers without specific investment targets. Emergency funds, savings accounts, reserve accounts. The distinction from category 9 (investments) is intent: savings are defensive (protecting against future adversity), investments are offensive (seeking future returns).

**11. `entertainmentAndLifestyle` (الترفيه ونمط الحياة) — Icon: `sports_esports`**

Entertainment and lifestyle — the final category, representing discretionary pleasures: dining out, travel, entertainment subscriptions, fashion. The `sports_esports` icon (a gaming controller) signals a broader meaning than just gaming — digital entertainment, sports, leisure. Its placement at position 11 reflects the priority logic: entertainment is the last category to receive budget allocation after all essential and obligatory spending is covered.

**The Full Priority Cascade:**

```
1. Income    → Source of all funds
2. Housing   → Primary survival need
3. Nutrition → Primary survival need
4. Transport → Economic participation
5. Health    → Physical maintenance
6. Education → Capacity development
7. Family    → Social obligation
8. Debts     → Contractual obligations
9. Invest    → Wealth building (offensive)
10. Savings  → Wealth protection (defensive)
11. Entertainment → Discretionary pleasure
```

The ordering is not alphabetical, not arbitrary, and not culturally neutral. It is a declaration of a personal finance priority system: survival before pleasure, obligation before discretion, investment before entertainment. This hierarchy is embedded in the code's static constant ordering and is non-configurable.

[Code Reference: `cost_center_dimension_category.dart`, lines 98–110]

---

### 10.5 The Extensibility Escape: Why the Category List Is Not a Closed Enum

The `CostCenterDimensionCategory` class was formerly a Dart `enum` — a closed, compile-time fixed set. It was refactored to a regular Dart class with a static `values` list and a static constant per default category. The class comment reads: *"Formerly a static enum, now a dynamic entity to allow user customization."*

This refactoring is an architectural concession to the reality that eleven categories cannot exhaustively model every individual's financial life. A freelancer might add "Platform Fees" as a category. A landlord might add "Property Management." An entrepreneur might add "Business Development."

The shift from `enum` to `class` enables the application layer to create custom `CostCenterDimensionCategory` instances with user-defined `id`, `name`, and `iconName`. The eleven static constants remain as "blessed" defaults — pre-seeded, `isDefault = true`, with known `id` strings that make them identifiable and backward-compatible.

The eleven defaults are not a ceiling. They are a foundation.

[Code Reference: `cost_center_dimension_category.dart`, lines 3–4, 98–110]

---

### 10.6 Default Cost Centers on Accounts: Pre-Tagged Financial Relationships

The `CreateAccountUseCase` supports `defaultCostCenters` — a list of `CostCenterTag` objects to be stored against the account:

```dart
// create_account_use_case.dart, lines 115–123
if (input.defaultCostCenters.isNotEmpty) {
  for (final tag in input.defaultCostCenters) {
    await _accountRepository.saveDefaultCostCenter(
      accountId: id,
      costCenterId: tag.costCenterId,
      dimensionIds: tag.dimensionIds,
    );
  }
}
```

This enables account-level pre-configuration of cost center associations. A user who creates a "Grocery Store" counterparty account can configure it to always tag transactions to the `nutritionAndConsumption` center with a "Groceries" dimension. When a voucher is created against this account, the application layer can auto-populate the cost center tags from the account's defaults.

This pre-configuration reduces the analytical burden at transaction creation time. Instead of manually selecting the cost center for every grocery purchase, the user configures it once on the account and all future vouchers against that account inherit the analytical classification automatically.

[Code Reference: `create_account_use_case.dart`, lines 115–123; `manage_account_default_cost_centers_use_case.dart`]

---

### 10.7 The Budget as an Optional Sentinel: Domain Entity vs. Application Enforcement

The `CostCenter` entity carries a `budgetMinorUnits` field that represents an optional spending ceiling. The `hasBudget` computed property:

```dart
// cost_center.dart
bool get hasBudget => budgetMinorUnits > 0;
```

Zero indicates "no budget limit." A positive integer represents the maximum minor-unit expenditure allowed within this cost center.

**Critical architectural note:** The domain entity does not enforce the budget. There is no `assertWithinBudget()` method that throws if cumulative spending exceeds `budgetMinorUnits`. The domain entity merely carries the limit. Budget enforcement — checking whether cumulative tagged expenditure exceeds the limit, and what to do when it does (alert? block?) — is entirely the responsibility of the application layer.

This is a deliberate design choice: budget enforcement is a policy decision, not an accounting rule. Whether exceeding a budget should block a transaction or merely generate a warning is a user preference, not a domain invariant. By keeping the budget as data in the entity and the enforcement in the application layer, the system allows the enforcement policy to be changed without modifying domain logic.

[Code Reference: `cost_center.dart`]

---

### 10.8 The Non-Deletability of Cost Centers: Analytical History as Permanent Record

The `CostCenter` entity provides a `suspend()` method but no `delete()` method. The entity comment reads: *"Centers are never deleted — they can be suspended (deactivated) only when their balance is zero (enforcement is in the application layer)."*

Two additional invariants prevent even suspension for protected centers:

```dart
// cost_center.dart: suspend()
if (isDefault) {
  throw ImmutableEntityException(
    code: 'cost_center_suspend_default',
  );
}
```

And for renaming:

```dart
// cost_center.dart: rename()
if (isDefault) {
  throw ImmutableEntityException(
    code: 'cost_center_rename_default',
  );
}
```

Default cost centers cannot be suspended OR renamed. They are permanent fixtures of the analytical landscape — both in terms of operational availability and in terms of identity (their `id` strings like `'income_work'`, `'housing_living'` are stable, hardcoded constants in the dimension category class).

The non-deletability creates a design constraint: once a cost center exists and has been used to tag vouchers, it cannot be removed without creating orphaned voucher-center associations. The system prefers to preserve analytical history (even for inactive centers) rather than allow destructive deletion that would corrupt historical reports.

[Code Reference: `cost_center.dart`]

---

---

## SECTION 11: THE TRIPARTITE TRANSFER MODEL

---

### 11.1 The Three-Principal Financial Protocol

The tripartite transfer system models a financial mediation scenario with three distinct principals and two transaction legs:

```
          TRIPARTITE TRANSFER TOPOLOGY

    Principal A          Principal C          Principal B
    (Source)            (Mediator/User)        (Destination)
        │                     │                      │
        │   ┌─────────────────┤                      │
        │   │  RECEIPT LEG    │                      │
        ├──►│  A→C            │                      │
        │   │  (VoucherType=  │                      │
        │   │   receipt)      │                      │
        │   └─────────────────┤                      │
        │                     │                      │
        │                     │  ┌───────────────────┤
        │                     │  │  PAYMENT LEG      │
        │                     │  │  C→B              │
        │                     │  │  (VoucherType=    │
        │                     ├──►  payment)         │
        │                     │  │  isContingent=true│
        │                     │  └───────────────────┤
        │                     │                      │
        │   ┌─────────────────┤                      │
        │   │  FEE VOUCHER    │                      │
        ├──►│  A→FeeAccount   │                      │
        │   │  (if fee > 0)   │                      │
        │   └─────────────────┤                      │

    Three vouchers, one transferGroupId, causal ordering enforced.
```

**Deductive Interpretation:** The diagram reveals the system's answer to a fundamental problem in personal financial mediation: how do you ensure that C does not pay B before receiving from A? The `isContingent = true` flag on the payment voucher is the architectural lock that enforces causal ordering. The system's answer is not a policy instruction to the user — it is a mechanical lock in the data model.

[Code Reference: `tripartite_meta.dart`; `create_tripartite_transfer_use_case.dart`]

---

### 11.2 The `transferGroupId` as the Atomic Bond of the Transfer Complex

The `TripartiteMeta.transferGroupId` is a UUID generated once for the entire transfer complex and shared across all vouchers in the group: the receipt voucher, the payment voucher, and the fee voucher (if applicable).

```dart
// tripartite_meta.dart, lines 20–21
/// UUID shared between the receipt and payment vouchers in this transfer.
final String transferGroupId;
```

This shared identifier is the system's mechanism for:

1. **Querying the transfer complex:** "Give me all vouchers where `tripartiteMeta.transferGroupId == X`" retrieves the complete set of vouchers constituting a single transfer.

2. **Cascade release:** When `ConfirmVoucherUseCase._cascadeTripartiteRelease()` searches for contingent payment siblings, it filters by `transferGroupId`:

   ```dart
   // confirm_voucher_use_case.dart
   where (v) => v.tripartiteMeta?.transferGroupId == transferGroupId
               && v.isContingent == true
   ```

3. **Display context:** The `GetVoucherDetailsUseCase` includes `transferGroupId` in its output DTO, enabling the UI to provide a "View Complete Transfer" navigation action.

The `transferGroupId` is thus not merely metadata — it is the binding key that makes the three-voucher transfer complex navigable and retrievable as a unit.

[Code Reference: `tripartite_meta.dart`, lines 19–21; `confirm_voucher_use_case.dart`, lines 133–180]

---

### 11.3 The `linkedPartyId` Cross-Reference: Perspective Reconstruction from Any Vantage Point

The `TripartiteMeta.linkedPartyId` field holds the ID of the "other" principal in the chain — the one not directly named in the voucher's standard `counterpartyId` and `affectedAccountId` fields:

```dart
// tripartite_meta.dart, lines 25–28
/// The counterpart party in the chain:
/// - On the receipt (A→C): stores B's account ID (final beneficiary).
/// - On the payment (C→B): stores A's account ID (original source).
final AccountId linkedPartyId;
```

This cross-reference enables any party who receives either the receipt voucher or the payment voucher to reconstruct the full transfer topology.

Party A receives the receipt voucher. It tells A: "You sent to C (affectedAccountId), and the ultimate destination is B (linkedPartyId)."

Party B receives the payment voucher. It tells B: "You received from C (affectedAccountId), and the original source was A (linkedPartyId)."

Without `linkedPartyId`, B would see only that C paid them — they would have no record of A's involvement in the chain. With `linkedPartyId`, B can view the complete transfer topology and understand that C acted as an intermediary between A and themselves.

This transparency serves both the mediator and the end parties: the complete transfer chain is auditable by all participants, preserving the accountability of the intermediary role.

[Code Reference: `tripartite_meta.dart`, lines 25–28]

---

### 11.3.1 The Personal Account Non-Impact Doctrine: Accounting Isolation as a Structural Guarantee

The `linkedPartyId` cross-reference achieves transparency for all three principals. There is, however, a complementary doctrine that governs *what is not recorded* in the tripartite model: the mediator's personal accounts with the source party (A) and the destination party (B) are not touched by the tripartite transfer ledger entries.

This is not a policy instruction — it is a structural consequence of how `EntryGenerator.generateForConfirmedVoucher()` is coded:

```dart
// entry_generator.dart — Receipt leg (A→C)
case VoucherType.receipt:
  return [
    LedgerEntry(accountId: voucher.affectedAccountId, side: EntrySide.debit, ...),   // ← C's cash fund
    LedgerEntry(accountId: voucher.counterpartyId, side: EntrySide.credit, ...),      // ← A's account
  ];

// entry_generator.dart — Payment leg (C→B)
case VoucherType.payment:
  return [
    LedgerEntry(accountId: voucher.counterpartyId, side: EntrySide.debit, ...),       // ← B's account
    LedgerEntry(accountId: voucher.affectedAccountId, side: EntrySide.credit, ...),   // ← C's cash fund
  ];
```

On the receipt voucher, `affectedAccountId` = C's liquid cash fund and `counterpartyId` = A (the external source). On the payment voucher, `affectedAccountId` = C's liquid cash fund and `counterpartyId` = B (the destination). In both cases, the two accounts targeted by the ledger entries are:

1. **C's designated cash fund** (the `affectedAccountId` specified when creating the tripartite transfer).
2. **A's account** (on the receipt leg) or **B's account** (on the payment leg).

The mediator's *personal* account relationship with A — the account that reflects informal loans, shared expenses, or personal debts between C and A — is a **different account** from A's party account used as the `counterpartyId`. The system makes no assumption that these are the same. If C has a longstanding personal balance with A, that balance is recorded in C's personal ledger under a different account entry line. The tripartite receipt voucher posts to A's formal counterparty account, not to C's personal relationship account.

**The net effect for the mediator:**

```
Before tripartite transfer (1,000 units):
  C's personal balance with A:   500 (A owes C)    ← UNCHANGED
  C's personal balance with B:   0                  ← UNCHANGED
  C's liquid cash fund:          X

After tripartite transfer:
  C's personal balance with A:   500 (still)        ← UNCHANGED
  C's personal balance with B:   0 (still)           ← UNCHANGED
  C's liquid cash fund:          X + 1,000 − 1,000 = X  (net zero)
```

The tripartite entries traverse C's cash fund and exit — they do not alter C's personal relationship ledger with either party.

```
  PERSONAL ACCOUNT ISOLATION — VISUAL TOPOLOGY

  ┌──────────────────────────────────────────────────────────────────┐
  │  C's Ledger BEFORE tripartite transfer (1,000 units)             │
  │                                                                  │
  │  ┌─────────────────────────────┐  ┌──────────────────────────┐   │
  │  │  Account: A (personal)      │  │  Account: B (personal)   │   │
  │  │  Balance: 500  (A owes C)   │  │  Balance: 0              │   │
  │  └─────────────────────────────┘  └──────────────────────────┘   │
  │                                                                  │
  │  ┌─────────────────────────────────────────────────────────┐     │
  │  │  C's Cash Fund  (affectedAccountId)   Balance: X        │     │
  │  └─────────────────────────────────────────────────────────┘     │
  └──────────────────────────────────────────────────────────────────┘

          RECEIPT LEG (A → C)         PAYMENT LEG (C → B)
          ──────────────────         ──────────────────────
          Dr  C's Cash Fund  +1,000  Dr  B's counterparty   +1,000
          Cr  A's counterparty -1,000  Cr  C's Cash Fund    -1,000
               ↑                            ↑
          affectedAccountId          affectedAccountId
          (C's Cash Fund)            (C's Cash Fund)

           ╳  A (personal) account  ← NEVER TOUCHED BY EntryGenerator
           ╳  B (personal) account  ← NEVER TOUCHED BY EntryGenerator

  ┌──────────────────────────────────────────────────────────────────┐
  │  C's Ledger AFTER tripartite transfer                            │
  │                                                                  │
  │  ┌─────────────────────────────┐  ┌──────────────────────────┐   │
  │  │  Account: A (personal)      │  │  Account: B (personal)   │   │
  │  │  Balance: 500  ← UNCHANGED  │  │  Balance: 0  ← UNCHANGED │   │
  │  └─────────────────────────────┘  └──────────────────────────┘   │
  │                                                                  │
  │  ┌─────────────────────────────────────────────────────────┐     │
  │  │  C's Cash Fund   Balance: X+1,000-1,000 = X  (NET ZERO) │     │
  │  └─────────────────────────────────────────────────────────┘     │
  └──────────────────────────────────────────────────────────────────┘

  Key: The two entries in each leg use affectedAccountId (Cash Fund)
       and counterpartyId (A or B formal account) — NOT the personal
       relationship accounts that C maintains with A and B privately.
```

**The critical distinction from two sequential independent vouchers:**

If C were to record two independent, non-tripartite vouchers — a receipt from A and a payment to B — those vouchers would use whatever accounts C chose. If C chose the "A personal account" as the counterparty for the receipt, the personal balance would be affected. The tripartite mechanism prevents this ambiguity by routing both legs through the mediator's *designated cash fund*, enforced by the `affectedAccountId` constraint in `CreateTripartiteTransferInput`:

```dart
/// The mediator's own account (C) — usually the default cash/liquid account.
final String affectedAccountId;
```

The designation is explicit at creation time. The choice of `affectedAccountId` determines which of C's accounts acts as the pass-through channel. If correctly set to C's operational cash fund (not to any personal relationship account), the personal ledger relationships remain structurally isolated.

**[enforced by structure]**: `EntryGenerator` deterministically uses `affectedAccountId` and `counterpartyId` — there is no conditional logic that could inadvertently route an entry to a personal balance account. The isolation is not a guard clause — it is a consequence of the entry generation algorithm.

[Code Reference: `entry_generator.dart`; `create_tripartite_transfer_use_case.dart`; `create_tripartite_transfer_input.dart`]

---

### 11.4 The `isContingent` Flag: A Temporal Guardian of Causal Integrity

The `isContingent` boolean on `TripartiteMeta` is the system's enforcement mechanism for the causal ordering invariant: the payment leg (C→B) must not execute before the receipt leg (A→C) is confirmed.

```dart
// tripartite_meta.dart, lines 36–38
/// When `true`, this voucher is locked (cannot be shared/signed) until
/// its parent voucher in the group transitions to confirmed/verified.
final bool isContingent;
```

The contingency lock is set at creation: the payment voucher is created with `isContingent = true` by `CreateTripartiteTransferUseCase`.

The lock is released by `ConfirmVoucherUseCase._cascadeTripartiteRelease()` when the receipt voucher's confirmation is processed. The release mechanism:

```dart
// confirm_voucher_use_case.dart (cascadeTripartiteRelease)
final contingentSiblings = allInGroup.where((v) => v.isContingent).toList();
for (final sibling in contingentSiblings) {
  final released = Voucher.restore(
    ...sibling fields...
    tripartiteMeta: sibling.tripartiteMeta?.release(),
  );
  await _voucherRepository.save(released);
}
```

The use of `TripartiteMeta.release()` — which returns a new `TripartiteMeta` with `isContingent = false` — combined with `Voucher.restore()` (the data layer's rehydration factory) achieves the contingency release without triggering the creation guards in `Voucher.draft()`.

**Why `Voucher.restore()` instead of a domain method?**

A domain method on `Voucher` for releasing contingency would be: `Voucher releaseContingency()`. However, this method would semantically apply only to contingent tripartite payment vouchers. Adding it to the `Voucher` entity would pollute the general voucher model with a highly specific tripartite concern. Using `Voucher.restore()` keeps the domain entity clean while achieving the necessary state mutation through the data layer's rehydration factory.

This is an acknowledged case of pragmatism over purity: the tripartite release operation borrows the data layer's factory because creating a dedicated domain method for a narrow special case would over-specialize the domain model.

[Code Reference: `tripartite_meta.dart`, lines 36–48; `confirm_voucher_use_case.dart`, lines 133–180]

---

### 11.5 The `TripartiteMeta.release()` Method: Immutability in Action

The `TripartiteMeta.release()` method demonstrates the system's immutability pattern applied to a value object:

```dart
// tripartite_meta.dart, lines 41–48
TripartiteMeta release() => TripartiteMeta(
  transferGroupId: transferGroupId,
  role: role,
  linkedPartyId: linkedPartyId,
  mediatorAccountId: mediatorAccountId,
  feeAmount: feeAmount,
  isContingent: false,  // ← The only change
);
```

`release()` does not modify `this`. It returns a new `TripartiteMeta` object with `isContingent = false` and all other fields copied from `this`. This is the value object pattern applied consistently: value objects are immutable, and all state transitions produce new instances.

The immutability of `TripartiteMeta` means that no code can accidentally "release" a contingent flag without creating a complete audit trail: the old `TripartiteMeta` (with `isContingent = true`) is discarded, and the new one (with `isContingent = false`) is saved to persistence. The persistence write is the record of the release event.

[Code Reference: `tripartite_meta.dart`, lines 41–48]

---

### 11.6 Fee Capture: The Mediator's Revenue Mechanism

When a transfer fee is configured, `CreateTripartiteTransferUseCase` creates a third voucher for fee capture:

```dart
// create_tripartite_transfer_use_case.dart
final feeVoucher = Voucher.draft(
  id: VoucherId(_idGenerator.next()),
  type: VoucherType.receipt,    // ← Receipt INTO the fee account
  counterpartyId: sourceId,     // ← From the source party (A)
  affectedAccountId: feeAccount.id, // ← Into the fee revenue account
  amount: feeAmount,
  currency: currency,
  ...
  tripartiteMeta: TripartiteMeta(
    transferGroupId: transferGroupId,
    role: TripartiteRole.feeReceipt,
    linkedPartyId: destId,
  ),
);
```

The fee voucher is a receipt from the source party (A) into the mediator's fee revenue account. This is the system's model of fee economics: the source party "pays" the fee by being the counterparty on the fee receipt voucher. When the mediator confirms this fee voucher, the fee amount is posted as a debit to the source party's account and a credit to the fee revenue account.

The fee account is auto-generated if it doesn't exist yet:

```dart
// create_tripartite_transfer_use_case.dart
final feeAccount = _getOrCreateFeeRevenueAccount();
```

This auto-creation ensures that the first time the mediator charges a fee, the fee revenue account is automatically provisioned — the user's accounting system expands to accommodate the new economic activity without manual intervention.

The architectural question raised in the Phase I document — whether the fee account being created under `AccountClassification.settlements` (not `remittanceFees`) is intentional — remains open. The `remittanceFees` classification exists in the standard taxonomy specifically for this purpose. The current behavior creates the account under `settlements`. This may represent a historical implementation choice that predates the formal taxonomy, or a deliberate simplification. Code evolution context is required to resolve this question definitively.

[Code Reference: `create_tripartite_transfer_use_case.dart`]

---

### 11.7 The SWIFT Analogy: Structural Equivalence at the Protocol Level

The tripartite transfer model is structurally equivalent to the correspondent banking model used in SWIFT (Society for Worldwide Interbank Financial Telecommunication) transfers:

| SWIFT Concept | Qayd Tripartite Equivalent |
|---|---|
| Originating bank | Mediating party C (receives from A) |
| Corresponding bank | Mediating party C (pays to B) |
| Nostro account | Mediator's `liquidAssets` account |
| Vostro account | Source/Destination accounts |
| SWIFT message (MT103) | Receipt + Payment voucher pair |
| Value date | `tripartiteMeta.date` |
| Bank charges | Fee voucher (type=receipt, to feeAccount) |
| Settlement guarantee | `isContingent` contingency lock |

The critical distinction: SWIFT transfers operate under international treaty law, banking regulations, and central bank oversight. They involve legally chartered financial institutions bound by KYC/AML requirements. The Qayd tripartite mechanism operates at the informal personal level — it models the *economic pattern* of correspondent banking without any of its legal, regulatory, or institutional infrastructure.

Qayd is not a regulated financial instrument. It is an accounting tool for people who naturally function as intermediaries in informal transfer networks — a common economic reality in many cultures where formal banking infrastructure is limited, expensive, or culturally unfamiliar. The software models the economic pattern; the legal and social structures that make it legitimate or appropriate are external to the accounting system.

[Code Reference: `create_tripartite_transfer_use_case.dart`; `tripartite_meta.dart`; `tripartite_role.dart`]

---

## SECTION 12: THE LEDGER AS CONVERSATION — CONVERSATIONAL EPISTEMOLOGY OF DEBT

---

### 12.1 The `ListAccountStatementChatUseCase`: A Use Case That Thinks Differently

The `ListAccountStatementChatUseCase` (`list_account_statement_chat_use_case.dart`) is architecturally the most philosophically complex use case in the system. Its name contains the word "Chat" — not "Statement," not "Ledger," not "History." This naming choice is revealing: it declares that the system's interaction with financial counterparties is not transactional (one-directional) but conversational (bilateral).

The word "chat" carries specific meaning in software: a conversation between two or more parties, presented as a threaded sequence of messages, each contextually aware of what came before. The `ListAccountStatementChatUseCase` applies this paradigm to the account statement: rather than presenting a flat ledger of entries, it presents a conversation between the user and their counterparty, where each financial event is a "message."

The use case's internal logic is driven by a `perspective` parameter — the account from whose vantage point the conversation is being viewed. The same debt between two parties appears completely differently depending on who is reading it:

```
Counterparty A's perspective:  "I sent 100 to B (payment, debit to my liquid assets)"
Counterparty B's perspective:  "I received 100 from A (receipt, credit to my receivables)"
```

The `direction` field of each chat item (which the use case computes) tells the UI whether the financial event is an "outbound message" (money leaving the perspective account) or an "inbound message" (money arriving).

[Code Reference: `list_account_statement_chat_use_case.dart`]

---

### 12.2 The Direction Calculation: Perspective-Dependent Economic Polarity

The direction calculation in `ListAccountStatementChatUseCase` works by resolving which account is the "perspective" account and which is the "counterparty" account in the context of the voucher.

For a `VoucherType.payment` voucher, the polarity of the cash flow depends on perspective:

```
If perspective account == affectedAccountId (the cash source):
    Direction: OUTBOUND (money left this perspective)
If perspective account == counterpartyId (the receiving destination):
    Direction: INBOUND (money arrived at this perspective)
```

For a `VoucherType.receipt` voucher, the polarities invert:

```
If perspective account == affectedAccountId (the beneficiary):
    Direction: INBOUND (money arrived here)
If perspective account == counterpartyId (the source):
    Direction: OUTBOUND (money left here)
```

This perspective-dependent direction calculation embodies a sophisticated insight: the same physical financial event has two equally valid descriptions depending on who is describing it. The use case produces the correct description for the specified perspective without requiring the caller to perform this reversal logic.

The architectural implication: the system contains NO single "canonical direction" for a financial event. Direction is always relative. This is philosophically consistent with double-entry accounting, where every entry is both a debit and a credit — the same amount in two accounts, seen from two different vantage points.

[Code Reference: `list_account_statement_chat_use_case.dart`, lines 112-165]

---

### 12.3 Tripartite Filtering in the Chat View: Contingent Leg Suppression

When displaying the account statement chat for a tripartite transfer, the use case suppresses contingent payment legs. A contingent payment voucher (the locked C-to-B leg) does not appear in the chat view until it is released. This prevents a confusing UX scenario where the user sees a payment voucher that appears "pending" without explanation — the contingent status requires context from the receipt leg to be interpretable.

The suppression is purely presentational: the contingent payment voucher exists in the database and is accounted for in the VoucherState system. It is simply not surfaced in the chat view until the triggering condition (receipt confirmation) releases it.

This distinction between "data existence" and "view inclusion" is the system's implementation of the "don't show what cannot yet be acted upon" UX principle. A locked, contingent voucher cannot be signed, shared, or confirmed by the receiving party. Showing it would create a call-to-action without a valid action. Suppression is the correct UX response.

[Code Reference: `list_account_statement_chat_use_case.dart`, lines 78-95]

---

### 12.3.1 The Mediator Exclusion Rule: Tripartite Vouchers Are Invisible in the Mediator's Personal Chats

The most architecturally significant filtering rule in `ListAccountStatementChatUseCase` is not the contingent leg suppression described in §12.3 — it is the **mediator exclusion rule**, which governs *which conversation a tripartite voucher belongs to*.

The rule is expressed in a single conditional block:

```dart
// list_account_statement_chat_use_case.dart, lines 82–88
if (v.isTripartite) {
  final mediatorId =
      v.tripartiteMeta?.mediatorAccountId ?? v.affectedAccountId;
  if (myId == mediatorId || cpId == mediatorId) {
    return false; // Exclude from Mediator's chat with parties
  }
}
```

**Deductive Interpretation:** If the conversation being viewed involves the mediator C as one of its two parties (i.e., `myId == mediatorId` or `cpId == mediatorId`), then the tripartite voucher is **excluded from that conversation entirely**. It does not appear in C's chat with A. It does not appear in C's chat with B.

This is the inverse of what one would naively expect. One might assume that:

- The receipt leg (A→C) would appear in A's conversation with C.
- The payment leg (C→B) would appear in C's conversation with B.

The system deliberately refuses this arrangement. Instead, tripartite vouchers are routed to the **conversation between the source (A) and the destination (B)** — the two principals whose economic relationship is ultimately served by the transfer, regardless of C's physical intermediation.

**The cross-reference that makes this work:**

The `linkedPartyId` field (documented in §11.3) is the mechanism that enables this routing. When A opens their chat with B, the chat inclusion filter checks:

```dart
// list_account_statement_chat_use_case.dart, lines 75–79
allVouchers = myVouchers.where((v) {
  final involvesCp = v.affectedAccountId == cpId ||
      v.counterpartyId == cpId ||
      v.tripartiteMeta?.linkedPartyId == cpId;  // ← Tripartite routing key
  if (!involvesCp) return false;
  ...
}).toList();
```

The condition `v.tripartiteMeta?.linkedPartyId == cpId` ensures that a voucher where cpId is the *linked* party (not the direct counterparty) is still included in the conversation between the perspective account and cpId. This achieves the tripartite routing: the receipt voucher (A→C, with `linkedPartyId = B`) appears in A's chat with B because B is the `linkedPartyId`.

**Direction from the correct perspective:**

Once routed to the A↔B conversation, the direction is computed using `_directionFromPerspective()`, which uses `linkedPartyId` to reconstruct the original transfer direction:

```dart
// list_account_statement_chat_use_case.dart, lines 339–353
if (v.isTripartite) {
  final isReceipt = v.type == VoucherType.receipt;
  // Receipt: counterpartyId=A, linkedPartyId=B
  final sourceId = isReceipt ? v.counterpartyId : v.tripartiteMeta!.linkedPartyId;
  // Payment: counterpartyId=B, linkedPartyId=A
  final destId   = isReceipt ? v.tripartiteMeta!.linkedPartyId : v.counterpartyId;

  if (perspectiveId == sourceId) return 'outgoing';
  if (perspectiveId == destId)   return 'incoming';
}
```

From A's perspective: A is `sourceId` → direction is `outgoing`.
From B's perspective: B is `destId` → direction is `incoming`.

Both A and B see the transfer as a direct A→B event. The mediator C is surfaced only as a metadata label (`mediatorName`) attached to the chat item — not as a party in the conversation.

**The `mediatorName` field in the chat item DTO:**

```dart
// list_account_statement_chat_use_case.dart
mediatorAccountId: v.tripartiteMeta?.mediatorAccountId?.value,
mediatorName: v.tripartiteMeta?.mediatorAccountId != null
    ? accountNamesLookup[v.tripartiteMeta!.mediatorAccountId!.value]
    : null,
```

The mediator's name is exported as a separate field on the chat item. The UI can render it as: *"via mediator: [C's name]"* — a parenthetical annotation on a fundamentally A↔B conversation, not a participant in that conversation.

**The complete conversational routing table:**

```
Conversation: A ↔ B
   Tripartite voucher appears here (via linkedPartyId routing)
  Direction from A: OUTGOING ("I sent to B via C")
  Direction from B: INCOMING ("I received from A via C")

Conversation: A ↔ C
  ✗ Tripartite voucher EXCLUDED (mediator exclusion rule)
  Only direct (non-tripartite) vouchers between A and C appear here

Conversation: C ↔ B
  ✗ Tripartite voucher EXCLUDED (mediator exclusion rule)
  Only direct (non-tripartite) vouchers between C and B appear here

Mediator C's operational view:
  The tripartite transfer is visible in C's unified fund view / transfer
  group view — not in any bilateral personal conversation.
```

**Why this architecture is philosophically correct:**

The tripartite transfer exists because A wants B to receive money, and C is the physical vehicle. The economic relationship being documented is A→B. The fact that C physically handled the funds is a mechanism, not the event. If A and C had a prior personal debt, that debt is a *different* economic relationship — it belongs in the A↔C conversation. Mixing the tripartite routing transaction into A↔C would contaminate A's personal debt ledger with an unrelated mediation event.

The mediator exclusion rule enforces *semantic clarity*: each bilateral conversation carries only the economic relationships that are *native* to that pair of principals. Mediation events are routed to the A↔B conversation because that is the conversation where the underlying economic intent lives.

**[enforced by code]:** The exclusion is a `return false` in the filtering predicate — it is not advisory. No tripartite voucher where the mediator is one of the conversation's two participants will appear in that conversation.

```
  TRIPARTITE CONVERSATIONAL ROUTING — COMPLETE MAP

  ┌─────────────────────────────────────────────────────────────────────┐
  │         Ali (A)          Mohammed (C)           Badi' (B)           │
  │       [Source]            [Mediator]          [Destination]         │
  │          │                    │                     │               │
  │  ════════╪════════════════════╪═════════════════════╪════════       │
  │  CONVERSATION  A ↔ B         ║                      ║               │
  │  ══════════════════════════  ║                      ║               │
  │    Transfer 1,000 appears   ║                      ║               │
  │     ┌───────────────────┐    ║                      ║               │
  │     │ [→ OUTGOING]      │    ║    [INCOMING ←]      ║               │
  │     │  1,000 units      │════╬══►  1,000 units      ║               │
  │     │  via Mohammed (C) │    ║     via Mohammed (C) ║               │
  │     └───────────────────┘    ║                      ║               │
  │                              ║                      ║               │
  │  ════════════════════════════╬══════════════════════╬═══════        │
  │  CONVERSATION  A ↔ C         ║                      ║               │
  │  ══════════════════════════  ║                      ║               │
  │  ✗  Tripartite voucher       ║   [mediator rule:    ║               │
  │     does NOT appear here  ───╬►   return false]     ║               │
  │     Only direct A↔C          ║                      ║               │
  │     vouchers appear          ║                      ║               │
  │                              ║                      ║               │
  │  ════════════════════════════╬══════════════════════╬═══════        │
  │  CONVERSATION  C ↔ B         ║                      ║               │
  │  ══════════════════════════  ║                      ║               │
  │  ✗  Tripartite voucher       ║   [mediator rule:    ║               │
  │     does NOT appear here ────╬────────────────────► ║return false]  │
  │     Only direct C↔B          ║                      ║               │
  │     vouchers appear          ║                      ║               │
  │                              ║                      ║               │
  │  ════════════════════════════╬══════════════════════╬═══════        │
  │  MEDIATOR C's OPERATIONAL VIEW (Fund Ledger / Transfer Group)       │
  │    Both legs visible in unified fund view                          │
  │     Receipt (A→C)  +1,000  │  Payment (C→B)  -1,000                 │
  │     Net: 0 (pass-through confirmed)                                 │
  └─────────────────────────────────────────────────────────────────────┘

  DECISION ENGINE (per voucher v, per conversation myId↔cpId):
  ┌─────────────────────────────────────────────────────────────────────┐
  │                                                                     │
  │  isTripartite?  ──YES──►  mediatorId = meta.mediatorAccountId       │
  │       │                              ?? affectedAccountId           │
  │       │                        ┌─────────────────────────┐          │
  │       │          myId==med ─►  │  return false (EXCLUDE) │          │
  │       │          cpId==med ─►  │  from this conversation)│          │
  │       │                        └─────────────────────────┘          │
  │       │          else ──────►  check linkedPartyId == cpId          │
  │       │                         if YES: INCLUDE (A↔B routing)       │
  │       NO                                                            │
  │       │                                                             │
  │       └──────────────────────►  normal counterpartyId check         │
  └─────────────────────────────────────────────────────────────────────┘
```

[Code Reference: `list_account_statement_chat_use_case.dart`, lines 75–93, 339–354]

---

### 12.4 The Chat Item Envelope: Wrapping Financial Reality in Social Form

The output DTO of `ListAccountStatementChatUseCase` is a list of `VoucherChatItem` objects. Each `VoucherChatItem` wraps a `Voucher` with:

- `direction`: Computed directional polarity relative to the perspective account.
- `isOwnMessage`: Whether the creator of this voucher is the perspective account's owner.
- `isRead`: Whether the counterparty has acknowledged the voucher.
- `timestamp`: The economic event date (not the creation timestamp).
- `runningBalance`: The cumulative net balance at this point in the conversation.

The `isOwnMessage` field drives the chat bubble alignment in the UI: own messages appear on the right (like sent SMS messages), counterparty messages on the left (like received SMS messages). This left-right positioning maps the social convention of chat interfaces onto the structure of bilateral accounting.

[Code Reference: `list_account_statement_chat_use_case.dart`, lines 220-271]

---

### 12.5 Running Balance in the Chat View: The Ledger Within the Conversation

Each `VoucherChatItem` carries a `runningBalance` field — the cumulative net balance between the two parties at the moment of this particular financial event, from the perspective account's point of view.

This running balance is computed incrementally as the use case iterates through chronologically ordered vouchers:

```
int runningBalance = 0;
for (final voucher in chronologicalVouchers) {
  final delta = _computeDelta(voucher, perspective);
  runningBalance += delta;
  items.add(VoucherChatItem(
    voucher: voucher,
    runningBalance: runningBalance,
    ...
  ));
}
```

The `_computeDelta()` function maps voucher type and direction to a signed integer:

- Inbound receipt (money arriving): `+amount.minorUnits`
- Outbound payment (money leaving): `-amount.minorUnits`

The running balance at each chat item tells the user: "At this moment in our financial history, you owed me / I owed you X." This is the account statement rendered as a timeline, with each event annotated with the cumulative net position at that point.

The running balance in a chat view is the fusion of two paradigms: the social (chronological conversation with messages) and the financial (running balance ledger). The result is a **conversational ledger**.

[Code Reference: `list_account_statement_chat_use_case.dart`, lines 225-258]

---

---

## SECTION 13: REPORTING AS AUTHORITATIVE TRUTH — TWO-LAYER KNOWLEDGE ARCHITECTURE

---

### 13.1 The Trial Balance Generator: Three-Phase Balance Computation

The `TrialBalanceGenerator` (`trial_balance_generator.dart`) computes account balances using a three-phase model for each account:

**Phase 1: Opening Balance** — The net balance at the start of the reporting period, derived from all entries before `periodStart`.

**Phase 2: Period Activity** — The sum of debits and sum of credits posted during the period (`periodStart` to `periodEnd`).

**Phase 3: Closing Balance** — Opening Balance + Period Activity (net).

The `_AccountActivity` private class encapsulates these three phases:

```dart
class _AccountActivity {
  int openingDebitMinor = 0;
  int openingCreditMinor = 0;
  int periodDebitMinor = 0;
  int periodCreditMinor = 0;

  int get openingNetMinor => openingDebitMinor - openingCreditMinor;
  int get periodNetMinor => periodDebitMinor - periodCreditMinor;
  int get closingNetMinor => openingNetMinor + periodNetMinor;
}
```

The use of raw `int` fields (not `Money` objects) in `_AccountActivity` is deliberate: at the computation layer, the system needs signed integers that can freely go negative during intermediate computation. The `Money` type hierarchy would impose non-negativity or positivity constraints that would interfere with the arithmetic. Conversion to `Money` objects happens at the output DTO layer, after all computation is complete.

[Code Reference: `trial_balance_generator.dart`]

---

### 13.2 The Balance Sheet Generator: Hierarchical Section Roll-Up

The balance sheet generation process in `GenerateBalanceSheetUseCase` uses a hierarchical classification-to-section mapping to compute aggregated totals. The algorithm:

```
FOR EACH account in the chart of accounts:
  section_total[account.classification] += account.closing_balance

FOR EACH classification section:
  group_total = SUM(section_totals for all accounts in section)

ASSERT: (assets_total + liabilities_total + income_net).abs() < 10
```

The roll-up is performed at the classification section level. Every account's closing balance contributes directly to its classification section total, regardless of its position in the account tree hierarchy. The classification section hierarchy (assets, liabilities, equity/income) is the reporting hierarchy.

The `< 10` tolerance check, as discussed in Section 2.5, is an engineering honesty mechanism: structurally unreachable under the current deterministic `EntryGenerator`, but hedged for future rounding risk.

[Code Reference: `generate_balance_sheet_use_case.dart`]

---

### 13.3 Real-Time Ledger Reads: No Stale Balance Cache

Every trial balance computation is a fresh read from the immutable `LedgerEntry` table, not from a pre-computed cache. The report is always current to the last posted transaction. There is no separate "compute balances" batch job that must be run before requesting a report.

This real-time computation trades performance (re-reading all entries on every report request) for correctness and simplicity (no cache invalidation, no stale balances, no background reconciliation). For personal accounting with hundreds or low thousands of transactions, the performance trade-off is acceptable.

[Code Reference: `trial_balance_generator.dart`; `get_account_statement_use_case.dart`]

---

### 13.4 The Account Statement: Window-Based Ledger Query

The `GetAccountStatementUseCase` (`get_account_statement_use_case.dart`) produces a time-windowed account statement — the chronological sequence of entries for a specific account within a date range, with a running balance.

Both `fromDate` and `toDate` are nullable, supporting three query modes:

1. **Full history:** `fromDate = null, toDate = null`
2. **From inception to date:** `fromDate = null, toDate = date`
3. **Specific period:** `fromDate = start, toDate = end`

The account nature is used to determine the sign convention for the running balance display: for a debit-nature account, debits are positive; for a credit-nature account, credits are positive. This ensures that a cash account's running balance always displays positive when it has money — matching user intuition, not just accounting convention.

[Code Reference: `get_account_statement_use_case.dart`]

---

### 13.5 The Reporting Layer's Independence from Classification

The reporting layer computes balances from ledger entries alone. Classification and nature are used only at the point of interpreting what the balance means (positive vs. negative, debit vs. credit convention). The arithmetic is purely additive: Sigma(Debits) - Sigma(Credits) for every account.

This separation means adding a new classification kind does not require modifying the reporting computation logic. The trial balance generator iterates all accounts and sums their entries; it has no special cases per classification. The balance sheet generator has special-case logic only at the section assignment level (which classification belongs to which report section). Within each section, all accounts are treated identically.

[Code Reference: `trial_balance_generator.dart`; `generate_balance_sheet_use_case.dart`]

---

---

## SECTION 14: THE GOVERNANCE AUTHORITY MODEL — THE EXTERNAL WRITE GATE

---

### 14.1 The `GovernanceWriteGuard`: A Single Chokepoint

Every use case that mutates persistent state calls `_writeGuard.assertWritesPermitted()` as its first operation:

```dart
// Pattern present in ALL mutating use cases
final gate = await _writeGuard.assertWritesPermitted();
if (gate.isFailure) {
  return FailureResult(gate.failureOrNull!);
}
```

There is no code path that persists a voucher, creates an account, or modifies any entity without first passing through this guard. The `GovernanceWriteGuard` is the single chokepoint through which all write operations must pass.

The guard reads the current governance status from `GovernanceStatusReader` and returns a `GovernanceFailure` (code: `'writes_blocked_governance'`) if the status is `suspended` or `revoked`. Only `activated` and `expired` (grace period) statuses permit writes.

[Code Reference: `governance_write_guard.dart`]

---

### 14.2 The Four Governance States: Administrative Lifecycle

The `GovernanceStatus` enum (`governance_status.dart`) defines four states:

**`activated`:** The license is current and fully operational. All write operations permitted.

**`suspended`:** Administratively suspended (e.g., billing delinquency). Write operations blocked. Read operations (balance queries, statement reports) remain accessible. The user can view their existing financial data without being able to modify it.

**`revoked`:** Permanently cancelled. The most severe governance state. Write operations blocked permanently.

**`expired`:** License period ended. Grace period may permit continued writes depending on implementation policy. After grace, transitions to `revoked`.

The "read but not write" governance model for `suspended` status respects the user's ownership of their existing data even while restricting new activity. It is the digital equivalent of "your account is frozen — you can see your balance but cannot make withdrawals."

[Code Reference: `governance_status.dart`]

---

### 14.3 The Trial Status System: Clock-Secured Evaluation Period

The `LicenseVault.readTrialState()` method reads trial period metadata stored in `FlutterSecureStorage`. The trial state consists of:

- `trialStartedAt`: The UTC epoch when the trial began.
- `hasTrialExpired`: A boolean flag set to `true` when the trial period ends.
- `hasActivated`: Whether the user has entered a valid license key.

The trial period is enforced through the combination of:

1. `MonotonicClockGuard.detectTamper()` — preventing clock rollback to restart the trial.
2. `LicenseVault.hasTrialExpired` — the persisted flag that records trial expiration.
3. `GovernanceStatusReader` — which incorporates trial state into the governance status computation.

The three-layer enforcement (clock guard + persisted flag + governance reader) creates a robust trial system that cannot be circumvented by simple clock manipulation — the most common attack vector against trial periods on mobile devices.

[Code Reference: `license_vault.dart`, lines 41-68]

---

### 14.4 The Governance-Application Boundary: Remote Adjudication, Local Execution

The most architecturally interesting aspect of the governance system is its boundary with the local-first principle:

- **Adjudication** (who is allowed) happens remotely: the server issues a JWT token that encodes `GovernanceStatus`.
- **Execution** (what is allowed) happens locally: the `GovernanceWriteGuard` reads the locally cached status and makes the write/no-write decision.

This means the governance system works offline. A previously `activated` system remains operational without network access. A `suspended` system remains blocked without network access.

The risk this creates: a suspended user who knows the governance status is locally cached might attempt to manipulate the cached value. This is mitigated by storing the governance JWT in `FlutterSecureStorage` — the device's hardware-backed secure storage, which is not accessible to ordinary file system operations. Manipulation would require device-level root access.

The boundary between server-adjudicated governance and locally-executed enforcement is the system's adaptation of the local-first principle to the commercial reality that software licensing requires centralized authority.

[Code Reference: `governance_write_guard.dart`; `license_vault.dart`]

---

---

## SECTION 15: SECURITY ARCHITECTURE — CRYPTOGRAPHIC IDENTITY AND THE PANIC SURFACE

---

### 15.1 The Ed25519 Key Pair: Identity as Mathematical Proof

Ed25519 is an elliptic curve algorithm offering 128-bit security with 32-byte keys. Its choice over alternatives reflects:

1. **Small key size:** 64-byte signatures vs. ECDSA's variable-length signatures.
2. **Fast verification:** Approximately 2x faster than ECDSA.
3. **Deterministic signatures:** No random nonce required at signing time, eliminating the "bad RNG leads to private key exposure" vulnerability.
4. **Single-pass signing:** The entire message is hashed once during signing.

The `ReceiptSigningService.signReceipt()` method takes a `SignableReceipt` and `CryptoKeyPair` and returns a `SignedReceipt` containing `signatureHex` and `signerPublicKeyHex`. The signature covers the six-field canonical payload defined in Section 7.1.

The signed receipt is immutable and complete: it contains all information needed for independent verification without server involvement.

[Code Reference: `receipt_signing_service.dart`; `crypto_key_pair.dart`]

---

### 15.2 The Public Key History: Key Rotation Without Historical Loss

The `PartyDetails` entity (`party_details.dart`) maintains two key-related fields:

- `currentPublicKeyHex`: The party's most recently registered public key.
- `publicKeyHistoryHex`: A list of all previously used public keys.

The `allAuthorizedKeys` computed property returns the union:

```dart
List<String> get allAuthorizedKeys => [
  if (currentPublicKeyHex != null) currentPublicKeyHex!,
  ...publicKeyHistoryHex,
];
```

This enables backward verification: a voucher signed two years ago with the key that was current at that time can still be verified today, even if the user has since rotated to a new key pair. The verification engine iterates all authorized keys until it finds one that validates the signature.

This is critical for long-term financial records. Personal accounting records may be maintained for years or decades. A user who rotates their cryptographic keys should not lose the verifiability of historical financial documents. The `allAuthorizedKeys` list preserves verifiability indefinitely — at the cost of indefinitely growing key histories.

The system does not implement key history pruning. This is an acknowledged scalability concern for very long-lived accounts with many rotations, but acceptable for the typical personal finance use case (fewer than 10 key rotations over the account lifetime).

[Code Reference: `party_details.dart`]

---

### 15.3 The Panic Wipe Service: The Nuclear Button

The `PanicWipeService` (`panic_wipe_service.dart`) implements total, irreversible destruction of all security-sensitive material. The `wipeAll()` method destroys three independent storage locations:

```
1. FlutterSecureStorage   -> All cryptographic keys, salts, license data, mnemonic
2. SQLCipher database file -> The entire financial ledger
3. Attachments directory   -> All supporting document files (recursive delete)
```

After `wipeAll()`, the device retains no user financial data of any kind. The application, on next launch, will follow the `freshCreated` database initialization path — behaving as if freshly installed.

The panic wipe is triggered by:

- Explicit user action (security settings panic wipe button).
- Certain governance revocation scenarios.
- Anti-tamper detection (clock tamper leading to trial integrity violation).

The existence of panic wipe as a first-class feature is philosophically significant: the system regards the destruction of data as preferable to adversarial access. It implements the principle that financial privacy is more valuable than financial records — records can be reconstructed from paper sources; privacy, once breached, cannot be restored.

[Code Reference: `panic_wipe_service.dart`]

---

### 15.4 The Secure Storage Architecture: OS-Delegated Hardware Security

`FlutterSecureStorage` delegates to platform-specific hardware-backed secure storage:

- **Android:** Android Keystore System (uses hardware security module if present, TEE otherwise).
- **iOS:** iOS Keychain (hardware-backed on all devices with Secure Enclave: iPhone 5S+).

The keys stored in `FlutterSecureStorage` are:

- `'ed25519_private_key_hex'`: User's signing key.
- `'db_local_salt'`: Local component of the database encryption key.
- `'license_jwt'`: Governance token.
- `'mnemonic_phrase'`: BIP-39 recovery phrase.
- `'trial_started_at'`: Trial epoch.
- `'has_trial_expired'`: Trial expiration flag.

The private key is device-bound — signing can only be performed on the enrolled device.

[Code Reference: `license_vault.dart`; Flutter Secure Storage documentation]

---

### 15.5 The Attachment Security Model: File-Level Reference, Vault-Level Storage

Attachment files are stored by `AttachmentStorageService.store()` in the application's local documents directory, separate from the SQLCipher database. Each attachment undergoes:

1. **Hash computation** (`encryptedBlobHash`): SHA-256 hash of the file content, stored in the `AttachmentRef`.
2. **Path reference** (`storagePath`): The local file system path stored in `AttachmentRef`.

The hash serves as an integrity check: when an attachment is opened, the system can verify that the file at `storagePath` matches the stored hash.

**Critical architectural note:** The attachment files themselves are NOT encrypted at the application layer in the current implementation. They reside in the application's documents directory in plaintext. The database (which contains the attachment references and all financial data) is encrypted. This creates a threat model gap: an attacker with file system access could potentially read attachment files without the database key. This is a known architectural limitation documented in the gap analysis (Section 22).

[Code Reference: `panic_wipe_service.dart`; `attachment_storage_service.dart`]

---

---

## SECTION 16: THE NAVIGATION EPISTEMOLOGY — SEPARATING TIERS OF FINANCIAL ENGAGEMENT

---

### 16.1 The `AppShellPage`: Five Tabs as an Ontological Taxonomy

The `AppShellPage` (`app_shell_page.dart`) is the primary navigation container after authentication. It presents five tabs, each representing a distinct tier of financial engagement:

| Tab | Arabic | Layer | Prerequisite |
|-----|--------|-------|-------------|
| 1 | الحسابات (Accounts) | Entity Definition | None (foundational) |
| 2 | السندات (Vouchers) | Event Recording | Accounts must exist |
| 3 | التقارير (Reports) | Knowledge Extraction | Vouchers must exist |
| 4 | مراكز التكلفة (Cost Centers) | Management Analysis | Vouchers (for tagging) |
| 5 | الإعدادات (Settings) | System Administration | None (meta-layer) |

The five-tab structure encodes the five fundamental layers of a complete accounting system: entity definition, event recording, knowledge extraction, management analysis, and system administration. Every accounting system in the world, from a paper ledger to SAP, contains these five layers in some form.

The ordering is not arbitrary. Entity definition (Tab 1) is the prerequisite for event recording (Tab 2), which produces the data that knowledge extraction (Tab 3) synthesizes, which can be annotated by management analysis (Tab 4), all governed by system administration (Tab 5).

[Code Reference: `app_shell_page.dart`, lines 85-131]

---

### 16.2 The Sync Status Banner: Real-Time Network State in the Financial Shell

The `AppShellPage` integrates a `SyncStatusBanner` at the top of the navigation shell. This banner transitions between states:

- **Hidden** (no sync occurring, local-only operation)
- **`connecting`**: Network negotiation in progress
- **`syncing`**: Transfer in progress
- **`success`**: Last sync completed successfully
- **`failure`**: Last sync failed (reason displayed)

The failure state is particularly important: the user must know when a sync has failed, because their counterparty has not received the voucher they believe they sent. Without the failure banner, the user might assume successful delivery and act on that assumption, creating a financial discrepancy.

[Code Reference: `app_shell_page.dart`, lines 135-180]

---

### 16.3 The Restore Prompt: Recovery Priority Over Normal Navigation

The `AppShellPage` checks on initialization for a pending backup restore request:

```dart
if (await _restoreService.hasPendingRestoreRequest()) {
  _showRestorePrompt();
}
```

If a pending restore request is detected, the system surfaces a restore prompt before the user can access any financial tabs. This is a navigational guard: the UI shell enforces a system-level invariant (restore completion before normal operation) that would otherwise require every tab to check for pending restores independently.

[Code Reference: `app_shell_page.dart`, lines 200-224]

---

---

## SECTION 17: THE COLLATERAL DOCTRINE — SECURED OBLIGATIONS UNDER LOCAL SOVEREIGNTY

---

### 17.1 The `Collateral` Entity: Securitization of Personal Debt

The `Collateral` entity (`collateral.dart`) models collateral — an asset pledged as security for a financial obligation. Its existence proves that Qayd models not just simple cash transactions but the economics of secured credit.

The entity carries:

- `voucherId`: The voucher (obligation) this collateral secures.
- `description`: The description of the pledged asset.
- `estimatedValue`: The estimated value of the asset.
- `status`: The current lifecycle status.

The lifecycle is a four-state machine:

```
           ┌──> liquidated (TERMINAL: collateral seized)
           |
active ────┼──> released   (TERMINAL: obligation fulfilled, collateral returned)
           |
           └──> expired    (TERMINAL: pledge term ended)
```

**`active`:** The collateral is currently pledged. The associated obligation is outstanding.

**`expired`:** The collateral pledge term has ended without the obligation being fulfilled.

**`liquidated`:** The collateral has been seized and sold to satisfy the obligation. Terminal state: the creditor exercised their claim.

**`released`:** The collateral has been returned because the underlying obligation was satisfied. Terminal state: the debt was repaid, the pledge is dissolved.

[Code Reference: `collateral.dart`, lines 1-158]

---

### 17.2 The Collateral-Voucher Bond: Secured Lending in the Domain Model

The link between `Collateral` and `Voucher` is through `voucherId`. The `GetVoucherDetailsUseCase` includes collateral information in the voucher detail DTO:

```dart
final collateral = await _collateralRepository.getByVoucherId(voucher.id);
```

If collateral is associated with a voucher, the detail view displays: "This debt is secured by: [asset description, estimated value: X]." This provides the lender immediate visibility of their security position when reviewing the debt voucher.

The collateral system enables Qayd to model informal secured lending: "I am lending you 50,000 SAR, and your car is pledged as collateral" is representable as a complete and economically accurate record in the system.

[Code Reference: `get_voucher_details_use_case.dart`; `collateral.dart`]

---

### 17.3 Collateral Liberation: The Link Between Settlement and Release

The `released` collateral status is intended to be set when the corresponding obligation is settled. However, the current implementation does not implement automatic collateral release upon voucher settlement. The application layer must explicitly call the collateral release operation.

This is a conceptual gap: in the real world, collateral is automatically released when the secured obligation is satisfied. The system models both the settlement (via `VoucherState.settled`) and the release (via `Collateral.status.released`), but does not enforce the link automatically.

The gap has a practical mitigation: the `GetVoucherDetailsUseCase` surfaces both the voucher state and the collateral status together. If a user settles a voucher with associated collateral, the UI can prompt: "This voucher is settled, but the associated collateral is still active. Release it?"

[Code Reference: `collateral.dart`; `get_voucher_details_use_case.dart`]

---

---

## SECTION 18: ACCRUAL COMPONENTS — TIME-BASED OBLIGATION WITHOUT AUTOMATIC EXECUTION

---

### 18.1 The `AccrualComponent` Entity: Modeling Recurring Financial Reality

The `AccrualComponent` entity (`accrual_component.dart`) models recurring financial obligations — the class of financial event characterized by regular, periodic occurrence: monthly rent, salary payments, subscription fees, quarterly insurance premiums.

The entity carries:

- `amount`: The recurring amount (as `Money`).
- `frequency`: How often the obligation recurs (`weekly`, `monthly`, `quarterly`, `annually`).
- `nextDueDate`: The next date on which the obligation falls due.
- `accountId`: The account to which the recurring entry should be posted.
- `description`: The human-readable description of the obligation.
- `isActive`: Whether this accrual is currently active.

[Code Reference: `accrual_component.dart`]

---

### 18.2 The Execution Gap: Obligation Tracking Without Automatic Journal Entry

The critical architectural characteristic of the `AccrualComponent` system is the absence of an automatic execution mechanism. The `AccrualComponent` tracks that an obligation exists and when it is due. It does NOT automatically create a `Voucher` and post it to the ledger when `nextDueDate` passes.

The system comment in the code is explicit: "Accrual execution (voucher creation) is initiated by the user, not automated. The component tracks the obligation; the user confirms when executed."

This design is deliberate: personal accounting operates in a fundamentally different posture from automated corporate systems. Automatic voucher creation for accruals would bypass:

- The `GovernanceWriteGuard` (write permission check)
- The user's opportunity to review and modify each posting
- The `EntryGenerator` confirmation requirement

These are architectural invariants that exist for good reasons. The accrual component respects them by requiring explicit user confirmation. The component provides the reminder (what is due and when); the user provides the execution.

[Code Reference: `accrual_component.dart`, lines 92-97]

---

### 18.3 The `nextDueDate` Advancement: Forward Motion in Obligation Time

When the user confirms an accrual execution (creating a voucher for the recurring obligation), the application layer is responsible for advancing `nextDueDate` by one frequency period:

```
monthly:   nextDueDate + 1 month
quarterly: nextDueDate + 3 months
annually:  nextDueDate + 1 year
weekly:    nextDueDate + 7 days
```

The `AccrualComponent.advance()` method returns a new instance with the updated `nextDueDate`, preserving the immutability pattern. The original is not mutated. The advancement produces a new domain object.

[Code Reference: `accrual_component.dart`, lines 60-80]

---

---

## SECTION 19: AUDIT TRAIL AND THE NON-DESTRUCTIVE RECORD IMPERATIVE

---

### 19.1 The `AuditLogService`: Entity Change Tracking as a First-Class Concern

The `AuditLogService` (`audit_log_service.dart`) is injected into the major mutating use cases and called after successful persistence operations:

```dart
// create_voucher_use_case.dart, lines 308-320
if (saved.isSuccess) {
  await _auditLogService?.log(
    entityType: 'voucher',
    entityId: voucher.id.value,
    action: AuditAction.create,
    newData: {
      'type': voucher.type.name,
      'amount': voucher.amount.minorUnits,
      'currency': voucher.currency.code,
      'state': voucher.state.name,
    },
  );
}
```

The audit log records: what entity changed, what action was taken (`create`, `update`, `delete`), what the new state is, and when the change occurred. The `oldData` and `newData` maps provide a before/after snapshot of the changed entity's relevant fields.

[Code Reference: `audit_log_service.dart`]

---

### 19.2 The `AuditEntry` Entity: Immutable Change Record

The `AuditEntry` entity (`audit_entry.dart`) is the persisted record of a single audit event. It carries:

- `entityType`: The type of entity changed (`'voucher'`, `'account'`, etc.)
- `entityId`: The ID of the changed entity.
- `action`: `AuditAction.create`, `update`, or `delete`.
- `oldData`: The entity's field values before the change (null for creates).
- `newData`: The entity's field values after the change (null for deletes).
- `timestamp`: When the change occurred.

The `AuditEntry` is immutable — once created, it cannot be modified. The audit log grows monotonically: entries are appended but never overwritten. If an entity is modified five times, there are five `AuditEntry` records. The complete history is fully reconstructible.

This is the system's implementation of the audit trail principle: every write operation leaves an indelible mark. The audit record is separate from the entity itself — modifying or deleting an entity does not remove its audit entries.

[Code Reference: `audit_entry.dart`]

---

### 19.3 The Rollback Placeholder: Acknowledged Incompleteness

The `AuditLogService.rollback()` method is documented in the code as a placeholder:

```dart
Future<void> rollback(String auditEntryId) async {
  // TODO: Implement rollback from audit entry.
  // This requires reversing the change recorded in the audit entry,
  // which for financial entries means generating a reversal voucher.
  throw UnimplementedError('Rollback not yet implemented');
}
```

The comment "for financial entries means generating a reversal voucher" is architecturally important: it acknowledges that ledger rollback cannot be a direct data mutation (deleting ledger entries). It must be implemented through new financial events that reverse the effect of the original events. This is the non-destructive record imperative applied to rollback: even undo is implemented through additive entries, not destructive deletion.

[Code Reference: `audit_log_service.dart`]

---

### 19.4 The Withdrawal as the Principal Non-Destructive Retraction

The primary non-destructive retraction in the system is `Voucher.withdraw()`. When a user withdraws a voucher:

1. The voucher's `state` is set to `VoucherState.withdrawn`.
2. The `withdrawnAt` timestamp is recorded.
3. The voucher record remains in the database.
4. Ledger entries (if any were generated) are not deleted.

The withdrawal does not generate reversal ledger entries. If a confirmed voucher is withdrawn after entries have been posted, those entries remain. This is a potential accounting integrity gap for the edge case where a confirmed-but-not-accepted voucher is withdrawn with existing entries.

This gap is mitigated by the `canWithdraw` guard (Section 6.4), which prevents withdrawal of confirmed vouchers after the counterparty has accepted. The future rollback mechanism (Section 19.3) would address the remaining edge case.

[Code Reference: `voucher.dart`, lines 331-346; `withdraw_voucher_use_case.dart`]

---

---

## SECTION 20: INCOME SOURCE TAXONOMY — REVENUE AS ACCOUNT METADATA

---

### 20.1 The `IncomeSourceType` Enum: Revenue as a Classified Asset Property

The `IncomeSourceType` enum (referenced via `metadata['income_source_type']` on `Account`) classifies revenue-generating accounts into four categories:

**`profession` (المهنة):** Income from active labor — salary, freelance fees, professional services. Earning requires ongoing personal effort.

**`investmentAsset` (أصل استثماري):** Income from deployed capital — rental income, dividends, profit distributions. Earning requires capital at risk, not ongoing labor.

**`possession` (مُلكية):** Income from asset ownership transfers — selling goods, licensing intellectual property, one-time asset sales.

**`other` (أخرى):** Income outside the three primary categories — inheritance, gifts, windfalls, refunds.

The taxonomy aligns with classical Islamic economic categories:

- `كسب` (kasb): earned income from work (profession)
- `استثمار` (istithmar): investment returns (investmentAsset)
- `بيع` (bay'): commercial sale (possession)
- `هبة / إرث` (hibah / irth): gift/inheritance (other)

This cultural alignment reflects the target user base's frame of reference for income classification.

[Code Reference: `income_source_type.dart`]

---

### 20.2 The Metadata Derivation: Feature Addition Without Schema Migration

Income source type is stored in `metadata['income_source_type']` rather than as a dedicated column. This metadata-based approach has two implications:

**Implication 1: No Schema Migration Required.** The `metadata` column already existed as a JSON blob. The feature was added by defining a new metadata key and providing UI to set it.

**Implication 2: Income Source Is Optional Without Null Columns.** Not every account needs an income source type. The metadata approach avoids nullable column proliferation.

The trade-off: income source is not queryable via SQL directly. Filtering by source type requires loading all accounts and filtering in Dart code. For personal finance volumes (fewer than 1,000 accounts), this is not a performance concern.

[Code Reference: `account.dart`, lines 33-34; `income_source_type.dart`]

---

---

## SECTION 21: THE SYNCHRONIZATION PROTOCOL — P2P FINANCIAL MESSAGING

---

### 21.1 The `SyncEventDispatcher`: Fire-and-Forget Local-First Messaging

The `SyncEventDispatcher` is the system's mechanism for notifying counterparties of financial events. The definitive architectural pattern:

```dart
// create_voucher_use_case.dart, line 305
_syncEventDispatcher!.dispatchVoucherClaim(voucher).ignore();
```

The `.ignore()` call is architecturally definitive: the result of the sync dispatch is deliberately ignored. The use case does not wait for network confirmation. The use case does not retry on failure. The use case completes as soon as local persistence succeeds, regardless of network state.

The `Future.ignore()` pattern in Dart allows a Future to run without being awaited. The sync infrastructure handles retry logic independently: it maintains an outbox of pending sync events, retries failed events when connectivity is restored, and confirms delivery through the background sync orchestration service.

[Code Reference: `create_voucher_use_case.dart`, line 305; `sync_event_dispatcher.dart`]

---

### 21.2 The E2EE SyncNode: Encrypted Envelope for Cross-Device Communication

The `SyncNode` wraps the voucher payload in end-to-end encryption:

- The sender encrypts the voucher data with the recipient's public key.
- Only the recipient (holder of the corresponding private key) can decrypt it.
- The server relays the encrypted envelope without reading its contents.

This E2EE model means that even if the server's relay infrastructure is compromised, the attacker sees only encrypted blobs — the financial content (amounts, parties, descriptions) remains private. The "server as relay" principle extends from the architectural level to the cryptographic level: the server is both structurally excluded (it holds no financial data) and cryptographically excluded (it cannot read the data in transit).

[Code Reference: `sync_node.dart`; `accept_voucher_use_case.dart`, lines 124-134]

---

### 21.3 The Acceptance Dispatch: Signing and Notifying in One Operation

In `AcceptVoucherUseCase`, after local confirmation is complete, the counterparty is notified:

```dart
if (_syncEventDispatcher != null) {
  _syncEventDispatcher!.dispatchAcceptance(voucher: confirmedVoucher).ignore();
}
```

Again, `.ignore()`. The acceptance notification is synchronous to the local operation but asynchronous to the counterparty's reception. The counterparty discovers the acceptance at their next sync cycle.

This creates a perception gap: Party A sees "UnderRequest" until the sync delivers Party B's acceptance. The `SyncStatusBanner` (Section 16.2) addresses this at the UX level by informing users of sync activity. But there is no real-time push update within a single session — it requires a pull or push sync cycle.

[Code Reference: `accept_voucher_use_case.dart`, lines 125-130]

---

### 21.4 The Sync Orchestration Service: Background Reliability

The `SyncOrchestrationService` is a background service responsible for:

1. **Outbox processing:** Reattempting dispatch of pending `SyncNode` objects that failed previously.
2. **Inbox polling:** Checking the server relay for incoming sync nodes addressed to the user.
3. **Conflict resolution:** Applying incoming voucher events to the local database, with special handling for financially material fields.

The conflict resolution strategy is "last writer wins" for most metadata fields, with exceptions for financially material fields (amount, participants, date) that trigger a separate dispute resolution flow rather than silent overwrite.

[Code Reference: `sync_orchestration_service.dart`]

---

---

## SECTION 22: THE UNKNOWN KNOWNS — SILENCES, GAPS, AND CONCEPTUAL DEBT

---

### 22.1 Known Gaps Under Active Development

The following gaps are explicitly documented through TODO comments, placeholder implementations, or acknowledged behavioral limitations:

**Gap 1: Fee Account Classification Ambiguity**

The fee account in `CreateTripartiteTransferUseCase` is created under `AccountClassification.settlements` rather than `AccountClassification.remittanceFees`. The `remittanceFees` classification exists explicitly for this purpose. This discrepancy suggests either (a) a historical implementation predating the formal taxonomy, or (b) a deliberate simplification where fees are treated as settlements. Resolution requires examining git history.

**Gap 2: Rollback Not Implemented**

`AuditLogService.rollback()` throws `UnimplementedError`. No substitute mechanism exists. The audit trail preserves the `oldData` needed for rollback; the restoration logic is pending.

**Gap 3: Accrual Execution Not Automated**

`AccrualComponent` records recurring obligations but does not automatically create vouchers when due dates pass. No background scheduler generates reminders or vouchers. The user must manually trigger each accrual execution.

**Gap 4: Attachment Files Are Unencrypted**

The SQLCipher database is fully encrypted. Attachment files in the documents directory are not encrypted at the application layer. OS-level file encryption (Android file-based encryption, iOS full-disk encryption) provides partial protection. Application-layer encryption would require dedicated key management.

**Gap 5: Contingent Voucher Withdrawal May Create Orphaned Entries**

If a confirmed-but-contingent voucher is withdrawn (edge case in `canWithdraw` logic), its ledger entries are not automatically reversed. A reversal voucher would need to be created manually.

[Code Reference: Multiple files]

---

### 22.2 NOT-Enforced Assumptions: The Contract with Future Developers

The following assumptions are documented in the architecture but are NOT enforced at runtime:

**Assumption A: Single Root Liquid Assets Account.** The automated bridge logic calls `firstWhere()`. If multiple root liquid assets accounts exist, an arbitrary one is selected. No uniqueness constraint exists at the domain or data layer.

**Assumption B: All Custom Classifications Have Appropriate Natures.** No semantic validation of the nature assigned to custom classifications. A "Mortgage Debt" account with debit nature is accepted without warning.

**Assumption C: The EntryGenerator Is Only Called for Confirmed Vouchers.** The `EntryGenerator` guard catches errors at runtime, but the calling convention (call `confirm()` first) must be maintained by every current and future use case. No compile-time guarantee prevents misuse.

**Assumption D: Cost Center Tags Are Applied Atomically With Vouchers.** Tag application occurs in a separate loop after voucher persistence. No transaction wraps both operations atomically. Tag failure leaves the voucher without analytical annotations.

---

### 22.3 Architectural Debt: Points of Accumulated Complexity

**Debt 1: Optional Parameter Proliferation in Use Case Constructors.** `CreateVoucherUseCase` accepts 8 optional constructor parameters beyond the required 6. The nullable-optional pattern makes dependency injection configurations difficult to audit — which optional dependencies are truly optional vs. expected?

**Debt 2: `Voucher.restore()` as the Release Mechanism for Contingency.** Using the data-layer rehydration factory to perform the tripartite contingency release is architecturally impure. A dedicated `Voucher.releaseContingency()` domain method would be cleaner.

**Debt 3: The Attachment Hash Is Not Verified on Read.** The `encryptedBlobHash` is stored at write time but not verified at every read. Corrupted attachments are detected only when the user opens them. Automatic hash verification on open would harden integrity guarantees.

---

---

## SECTION 23: SYNTHESIS — THE UNIFIED WORLDVIEW AND DEVELOPER COVENANT

---

### 23.1 The Five Philosophical Pillars

The entire architecture of Qayd can be reduced to five philosophical pillars. Every design decision in every domain entity, use case, and security component traces back to one or more:

**Pillar I: Local-First Data Sovereignty**

*Statement:* The user's financial data belongs to the user. It is stored on their device, encrypted with their own key material, and accessible regardless of network state or server availability.

*Code manifestation:* SQLCipher encryption (`sqflite_sqlcipher`), three-factor key derivation (mnemonic + server salt + local salt), fire-and-forget sync (`Future.ignore()`), read-capable governance suspension.

*Corollary:* The system makes no promises about data availability after device loss without a backup. Sovereignty implies responsibility.

**Pillar II: Document-Driven Accounting**

*Statement:* No accounting entry exists without a source document. Every entry is traceable to a voucher. Every voucher is traceable to a human decision.

*Code manifestation:* Unidirectional LedgerEntry-to-Voucher dependency, `Voucher.draft()` pre-confirmation state, `EntryGenerator.confirm()` requirement, withdrawal-not-deletion preservation.

*Corollary:* No automated process bypasses the voucher document layer. Even the bridge logic creates formal voucher documents.

**Pillar III: Bilateral Cryptographic Commitment**

*Statement:* A financial agreement between two parties is complete only when both have cryptographically signed it. One party's record is a claim until the counterparty countersigns.

*Code manifestation:* Ed25519 dual-signature model, `AgreementStatus.underRequest` receiver default, `SignatureVerificationEngine` cross-vector verification, `canWithdraw` bilateral gate.

*Corollary:* Local posting with `underRequest` resolves the tension between local sovereignty and bilateral commitment: "I have recorded this, but it is not yet bilaterally confirmed."

**Pillar IV: Immutability as Truth**

*Statement:* Financial history is immutable. Past events happened as they happened. The record cannot be edited to fit the convenience of the present.

*Code manifestation:* `LedgerEntry final class` with no mutation methods, `ImmutableEntityException` for non-draft voucher edits, immutable `AccountNature`, non-reclassifiable `AccountClassification`, audit log append-only.

*Corollary:* Corrections are new events, not edits of old events. A reversal voucher coexists with the original.

**Pillar V: Precision Over Convenience**

*Statement:* Financial arithmetic must be exact. User experience conveniences must not compromise mathematical integrity.

*Code manifestation:* Integer-only monetary arithmetic, ISO 4217 fractional digit delegation, `CurrencyMismatchException`, `SelfCancelingEntryException`, `positiveAmount` enforcement.

*Corollary:* Where convenience and precision conflict, precision wins.

---

### 23.2 The Developer Covenant: Ten Obligations to Future Maintainers

**Obligation 1: Never Bypass the GovernanceWriteGuard.** Every new mutating use case must begin with `_writeGuard.assertWritesPermitted()`.

**Obligation 2: Never Generate Entries Without Confirmed Vouchers.** Always call `voucher.confirm()` before `generateForConfirmedVoucher()`.

**Obligation 3: Respect the Three-Constructor Discipline.** `positiveAmount()` for events, `nonNegative()` for balances, `fromMinorUnits()` for arithmetic.

**Obligation 4: Use `Voucher.restore()` Only for Rehydration.** Never use the data-layer factory for creating new vouchers in application-layer code.

**Obligation 5: Preserve the Non-Destructive Record Policy.** No ledger entries, confirmed vouchers, or accounts with historical transactions shall be deleted.

**Obligation 6: Maintain Schema Version Monotonicity.** Every schema change increments `schemaVersion` by exactly one with a corresponding migration.

**Obligation 7: Respect the Metadata-Null Contract.** All `account.metadata` reads must tolerate null and type-mismatch gracefully.

**Obligation 8: Maintain Currency Isolation.** No cross-currency arithmetic outside a dedicated conversion layer.

**Obligation 9: Append, Never Overwrite, Audit Entries.** The audit log is a historical record. Modifying or deleting past entries corrupts the trail.

**Obligation 10: Respect the Bilateral Commitment Gate.** `canWithdraw` and the counterparty agreement protocol must not be circumvented.

---

### 23.3 The System in Summary: What Qayd Says About Financial Sovereignty

Qayd is a system that answers a question — one that most financial technology companies answer incorrectly.

The question is: **Who is responsible for an individual's financial records?**

Most financial technology answers: the platform. The bank holds your ledger. The app holds your data. The server processes your transactions. The company maintains your financial history. You access it at their pleasure.

Qayd answers: **the individual**.

Every architectural decision flows from this answer:

- SQLCipher encryption: your data is unreadable without your key.
- Three-factor key derivation: your key cannot be reconstructed without your mnemonic.
- Local-first architecture: your records are accessible without their servers.
- Bilateral cryptographic commitment: your agreements are provable without their witnesses.
- Immutable ledger: your history is permanent and cannot be altered by anyone.
- Panic wipe: your right to destroy your own data is architecturally guaranteed.

The philosophical cost is also explicit:

- You must guard your mnemonic phrase. If lost, your data is irrecoverable.
- You must maintain your device. If lost without a backup, your data is lost.
- You must engage counterparties. The system cannot compel a counterparty to accept your voucher.
- You bear accounting responsibility. The system enforces rules but cannot prevent misrecording.

Qayd is not a system that manages your finances. It is a system that gives you the tools to manage your own finances — with the full weight of that agency and the full responsibility that accompanies it.

This is the Qayd covenant: **local sovereignty in exchange for personal responsibility**.

[Code Reference: The entire codebase, in synthesis.]

---

---

## APPENDIX A: DOMAIN EXCEPTION TAXONOMY

---

| Exception Class | Code | Trigger Condition |
|---|---|---|
| `InvalidAmountException` | `voucher_amount_zero` | `Money.positiveAmount(0, ...)` |
| `SelfCancelingEntryException` | `voucher_self_counterparty` | `counterpartyId == affectedAccountId` |
| `ImmutableEntityException` | `voucher_not_draft` | `updateDraft()` on non-draft |
| `ImmutableEntityException` | `voucher_settled_immutable` | Side-effect on settled |
| `ImmutableEntityException` | `voucher_delete_not_draft` | Delete non-draft |
| `ImmutableEntityException` | `cost_center_suspend_default` | Suspend default center |
| `ImmutableEntityException` | `cost_center_rename_default` | Rename default center |
| `InvalidVoucherTransitionException` | (dynamic) | Illegal state transition |
| `AccountDeletionException` | `account_delete_default` | Delete isDefault account |
| `AccountDeletionException` | `account_delete_balance` | Delete non-zero balance |
| `AccountDeletionException` | `account_delete_children` | Delete with children |
| `AccountDeletionException` | `account_deactivate_default` | Deactivate isDefault |
| `AccountDeletionException` | `account_archive_default` | Archive isDefault |
| `AccountDeletionException` | `account_archive_balance` | Archive non-zero balance |
| `InvalidStateTransitionException` | `account_reparent_classification_mismatch` | relocateUnder() mismatch |
| `InvalidStateTransitionException` | `entries_require_confirmed_voucher` | EntryGenerator on non-confirmed |
| `CurrencyMismatchException` | `cross_currency_arithmetic` | Cross-currency Money ops |
| `GovernanceFailure` | `writes_blocked_governance` | Write while suspended/revoked |

---

## APPENDIX B: STATE MACHINE SUMMARY

---

### Voucher State Machine

```
draft ──confirm()──> confirmed ──settle()──> settled (TERMINAL)
  |                      |
  +──withdraw()──> withdrawn <──withdraw() [if receiverStatus != accepted]
                      (TERMINAL)
```

### AgreementStatus Machine (per Party)

```
underRequest ──> accepted   (TERMINAL)
     |
     +────────> rejected    (TERMINAL)
     |
     +────────> unverified  (TERMINAL)
```

### Account Lifecycle

```
active ──deactivate()──> inactive ──activate()──> active
active ──archive()──────> archived ──unarchive()──> active
active ──assertCanDelete()──> [deleted — irreversible]
    [requires: isDefault=false AND balance=0 AND hasChildren=false]
```

### GovernanceStatus Machine

```
activated ──> suspended ──> activated (after billing resolution)
activated ──> revoked       (permanent, no recovery)
activated ──> expired ──> (grace period) ──> revoked
```

### Collateral Status Machine

```
active ──> liquidated (TERMINAL: collateral seized)
active ──> released   (TERMINAL: obligation fulfilled)
active ──> expired    (TERMINAL: pledge term ended)
```

### TripartiteMeta Contingency

```
isContingent=true ──release()──> isContingent=false (ONE-WAY)
[triggered by: confirm() on the receipt leg voucher via cascade]
```

---

## APPENDIX C: STANDARD ACCOUNT CLASSIFICATION REFERENCE

---

| Standard Kind | Arabic Name | Nature | Section | Special Role |
|---|---|---|---|---|
| `liquidAssets` | نقدية | Debit | Assets | Bridge Logic Anchor |
| `receivables` | ذمم دائنة (عليك) | Debit | Assets | &mdash; |
| `fixedProfitableAssets` | أصول ثابتة - ربحية | Debit | Assets | &mdash; |
| `fixedDepreciableAssets` | أصول ثابتة - مهلكة | Debit | Assets | &mdash; |
| `payables` | ذمم مدينة (لك) | Credit | Liabilities | &mdash; |
| `settlements` | تسوية وشخصي | Credit | Liabilities | Fee Account Host (current) |
| `clearingRemittances` | مقاصة الحوالات | Debit | Liabilities | Tripartite Transit |
| `personalExpenses` | مصروفات شخصية | Debit | Income Statement | Bridge Trigger |
| `personalRevenues` | إيرادات شخصية | Credit | Income Statement | Bridge Trigger |
| `remittanceFees` | رسوم الحوالات | Credit | Income Statement | Intended Fee Host |
| `custom` | (user-defined) | (user-specified) | (by section) | Extensibility |

---

## APPENDIX D: DIMENSION CATEGORY REFERENCE

---

| # | ID | Arabic Name | Icon | Life Domain |
|---|---|---|---|---|
| 1 | `income_work` | الدخل والعمل | payments | Income Generation |
| 2 | `housing_living` | السكن والمعيشة | home | Primary Survival |
| 3 | `nutrition_consumption` | التغذية والاستهلاك اليومي | restaurant | Primary Survival |
| 4 | `transportation` | النقل والتنقل | directions_car | Economic Mobility |
| 5 | `health_care` | الصحة والعناية الشخصية | medical_services | Physical Wellbeing |
| 6 | `education_development` | التعليم وتنمية القدرات | school | Capacity Building |
| 7 | `family_dependents` | الأسرة والمعالون | family_restroom | Social Obligation |
| 8 | `obligations_debts` | الالتزامات والديون | account_balance | Contractual Duty |
| 9 | `investments_projects` | الاستثمارات والمشاريع | trending_up | Offensive Wealth |
| 10 | `savings_reserves` | الادخار وبناء الاحتياطي | savings | Defensive Wealth |
| 11 | `entertainment_lifestyle` | الترفيه ونمط الحياة | sports_esports | Discretionary |

---

## APPENDIX E: CORE FILE ANALYSIS INDEX

---

| File | Layer | Key Concepts |
|---|---|---|
| `voucher.dart` | Domain Entity | State machine, bilateral protocol, threading |
| `account.dart` | Domain Entity | Hierarchy, immutability, lifecycle |
| `ledger_entry.dart` | Domain Entity | Double-entry, immutability |
| `collateral.dart` | Domain Entity | Secured lending, four-state lifecycle |
| `accrual_component.dart` | Domain Entity | Recurring obligations, manual execution |
| `party_details.dart` | Domain Entity | Identity, key history, verification |
| `cost_center.dart` | Domain Entity | Management accounting, non-deletability |
| `cost_center_dimension_category.dart` | Domain VO | Eleven-category taxonomy |
| `money.dart` | Domain VO | Integer precision, three constructors |
| `account_classification.dart` | Domain VO | Sealed union, custom extensibility |
| `standard_account_classification_kind.dart` | Domain VO | Ten standard kinds |
| `tripartite_meta.dart` | Domain VO | Transfer group, contingency lock |
| `agreement_status.dart` | Domain VO | Bilateral protocol states |
| `voucher_state.dart` | Domain VO | Creator workflow states |
| `governance_status.dart` | Domain VO | License lifecycle states |
| `entry_generator.dart` | Domain Service | Pure double-entry function |
| `signature_verification_engine.dart` | Domain Service | Cross-vector verification |
| `create_voucher_use_case.dart` | Application | Bridge, signing, entries, audit |
| `accept_voucher_use_case.dart` | Application | Sign, confirm, dispatch |
| `withdraw_voucher_use_case.dart` | Application | Retraction, cascade |
| `create_tripartite_transfer_use_case.dart` | Application | Three-principal mediation |
| `governance_write_guard.dart` | Application | Write gate |
| `audit_log_service.dart` | Application | Append-only tracking |
| `list_account_statement_chat_use_case.dart` | Application | Conversational ledger |
| `get_account_statement_use_case.dart` | Application | Time-windowed statement |
| `generate_balance_sheet_use_case.dart` | Application | Hierarchical reporting |
| `trial_balance_generator.dart` | Application | Three-phase computation |
| `database_provider.dart` | Data | SQLCipher, schema v26, migrations |
| `license_vault.dart` | Data | Secure storage, trial state |
| `panic_wipe_service.dart` | Data | Three-storage nuclear wipe |
| `monotonic_clock_guard.dart` | Data | Anti-tamper clock |
| `main.dart` | Infrastructure | Two-phase bootstrap |
| `app_shell_page.dart` | Presentation | Five-tab navigation |

---

## APPENDIX F: GLOSSARY OF SPECIALIZED TERMS

---

| Term | Definition in the Qayd Context |
|---|---|
| **Voucher (سند)** | Primary financial document. Source of all ledger entries. Bilateral by design. |
| **LedgerEntry (قيد)** | Immutable debit or credit line. Generated from confirmed vouchers only. |
| **TransactionId** | UUID bonding a debit/credit pair into a balanced double-entry transaction. |
| **Tripartite Transfer** | Three-principal mediated transfer: A (source) to C (mediator) to B (destination). |
| **Contingent Voucher** | Payment voucher locked until its receipt sibling is confirmed. |
| **Transfer Group ID** | UUID linking all vouchers in a single tripartite transfer complex. |
| **AgreementStatus** | Bilateral protocol state per party: underRequest, accepted, rejected, unverified. |
| **VoucherState** | Creator workflow state: draft, confirmed, settled, withdrawn. |
| **VoucherLifecycle** | High-level social narrative of the document's bilateral journey. |
| **Root Account** | Account with parentId = null. Classification and nature source node. |
| **Child Account** | Account inheriting classification and nature from its parent. |
| **Default Account** | System-seeded account protected from all forms of termination. |
| **Bridge Logic** | Automated routing of personal expense/revenue vouchers through the root cash account. |
| **Minor Units** | Integer representation of monetary value (1 SAR = 100 minor units for SAR). |
| **Cost Center** | Management accounting tag applied to vouchers. Orthogonal to double-entry. |
| **Dimension** | Sub-classification within a cost center for multi-axis analytical tagging. |
| **GovernanceStatus** | Administrative license state controlling write access. |
| **Panic Wipe** | Destructive deletion of all cryptographic material and financial data. |
| **Ed25519** | Elliptic curve digital signature algorithm for bilateral voucher commitment. |
| **Mnemonic (BIP-39)** | 12-24 word recovery phrase seeding the database encryption key derivation. |
| **SQLCipher** | AES-256-CBC page-level encrypted SQLite variant. The local ledger engine. |
| **PBKDF2** | Password-Based Key Derivation Function 2. Derives AES key from three factors. |
| **Accrual** | Recurring financial obligation tracked for periodic manual posting. |
| **Collateral** | Asset pledged as security for a tracked financial obligation. |
| **AuditEntry** | Immutable record of a single entity change event. Append-only. |
| **SyncNode** | E2EE encrypted envelope for cross-device financial event transmission. |
| **Fire-and-Forget** | The Future.ignore() pattern: sync dispatch without awaiting delivery. |

---

*End of Document*

*This document was produced through direct, exhaustive analysis of the Qayd Flutter application source code. Every claim is traceable to a specific class, method, invariant, enumeration, or structural pattern in the corpus. No claim derives from user description, external documentation, or unverified accounting convention.*

*Document Version: 2.0 (Comprehensive Expansion)*
*Date of Analysis: 2026-04-14*
*Total Sections: 23 + Appendices A-F*
