# Desktop Profiles and Entity Compatibility Audit

Audit source: `patpet21/ai-pm-lab-privacy-gate` at `754f412596c7f32f04c3f50714dcd064704a3f13`.

Status: first compatibility pass complete. The exact recognizer implementation remains Desktop/Python-specific; profile keys, entity names, scope semantics, language choices and compatibility fixtures are cross-platform contracts.

## 1. Current profile keys are product identifiers

The Desktop currently defines these profile keys:

- `general_business` — default / recommended;
- `property_management`;
- `realtor_brokerage`;
- `projects_renovations`;
- `construction`;
- `legal`;
- `healthcare_general`.

The default profile key is `general_business`.

These keys should be treated as stable compatibility identifiers rather than UI labels. Android/iOS may present labels differently but must not silently rename a serialized profile key.

## 2. Current protection scopes

The Desktop currently defines:

- `essential` — Essential PII;
- `financial` — PII + Financial;
- `business` — PII + Business Confidential;
- `maximum` — Maximum Protection;
- `custom` — Custom Review.

The default scope is `maximum`.

Scope semantics are not just UI filters. `entities_for_scope()` selects a stable ordered subset. `maximum` is explicitly product-wide: it returns the deduplicated union of every installed profile pack, not merely the current profile's entity tuple.

This behavior must be reproduced by the shared Mobile contract.

## 3. Entity families

Desktop groups entity identifiers into several canonical families.

### Common US / contact / identity

Includes identifiers such as:

`PERSON`, `EMAIL_ADDRESS`, `PHONE_NUMBER`, `LOCATION`, `US_SSN`, `US_ITIN`, `US_DRIVER_LICENSE`, `US_PASSPORT`, `US_BANK_NUMBER`, `CREDIT_CARD`, `IP_ADDRESS`, `DATE_OF_BIRTH`, `STREET_ADDRESS`, `POSTAL_CODE`.

### Financial sensitive

Includes bank/routing/SWIFT/IBAN/crypto/card/transaction/reference/money/merchant/counterparty and business-registration entities.

### Business confidential

Includes `ORGANIZATION`, `URL`, business registration, invoice, purchase-order, contract, customer, employee and case-reference identifiers.

### Technical secrets

Includes `API_KEY`, `ACCESS_TOKEN`, `JWT_TOKEN`, `OAUTH_SECRET`, `CLOUD_CREDENTIAL`, `DATABASE_CREDENTIAL`, `WEBHOOK_SECRET`, `PRIVATE_KEY`, `MAC_ADDRESS`.

### Operational identifiers

Includes tenant/lease/property/building/vendor/work-order/proposal/insurance/mortgage/EIN/unit/access/lockbox/contractor/utility/loan/transaction identifiers.

### Real-estate sensitive pack

The installed pack is extensive and includes real-estate amounts, project/construction amounts, access/security credentials, approvals/payment identifiers, housing/screening identifiers, occupancy dates, loan/closing figures, permits, lien/COI/title/listing identifiers and other property/project operational data.

The exact strings in `domain/profiles.py` are the authoritative entity identifiers for this audited release.

## 4. Profile composition

`general_business` uses the general core.

`property_management`, `realtor_brokerage`, `projects_renovations`, and `construction` combine the general core with operational identifiers and the real-estate sensitive pack.

`legal` combines the general core with operational identifiers.

`healthcare_general` currently uses the general core and explicitly states that it is not a specialized clinical/HIPAA recognizer pack.

This distinction must remain visible in Mobile. Mobile should not imply clinical-specialist coverage that the audited Desktop does not provide.

## 5. Detection language contract

The current local detector supports two canonical document-language codes:

- `en` — English, Desktop model `en_core_web_sm`;
- `it` — Italiano, Desktop model `xx_ent_wiki_sm`.

English is the default.

Language aliases normalize to those two codes. Unsupported language values fail rather than silently falling back.

The exact spaCy model names are Desktop runtime details, not necessarily Mobile requirements. The cross-platform contract is language code + observable detection behavior/fixtures.

## 6. Detector architecture is layered

Desktop detection is not simply stock Presidio.

For English, the registry installs multiple PrivacyGate layers including:

- universal sensitive recognizers;
- address v2;
- safe-recall rules;
- semantic-context rules;
- residual cleanup;
- technical-secret recognizers;
- real-estate recognizers;
- real-estate sensitive pack.

Additional English guardrails filter NER/context false positives and prefer more specific entities when a generic entity overlaps a more specific PrivacyGate category.

For Italian, a separate recognizer pack includes Italian-specific contact/address/business/date/amount/cadastral/contextual behavior and Italian guardrails/propagation.

Therefore a Mobile port that only runs a generic NER model would not be PrivacyGate-compatible.

## 7. Threshold and overlap behavior

`PrivacyProfile.threshold` currently defaults to `0.35`.

The Presidio adapter requests only entities supported by the installed language runtime and applies the profile threshold. PrivacyGate then applies language-specific cleanup and overlap resolution.

Protected-token spans are excluded from re-detection so PrivacyGate tokens and `[REDACTED]` output are not treated as fresh PII findings.

This observable behavior belongs in compatibility fixtures even if Mobile uses a different detector implementation.

## 8. Compatibility strategy

Do not attempt to embed Python Presidio/spaCy directly as the required Mobile architecture.

Instead split the contract into:

```text
Shared product contract
  profile keys
  scope keys
  entity identifiers
  entity grouping/order
  language codes
  selection semantics
  expected fixture outputs

Platform detector implementation
  Desktop: Presidio + spaCy + PrivacyGate recognizers/guardrails
  Mobile: cross-platform/native detector stack + ported deterministic rules
```

The product is compatible when the same fixtures produce equivalent PrivacyGate findings and protection decisions, not when both platforms happen to use the same ML library.

## 9. What should become shared data

The following should eventually be exported into a versioned shared compatibility package/configuration rather than duplicated manually in Dart/Kotlin/Swift:

- profile definitions;
- scope definitions;
- canonical entity IDs;
- entity-family membership;
- user-facing labels/descriptions where suitable;
- compatibility schema version;
- deterministic recognizer rules that can be represented safely as data;
- golden input/output fixtures.

Complex guardrails that are executable logic can be ported separately but must be covered by the same golden fixtures.

## 10. Required fixture groups

Before Mobile detector acceptance, build fixtures for:

- repeated PERSON/email/phone/location values;
- street/postal/address ambiguity;
- US government IDs;
- banking/routing/IBAN/card/transaction data;
- organization/customer/contract/invoice/work-order IDs;
- technical secrets and tokens;
- property/tenant/lease/building/access identifiers;
- real-estate/project/construction amounts;
- generic-vs-specific overlap cases;
- false-positive guardrails;
- English and Italian equivalents;
- already-protected PrivacyGate tokens;
- every protection scope under representative profiles.

## Decision

Profile keys, scope semantics, entity identifiers and language behavior are part of the cross-platform PrivacyGate contract. Presidio/spaCy are Desktop implementation details. Mobile must match the product behavior through shared configuration and compatibility tests, not by blindly copying the Python runtime.
