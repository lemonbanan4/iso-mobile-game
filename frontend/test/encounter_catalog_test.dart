import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/syndicate/encounter_catalog.dart';
import 'package:frontend/core/syndicate/encounter_models.dart';

void main() {
  group('EncounterCatalog', () {
    test('seedLog returns requested count of unique blurbs', () {
      final log = EncounterCatalog.seedLog(count: 3);
      expect(log.length, 3);
      expect(log.toSet().length, 3);
    });

    test('randomPrompt always offers at least two choices', () {
      for (var i = 0; i < 10; i++) {
        final prompt = EncounterCatalog.randomPrompt();
        expect(prompt.choices.length, greaterThanOrEqualTo(2));
        expect(prompt.title.isNotEmpty, isTrue);
        expect(prompt.body.isNotEmpty, isTrue);
      }
    });

    test('ResourceDelta summary formats signed ledger shifts', () {
      const delta = ResourceDelta(credits: -40, heat: -18, loyalty: 5);
      expect(delta.summary, contains('-40 Credits'));
      expect(delta.summary, contains('-18 Heat'));
      expect(delta.summary, contains('+5 Loyalty'));
      expect(delta.isEmpty, isFalse);
    });
  });
}
