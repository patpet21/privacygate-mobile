import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/detection/detection_pack_catalog.dart';

void main() {
  test('generated detection pack matches canonical Desktop snapshot', () {
    expect(detectionPackCatalog.schemaVersion, 1);
    expect(
      detectionPackCatalog.sha256,
      'effaed8acf254bd9345345a4d96e839ffbc3a3922ddb2cef31a6c5b4dad89390',
    );
    expect(detectionPackCatalog.defaultProfileKey, 'general_business');
    expect(detectionPackCatalog.defaultScopeKey, 'maximum');
    expect(detectionPackCatalog.defaultLanguage, 'en');
    expect(detectionPackCatalog.engineKind('desktop'), 'presidio_spacy');
    expect(
      detectionPackCatalog.engineKind('mobile_basic'),
      'deterministic_rules',
    );
    expect(
      detectionPackCatalog.semanticEntities,
      containsAll(['PERSON', 'ORGANIZATION', 'LOCATION']),
    );
  });
}
