class PrivacyProfile {
  const PrivacyProfile({
    required this.key,
    required this.name,
    required this.description,
    required this.entities,
    this.threshold = 0.35,
  });

  final String key;
  final String name;
  final String description;
  final List<String> entities;
  final double threshold;
}

class ProtectionScope {
  const ProtectionScope(this.key, this.name, this.description);

  final String key;
  final String name;
  final String description;
}

const defaultProfileKey = 'general_business';
const defaultScopeKey = 'maximum';

const commonUsEntities = <String>[
  'PERSON',
  'EMAIL_ADDRESS',
  'PHONE_NUMBER',
  'LOCATION',
  'US_SSN',
  'US_ITIN',
  'US_DRIVER_LICENSE',
  'US_PASSPORT',
  'US_BANK_NUMBER',
  'CREDIT_CARD',
  'IP_ADDRESS',
  'DATE_OF_BIRTH',
  'STREET_ADDRESS',
  'POSTAL_CODE',
];

const financialSensitiveEntities = <String>[
  'US_BANK_NUMBER',
  'US_ROUTING_NUMBER',
  'SWIFT_BIC',
  'IBAN_CODE',
  'CRYPTO',
  'CARD_LAST_FOUR',
  'CARD_TRANSACTION_ID',
  'TRANSFER_TRANSACTION_ID',
  'TRANSACTION_ID',
  'STATEMENT_REFERENCE',
  'MONEY_AMOUNT',
  'MERCHANT',
  'COUNTERPARTY',
  'TRANSACTION_REFERENCE',
  'BUSINESS_REGISTRATION_NUMBER',
];

const businessConfidentialEntities = <String>[
  'ORGANIZATION',
  'URL',
  'BUSINESS_REGISTRATION_NUMBER',
  'INVOICE_NUMBER',
  'PURCHASE_ORDER_ID',
  'CONTRACT_ID',
  'CUSTOMER_ID',
  'EMPLOYEE_ID',
  'CASE_REFERENCE',
];

const technicalSecretEntities = <String>[
  'API_KEY',
  'ACCESS_TOKEN',
  'JWT_TOKEN',
  'OAUTH_SECRET',
  'CLOUD_CREDENTIAL',
  'DATABASE_CREDENTIAL',
  'WEBHOOK_SECRET',
  'PRIVATE_KEY',
  'MAC_ADDRESS',
];

const operationalIdentifierEntities = <String>[
  'US_ROUTING_NUMBER',
  'TENANT_ID',
  'LEASE_ID',
  'NYC_BBL',
  'NYC_BIN',
  'VENDOR_ACCOUNT_ID',
  'WORK_ORDER_ID',
  'PROPOSAL_ID',
  'INSURANCE_POLICY_ID',
  'PREAPPROVAL_ID',
  'MORTGAGE_REFERENCE',
  'US_EIN',
  'PROPERTY_IDENTIFIER',
  'UNIT_NUMBER',
  'PROPERTY_ACCESS_CODE',
  'LOCKBOX_CODE',
  'CONTRACTOR_LICENSE',
  'INSURANCE_CLAIM_ID',
  'UTILITY_ACCOUNT_ID',
  'LOAN_NUMBER',
  'TRANSACTION_ID',
];

const realEstateSensitiveEntities = <String>[
  'SECURITY_CODE',
  'UTILITY_METER_ID',
  'HOUSING_ASSISTANCE_ID',
  'LEASE_OCCUPANCY_DATE',
  'RENT_AMOUNT',
  'TENANT_BALANCE',
  'SECURITY_DEPOSIT_AMOUNT',
  'OWNER_DISTRIBUTION',
  'OPERATING_BALANCE',
  'RESERVE_BALANCE',
  'NOI_AMOUNT',
  'CAPEX_BUDGET_AMOUNT',
  'REMAINING_CAPITAL_BUDGET',
  'CONTINGENCY_AMOUNT',
  'CONTRACTOR_BID_AMOUNT',
  'CHANGE_ORDER_AMOUNT',
  'INVOICE_AMOUNT',
  'PURCHASE_ORDER_VALUE',
  'OFFER_PRICE',
  'PURCHASE_PRICE',
  'EARNEST_MONEY_AMOUNT',
  'BROKER_COMMISSION',
  'CLOSING_CREDIT',
  'ESCROW_AMOUNT',
  'MANAGEMENT_FEE',
  'CASE_REFERENCE',
  'MAINTENANCE_TICKET_ID',
  'PROJECT_JOB_CODE',
  'KEY_ACCESS_INSTRUCTION',
  'HOUSING_LEGAL_CASE_ID',
  'NYC_DOB_JOB_ID',
  'NYC_HPD_RECORD_ID',
  'INSPECTION_ACCESS_WINDOW',
  'VACANCY_OCCUPANCY_DATE',
  'APPROVAL_AUTH_CODE',
  'CARD_SECURITY_CODE',
  'PAYMENT_TOKEN',
  'ACH_AUTHORIZATION_ID',
  'WIRE_CONFIRMATION_ID',
  'WIFI_CREDENTIAL',
  'PASSWORD_CREDENTIAL',
  'PORTAL_USERNAME',
  'AUTH_SESSION_ID',
  'DEVICE_FINGERPRINT',
  'MFA_RECOVERY_CODE',
  'SAFE_COMBINATION',
  'APPLICATION_ID',
  'SCREENING_REFERENCE',
  'CREDIT_SCORE',
  'TENANT_INCOME_AMOUNT',
  'HOUSING_ASSISTANCE_AMOUNT',
  'VEHICLE_LICENSE_PLATE',
  'RENT_CONCESSION_AMOUNT',
  'PAYMENT_PLAN_AMOUNT',
  'LATE_FEE_AMOUNT',
  'PROPERTY_TAX_AMOUNT',
  'INSURANCE_PREMIUM_AMOUNT',
  'LOAN_AMOUNT',
  'LOAN_BALANCE',
  'DEBT_SERVICE_AMOUNT',
  'INTEREST_RATE',
  'LTV_RATIO',
  'PREAPPROVAL_AMOUNT',
  'CASH_TO_CLOSE',
  'CLOSING_COST_AMOUNT',
  'BUYER_BUDGET_AMOUNT',
  'SELLER_NET_PROCEEDS',
  'NEGOTIATION_LIMIT_AMOUNT',
  'INTERNAL_VALUATION_AMOUNT',
  'PROJECT_BUDGET_AMOUNT',
  'RETAINAGE_AMOUNT',
  'PAY_APPLICATION_AMOUNT',
  'SUBCONTRACT_AMOUNT',
  'LABOR_RATE',
  'MATERIAL_ALLOWANCE_AMOUNT',
  'PERMIT_ID',
  'LIEN_WAIVER_ID',
  'COI_REFERENCE',
  'INSURANCE_CLAIM_AMOUNT',
  'INSURANCE_DEDUCTIBLE_AMOUNT',
  'TITLE_FILE_ID',
  'LISTING_AGREEMENT_ID',
  'ACCOUNTS_PAYABLE_AMOUNT',
  'COMMITTED_COST_AMOUNT',
];

List<String> _mergeEntities(List<List<String>> groups) {
  final seen = <String>{};
  final merged = <String>[];
  for (final group in groups) {
    for (final entity in group) {
      if (seen.add(entity)) {
        merged.add(entity);
      }
    }
  }
  return List.unmodifiable(merged);
}

final generalCoreEntities = _mergeEntities([
  commonUsEntities,
  financialSensitiveEntities,
  businessConfidentialEntities,
  technicalSecretEntities,
  const ['US_EIN', 'DATE_TIME'],
]);

final scopes = <ProtectionScope>[
  const ProtectionScope(
    'essential',
    'Essential PII',
    'Identity, contact, government IDs, addresses and payment credentials.',
  ),
  const ProtectionScope(
    'financial',
    'PII + Financial',
    'Adds accounts, transaction IDs, card endings, amounts, merchants and references.',
  ),
  const ProtectionScope(
    'business',
    'PII + Business Confidential',
    'Adds company, property, contract, project and operational identifiers.',
  ),
  const ProtectionScope(
    'maximum',
    'Maximum Protection',
    'Scans every sensitive category available in PrivacyGate, across the core and installed profile packs.',
  ),
  const ProtectionScope(
    'custom',
    'Custom Review',
    'Scans every category enabled by the selected profile, then lets you choose exactly what to protect.',
  ),
];

final profiles = <PrivacyProfile>[
  PrivacyProfile(
    key: 'general_business',
    name: 'General — Recommended',
    description: 'Recommended default for most documents: identity, contact, financial, organization, contract, customer and general business data.',
    entities: generalCoreEntities,
  ),
  PrivacyProfile(
    key: 'property_management',
    name: 'Property Management',
    description: 'General protection plus tenant, owner, vendor, property, lease, building-access and real-estate financial data.',
    entities: _mergeEntities([
      generalCoreEntities,
      operationalIdentifierEntities,
      realEstateSensitiveEntities,
    ]),
  ),
  PrivacyProfile(
    key: 'realtor_brokerage',
    name: 'Realtor / Brokerage',
    description: 'General protection plus client, transaction, brokerage, property, offer and closing-sensitive data.',
    entities: _mergeEntities([
      generalCoreEntities,
      operationalIdentifierEntities,
      realEstateSensitiveEntities,
    ]),
  ),
  PrivacyProfile(
    key: 'projects_renovations',
    name: 'Projects & Renovations',
    description: 'General protection plus owner, contractor, subcontractor, project, budget, permit and site-access data.',
    entities: _mergeEntities([
      generalCoreEntities,
      operationalIdentifierEntities,
      realEstateSensitiveEntities,
    ]),
  ),
  PrivacyProfile(
    key: 'construction',
    name: 'Construction',
    description: 'General protection plus owner, contractor, vendor, project, permit, insurance and construction-financial identifiers.',
    entities: _mergeEntities([
      generalCoreEntities,
      operationalIdentifierEntities,
      realEstateSensitiveEntities,
    ]),
  ),
  PrivacyProfile(
    key: 'legal',
    name: 'Legal',
    description: 'General protection plus case, contract and operational identifiers commonly present in legal documents.',
    entities: _mergeEntities([
      generalCoreEntities,
      operationalIdentifierEntities,
    ]),
  ),
  PrivacyProfile(
    key: 'healthcare_general',
    name: 'Healthcare — General Privacy',
    description: 'General identity/contact/business privacy for healthcare documents; not a substitute for a specialized clinical/HIPAA recognizer pack.',
    entities: generalCoreEntities,
  ),
];

PrivacyProfile getProfile(String key) =>
    profiles.firstWhere((profile) => profile.key == key);

ProtectionScope getScope(String key) =>
    scopes.firstWhere((scope) => scope.key == key);

List<String> allProfileEntities() => _mergeEntities(
      profiles.map((profile) => profile.entities).toList(growable: false),
    );

List<String> entitiesForScope(PrivacyProfile profile, String scopeKey) {
  if (scopeKey == 'maximum') {
    return allProfileEntities();
  }
  if (scopeKey == 'custom') {
    return List.unmodifiable(profile.entities);
  }

  final allowed = switch (scopeKey) {
    'essential' => <String>{...commonUsEntities, ...realEstateSensitiveEntities},
    'financial' => <String>{
        ...commonUsEntities,
        ...financialSensitiveEntities,
        ...realEstateSensitiveEntities,
      },
    'business' => <String>{
        ...commonUsEntities,
        ...operationalIdentifierEntities,
        ...businessConfidentialEntities,
        ...realEstateSensitiveEntities,
      },
    _ => throw ArgumentError.value(scopeKey, 'scopeKey', 'Unknown protection scope'),
  };

  return List.unmodifiable(
    profile.entities.where(allowed.contains),
  );
}
