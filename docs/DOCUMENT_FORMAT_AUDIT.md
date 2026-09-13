# Desktop Document Format Audit for Mobile Compatibility

Audit source: `patpet21/ai-pm-lab-privacy-gate@754f412596c7f32f04c3f50714dcd064704a3f13`.

Status: first format-level compatibility pass complete.

## 1. Current Desktop supported formats

The canonical `DocumentPipelineService` currently routes:

- PDF `.pdf`
- Word `.docx`
- Excel `.xlsx`
- PowerPoint `.pptx`
- text `.txt`
- CSV `.csv`
- PNG `.png`
- JPEG `.jpg` / `.jpeg`

This is the current product capability inventory for the audited release. Mobile does not need to use the same Python libraries, but format support should be tracked explicitly against this set.

## 2. Common application contract

Every format is normalized into `AnalysisDocument` / `PageContent` so the same PrivacyGate detector and Protect logic can operate over extracted text.

Output is routed back through the format-specific writer. The cross-platform contract is therefore:

```text
source file
  -> deterministic extracted segments/text
  -> PrivacyGate findings/protection
  -> protected spans/tokens
  -> safe protected output
```

Mobile can replace the parser/writer libraries while preserving these semantics.

## 3. PDF

Desktop PDF extraction uses selectable PDF text. Password-protected PDFs are not supported in the current build.

The layout-preserving protected output is deliberately rasterized locally before PrivacyGate replacements are painted. This removes the original selectable text rather than drawing a cosmetic rectangle over recoverable source text.

Before export, every selected finding must be safely located in the source page. If one cannot be resolved, export fails rather than silently leaking the original value.

### Mobile consequence

PDF protection is a safety-sensitive reimplementation task, not just string replacement. The Mobile implementation must either:

- provide equivalent secure layout-preserving output; or
- explicitly use a safer simplified protected PDF representation until layout-preserving behavior passes compatibility/security tests.

Never ship a visual-overlay-only PDF redaction that leaves the original text extractable underneath.

## 4. Scanned/image-only PDFs

The current core PDF analysis still depends on selectable text. `PrivacyGateService.analyze()` fails when the extracted document has no text and reports that scanned/image-only PDFs are not supported in that path.

This is distinct from standalone image OCR support.

### Mobile consequence

Do not claim scanned-PDF parity in the first Mobile release unless a dedicated page-render/OCR pipeline is implemented and tested. Standalone camera/image OCR can arrive before scanned-PDF OCR.

## 5. Standalone image OCR

Desktop currently supports PNG/JPG/JPEG OCR using a local RapidOCR engine.

The image service retains text geometry. During protection, selected findings are mapped back to OCR word/line polygons and pixels are physically painted with protected labels. If every selected finding cannot be mapped back to pixels, export fails.

The protected raster is freshly written and source EXIF/metadata is intentionally dropped to reduce location/device metadata leakage.

Handwriting is explicitly not supported in the current image OCR version.

### Mobile consequence

Mobile camera/image support can use Android/iOS-native OCR if desirable, but must retain enough geometry to perform real pixel-level protection and must strip unsafe metadata from protected exports.

## 6. Word `.docx`

Desktop treats editable paragraphs, tables, headers and footers as deterministic analysis segments.

On export it reopens the source, verifies that the traversed text still matches what was scanned, and aborts if the source changed. It then writes replacements back into a protected copy while attempting to preserve runs/styles and document structure.

### Mobile consequence

Source-change detection is a product safety behavior and should survive even if the Mobile Office implementation differs.

## 7. Excel `.xlsx`

Desktop traverses cell values and comments. It preserves workbook structure where possible.

If selected sensitive data occurs inside a formula, privacy takes precedence: the safe copy may replace the formula with protected content rather than preserving an executable formula that contains PII.

Source content is verified before write-back.

### Mobile consequence

Spreadsheet compatibility is more than reading visible cells. Formula/comment behavior and source-change checks require explicit tests. This can be a later file phase rather than blocking the first text/PDF Mobile MVP.

## 8. PowerPoint `.pptx`

Desktop extracts editable text from shapes, groups, tables and existing notes. It avoids creating notes slides merely by scanning.

On export it verifies that the presentation text is unchanged since scanning, replaces selected ranges, and saves a protected deck while resetting core author/modified-by metadata to PrivacyGate values.

### Mobile consequence

PPTX can be deferred until the shared core is stable, but when implemented it needs deterministic traversal and source-change protection rather than a generic text dump.

## 9. Text and CSV

Desktop supports `.txt` and `.csv` as one local text analysis document.

It decodes UTF-8 BOM, UTF-8 and UTF-16 in order, with a replacement fallback. Protected output is written as UTF-8. CSV write-back uses bytes to avoid newline translation corruption.

### Mobile consequence

These are low-complexity formats and good early compatibility targets after paste/text. They can provide file-workflow testing before Office formats.

## 10. Recommended Mobile format order

For implementation risk, not marketing priority:

1. pasted/typed text;
2. `.txt` / `.csv`;
3. standalone PNG/JPG camera/image OCR;
4. selectable-text PDF with a safe protected-output strategy;
5. DOCX;
6. XLSX;
7. PPTX;
8. scanned-PDF OCR after its own security/geometry tests.

This order does not remove any Desktop capability from the parity checklist. It only sequences Mobile implementation by security and library complexity.

## 11. Cross-platform compatibility tests

Each format needs fixtures proving at minimum:

- extracted sensitive values resolve to the same canonical entity IDs;
- user selection results in compatible placeholders/mappings;
- every selected value is removed from the safe output;
- source-change detection fails safely where applicable;
- the output does not retain recoverable originals in hidden text/metadata;
- protected artifacts remain restorable through the corresponding full session mapping where restore is supported;
- Android and iOS produce equivalent PrivacyGate semantics even when native parsing/OCR libraries differ.

## Decision

The Desktop format layer is strongly platform-specific and should be reimplemented on Mobile. The reusable contract is the normalized text/segment model, finding/placeholder/mapping semantics, fail-closed safety behavior, and expected protected-output properties — not the Python document libraries themselves.
