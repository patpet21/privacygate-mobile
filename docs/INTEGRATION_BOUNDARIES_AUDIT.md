# Desktop Integration Boundaries Audit

Audit source: `patpet21/ai-pm-lab-privacy-gate@754f412596c7f32f04c3f50714dcd064704a3f13`.

Status: first Gmail / Drive / MCP compatibility pass complete.

## 1. Integration principle already present in Desktop

Desktop source integrations are intentionally separated from the canonical Protect engine.

Gmail and Google Drive adapters do not implement protection themselves. They turn already-local content into the generic `ProtectPackage` / `ProtectSource` contract consumed by `ProtectSessionService`.

This is the correct pattern for Mobile: platform-specific acquisition changes, but protection semantics stay shared.

## 2. Gmail adapter

`gmail_protect_sources.py` converts:

- email body -> in-memory text source with key `gmail_body`;
- each already-materialized attachment -> local file source with key `gmail_attachment_<index>`.

The adapter deliberately contains no Gmail API calls, Qt/UI state, protection logic or persistence.

Message/attachment content is not copied into package metadata. Package metadata carries provenance such as provider/account/item identity when available.

### Mobile consequence

Mobile Gmail access can arrive through a Workspace add-on, Android/iOS share flow, or future connector, but once the content is local it should normalize to the same generic source package rather than creating a Gmail-specific protection engine.

## 3. Google Drive adapter

`google_drive_protect_sources.py` requires explicit `google_drive` provenance and converts an already-local Drive working copy into a generic file source. Optional pasted text can participate as a second independent source.

A mixed Drive + pasted-text package therefore naturally uses the existing multi-source namespacing behavior.

### Mobile consequence

Drive browsing/download and Mobile file-provider integration are acquisition concerns. The local materialized file should enter the same shared Protect contract.

## 4. Source metadata is provenance, not vault content

Both integrations preserve enough provider/account/item metadata for Library organization, but sensitive content is kept in the actual local source rather than copied into generic metadata.

Mobile should follow the same rule. Connector metadata must not become an accidental channel for message bodies, attachment contents, mappings or credentials.

## 5. MCP is intentionally protected-only

The current MCP server reads from `ProtectedLibraryRepository`, not the restore-capable Personal Library tables.

Its tools can:

- report protected-library status;
- list protected document metadata;
- search protected copies;
- return protected text pages/resources.

The MCP contract explicitly reports/guarantees:

- no access to original PII;
- no access to restore mappings;
- no Library modification;
- read-only protected copies only.

This boundary must remain true when Mobile-created sessions later synchronize into Desktop.

## 6. Mobile does not need a second MCP vault

When a Mobile-created protected artifact is synchronized to Desktop and is eligible/approved for MCP sharing, Desktop can publish its protected projection through the existing protected-only Library architecture.

Mobile does not need to expose its full Mobile Vault to MCP. In particular, full offline mappings should never become MCP-readable merely because their protected artifact is synchronized.

## 7. Local MCP server is also localhost-only

The current HTTP MCP server rejects non-localhost bind addresses. Remote MCP is implemented separately through the remote/tunnel/provisioning architecture.

This reinforces the Mobile connection decision: do not repurpose local MCP or browser HTTP listeners as LAN sync endpoints. Build a dedicated paired-device sync surface.

## 8. Remote MCP infrastructure is separate from Mobile sync

Production MCP provisioning includes device identity, named-tunnel configuration and Supabase OAuth validation. That is an authenticated AI/tool remote-access architecture.

It is useful evidence for secure device identity and remote transport practices, but it does not imply that Mobile sync must use Supabase, the same OAuth model or the same tunnel.

A future Mobile relay should remain a separate transport decision and preserve the portable session/object contract.

## 9. Mobile integration order

The clean implementation sequence is:

```text
OS/app source acquisition
  -> local materialization
  -> generic ProtectPackage / source contract
  -> shared PrivacyGate detection/review/protect
  -> Mobile Vault / protected artifact
  -> optional sync to Desktop
  -> optional Desktop MCP protected projection
```

This keeps Gmail, Drive, Files, Share extensions and camera import from fragmenting PrivacyGate behavior.

## 10. Compatibility tests

Required integration fixtures include:

- Gmail body only;
- Gmail body + multiple attachments;
- Drive document only;
- Drive document + pasted text;
- source keys preserved for multi-source namespaces;
- no content/mapping copied into provenance metadata;
- Mobile-created artifact synchronized to Desktop and exposed to MCP only as protected content;
- full Mobile RestoreBundle remains absent from MCP-readable storage;
- disabling MCP share withdraws the protected projection without deleting the Master Vault item.

## Decision

Desktop already has the integration architecture Mobile needs: source-specific acquisition adapters feeding one generic protection engine, followed by a strictly protected-only MCP projection. Mobile should preserve that separation rather than rebuilding Gmail/Drive/MCP-specific protection logic.
