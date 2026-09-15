import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/domain/page_content.dart';
import 'package:privacygate/core/domain/protected_span.dart';
import 'package:privacygate/core/domain/protection_result.dart';

void main() {
  test('contract: combined text and spans follow Desktop page model', () {
    const firstText = 'A [[PG_PERSON_001]]';
    const secondText = 'B [[PG_EMAIL_ADDRESS_001]]';
    const firstSpan = ProtectedSpan(
      pageNumber: 1,
      start: 2,
      end: 19,
      entityType: 'PERSON',
      findingId: 'person-1',
      replacementText: '[[PG_PERSON_001]]',
    );
    const secondSpan = ProtectedSpan(
      pageNumber: 2,
      start: 2,
      end: 26,
      entityType: 'EMAIL_ADDRESS',
      findingId: 'email-1',
      replacementText: '[[PG_EMAIL_ADDRESS_001]]',
    );
    const result = ProtectionResult(
      protectedPages: [
        PageContent(pageNumber: 1, text: firstText),
        PageContent(pageNumber: 2, text: secondText),
      ],
      protectedSpans: [firstSpan, secondSpan],
    );

    expect(
      result.combinedText,
      '--- Page 1 ---\n$firstText\n\n--- Page 2 ---\n$secondText',
    );
    expect(result.protectedText, result.combinedText);
    expect(result.replacementMode, 'reversible');

    final combined = result.combinedSpans;
    final firstPageOffset = '--- Page 1 ---\n'.length;
    final secondPageOffset =
        firstPageOffset + firstText.length + 2 + '--- Page 2 ---\n'.length;
    expect(combined[0].start, firstPageOffset + firstSpan.start);
    expect(combined[0].end, firstPageOffset + firstSpan.end);
    expect(combined[1].start, secondPageOffset + secondSpan.start);
    expect(combined[1].end, secondPageOffset + secondSpan.end);
  });

  test('contract: single page combined views stay page-local', () {
    const span = ProtectedSpan(
      pageNumber: 1,
      start: 0,
      end: 17,
      entityType: 'PERSON',
      findingId: 'person-1',
      replacementText: '[[PG_PERSON_001]]',
    );
    const result = ProtectionResult(
      protectedPages: [
        PageContent(pageNumber: 1, text: '[[PG_PERSON_001]]'),
      ],
      protectedSpans: [span],
    );

    expect(result.combinedText, '[[PG_PERSON_001]]');
    expect(result.combinedSpans, same(result.protectedSpans));
  });
}
