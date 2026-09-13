import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/session/session_namespace.dart';

void main() {
  test('browser turn namespace matches audited Desktop shape', () {
    final sessionId = List.filled(32, 'a').join();
    final namespace = SessionNamespace.browserTurn(sessionId, 1);
    final token = SessionNamespace.applyToBaseToken('[[PG_PERSON_001]]', namespace);

    expect(namespace, 'BAAAAAAAA_T0001');
    expect(token, '[[PG_BAAAAAAAA_T0001_PERSON_001]]');
  });
}
