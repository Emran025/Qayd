# Privacy Policy — Qayd

**Effective Date:** April 2026
**Last Updated:** April 2026

---

## 1. Introduction

This Privacy Policy describes how Qayd ("the Platform," "the Service," "we," or "us") handles information when you use our financial commitment documentation application. It explains what data we can access, what data we cannot access, and what responsibilities fall on you as the user.

Qayd is built on a fundamentally different architecture than most applications. Your financial data is encrypted on your device using keys that only you possess. We operate the infrastructure that routes encrypted messages between users, but we cannot read, inspect, or reconstruct the content of those messages. This Privacy Policy reflects that architectural reality.

We encourage you to read this document carefully. Understanding how your data is protected — and where your own responsibilities lie — is essential to using Qayd safely and effectively.

---

## 2. Information We Cannot Access

The following categories of data are encrypted on your device and are architecturally inaccessible to the Platform. We do not hold the decryption keys, and no employee, system, or process operated by the Platform can read this data.

### 2.1 Your Financial Records

All financial data you create within Qayd — including vouchers, ledger entries, account balances, cost center allocations, transaction descriptions, notes, and tags — is stored in an encrypted database on your device. The encryption key for this database is derived from factors unique to your specific device and is stored in your device's secure hardware enclave. We do not possess this key, and we cannot derive it.

### 2.2 Your Counterparty Information

The identities of the people and organizations you transact with — their names, phone numbers, email addresses, account classifications, and public keys — are stored only in your local encrypted database. We do not maintain a registry of who transacts with whom based on financial content.

### 2.3 Your Cryptographic Identity

Your private signing key, your 24-word recovery phrase, and your derived key pair are generated and stored exclusively on your device. They are never transmitted to our servers. We have no copy of these credentials, no backup of them, and no ability to reconstruct them.

### 2.4 The Content of Synchronized Messages

When you exchange financial records with a counterparty through our synchronization service, the content of those records is encrypted before it leaves your device. Our servers route the encrypted package to your counterparty, but we cannot read its contents. We can see that a message was sent from one user to another; we cannot see what the message says or what financial value it represents.

---

## 3. Information We Do Process

To operate the routing infrastructure and provide the Service, we necessarily process a limited set of operational data. We are transparent about what this includes.

### 3.1 Account Registration Data

When you register, we collect and store:

- Your phone number and/or email address, used for account identification and counterparty discovery.
- Authentication credentials (securely hashed) for verifying your identity when you connect to the Service.

### 3.2 Routing Metadata

When encrypted messages are exchanged through our synchronization service, we process:

- The sender's and receiver's user identifiers (numeric IDs, not names or financial identities).
- The type of synchronization event (e.g., a new claim, an acceptance, a rejection — but not the financial content associated with it).
- Timestamps indicating when messages were sent and delivered.
- Delivery status (pending, delivered, acknowledged).

This metadata is the minimum necessary for message delivery. It tells us routing information — *who sent what category of event to whom, and when* — but reveals nothing about the financial substance of the transaction.

### 3.3 Technical and Diagnostic Data

We may collect standard technical information necessary for maintaining service quality:

- Device type and operating system version (for compatibility purposes).
- Application version.
- Connection status and error logs related to the synchronization service.

This data is used exclusively for diagnosing technical issues and improving service reliability. It does not include any financial content or cryptographic material.

---

## 4. What We Cannot Do

The following limitations are not organizational policies — they are structural consequences of the system's cryptographic architecture. They cannot be overridden by any administrative action, policy change, or legal order directed at the Platform, because we do not possess the technical capability.

**We cannot read your financial data.** Your records are encrypted with keys we do not hold. No employee, automated system, or external party accessing our infrastructure can decrypt your financial content.

**We cannot forge your signature.** Digital signatures are produced using your private key, which exists only on your device. Producing a valid signature requires possession of that key. We have never possessed it.

**We cannot determine the value of your transactions.** The financial amounts, currencies, and descriptions within synchronized messages are encrypted. We can observe that a synchronization event occurred; we cannot determine whether it involves five dollars or five million.

**We cannot alter your records.** Your financial records are protected by cryptographic signatures. Any modification to a signed record — even a change of a single digit — would invalidate the signature and be detectable by any party verifying the record.

**We cannot recover your data.** If you lose your device and your recovery phrase, your encrypted data is permanently inaccessible. We do not maintain backup keys, recovery escrow, or any mechanism to restore access on your behalf.

**We do not profile your financial behavior.** Because we cannot access the substance of your transactions, we cannot build financial profiles, creditworthiness assessments, spending pattern analyses, or any derivative intelligence about your financial activity.

---

## 5. How We Use the Information We Have

The operational data described in Section 3 is used solely for the following purposes:

- **Message routing:** Delivering encrypted synchronization events from sender to receiver.
- **Authentication:** Verifying that users connecting to the synchronization service are who they claim to be.
- **Counterparty discovery:** Enabling users to find each other by phone number or email for the purpose of exchanging cryptographic identities.
- **Service reliability:** Diagnosing and resolving technical issues affecting the routing infrastructure.

We do not use operational data for advertising, marketing, behavioral analysis, financial profiling, or sale to third parties. The data that would enable such activities — the decrypted content of your financial records — is architecturally inaccessible to us.

---

## 6. Data Sharing

### 6.1 We Do Not Sell Your Data

We do not sell, rent, or trade any user data to third parties. This applies to both the operational data we do process and the encrypted content we cannot access.

### 6.2 Legal Requests

If we receive a legal request for user data, we can only provide what we actually possess: account registration information (phone number, email) and routing metadata (message timestamps, delivery status, user identifiers). We cannot provide the content of financial records, because that content is encrypted with keys we do not hold.

We will comply with valid legal process to the extent technically possible, and we will notify affected users where permitted by law. However, compliance is inherently bounded by our architectural limitations: we cannot produce data we do not have.

### 6.3 Service Providers

We may engage third-party service providers for infrastructure operations (hosting, network services). These providers may process routing metadata in the course of delivering the Service, but they have no greater access to encrypted content than we do — which is none.

---

## 7. Data Retention

### 7.1 Routing Metadata

Synchronization event metadata is retained for the duration necessary to ensure reliable message delivery. Once a message is delivered and acknowledged by the recipient's device, the routing record's operational utility is exhausted. Encrypted payloads may be retained temporarily to support delivery reliability for offline recipients, but they reveal no financial content regardless of retention duration.

### 7.2 Account Data

Your registration information (phone number, email, authentication credentials) is retained for as long as your account remains active. Upon account deletion, this information is removed from our systems in accordance with our standard data lifecycle procedures.

### 7.3 Your Local Data

All financial records, cryptographic keys, and identity material stored on your device are under your exclusive control. You may export, back up, or delete this data at any time. The Platform provides a credential destruction feature that permanently and irrevocably eliminates all key material from your device, rendering your encrypted database inaccessible. This action is irreversible, and we cannot undo it.

---

## 8. Data Security

### 8.1 Encryption at Rest

Your financial data is stored in an encrypted database on your device. The encryption uses industry-standard algorithms with a key derived from device-specific factors and stored in your device's hardware-backed secure enclave.

### 8.2 Encryption in Transit

Financial data synchronized between users is encrypted end-to-end before leaving the sending device. The synchronization channel itself is secured via authenticated WebSocket connections over TLS, providing an additional transport-layer encryption envelope around the already-encrypted content.

### 8.3 Signature Integrity

Every signed financial record carries a cryptographic digital signature that enables any holder of the signer's public key to independently verify the record's authenticity and detect any tampering. This verification can be performed offline, without any involvement from the Platform.

### 8.4 Infrastructure Security

We implement reasonable administrative, technical, and physical safeguards to protect our routing infrastructure against unauthorized access, disruption, and misuse. However, because user financial data is encrypted with keys we do not possess, a breach of our infrastructure would not expose the financial content of any user's records.

---

## 9. Your Rights and Controls

### 9.1 Access to Your Data

Your financial data resides on your device. You have direct, immediate access to it through the application at all times, without needing to request it from us — because we do not hold it.

### 9.2 Data Portability

You may export your financial records in multiple standard formats (PDF, Excel) at any time through the application's export functionality. These exports are generated locally on your device from your decrypted data.

### 9.3 Data Deletion

You may delete your local data at any time by using the application's credential destruction feature or by uninstalling the application. You may request deletion of your server-side account data (registration information, routing metadata) by contacting us through the in-application support channel.

### 9.4 Correction

Because we cannot access your financial records, we cannot correct them on your behalf. Record corrections are made by you, within the application, through the creation of new signed correction or reversal entries — preserving the original record as part of the audit trail.

---

## 10. Children's Privacy

Qayd is not directed at individuals under the age of 18 (or the age of legal majority in the applicable jurisdiction). We do not knowingly collect personal information from children. If we become aware that a child has created an account, we will take steps to delete the associated account data from our servers.

---

## 11. Offline and Alternative Channels

Qayd supports the exchange of signed financial records through channels that do not involve our servers, including QR codes, SMS messages, and direct peer-to-peer device connections. When you use these channels:

- Your financial records are protected by the same cryptographic signatures used in server-mediated exchanges.
- The Platform does not process, route, or have visibility into records exchanged through offline channels.
- The privacy guarantees described in this Policy apply equally to records created, signed, and exchanged entirely offline.

---

## 12. Future Ecosystem Context

Qayd is architected as a foundational component within a planned expansion of the Accsystem enterprise accounting ecosystem. This architectural relationship is designed to enable future structural compatibility between Qayd's financial records and Accsystem's institutional accounting platform.

This relationship is relevant to your privacy in the following specific ways:

**What does not change:** The end-to-end encryption of your financial data, the exclusive custody of your cryptographic keys on your device, and the Platform's inability to access your financial content remain unchanged regardless of any ecosystem integration. Future interoperability does not introduce shared key custody, server-side decryption, or cross-platform access to encrypted data.

**How integration works:** Any future data exchange between Qayd and Accsystem will operate through user-initiated, device-local export operations. You choose what to export, your device performs the decryption and formatting, and you control the transmission. No automated server-to-server pipeline will access your encrypted data without your explicit action on your device.

**Separate responsibility:** Qayd and Accsystem maintain separate data handling obligations. The privacy guarantees described in this Policy are specific to the Qayd platform and are not contingent on, limited by, or shared with any other platform or service within the ecosystem.

---

## 13. Changes to This Policy

We may update this Privacy Policy from time to time to reflect changes in our practices, technology, or legal requirements. Material changes will be communicated through the application or other reasonable means prior to taking effect.

No update to this Privacy Policy can alter the structural properties of the encryption architecture. Our inability to access your encrypted financial data is a property of the system's design, not a policy commitment, and it persists regardless of any future revision to this document.

---

## 14. Contact

If you have questions or concerns about this Privacy Policy or your data, you may reach us through the in-application support channel or at the contact information provided within the application's settings.

---

*Your privacy in Qayd is not protected by a promise. It is protected by mathematics.*
