import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/syndicate/lieutenant_catalog.dart';

void main() {
  group('Lieutenant & black-market buffs', () {
    test('hacker reduces heat multiplier', () {
      final mods = PassiveModifiers.fromIds(['lt_hacker'], const []);
      expect(mods.heatMult, lessThan(1.0));
      expect(mods.flatHeat, lessThan(0));
    });

    test('enforcer boosts contraband', () {
      final mods = PassiveModifiers.fromIds(['lt_enforcer'], const []);
      expect(mods.contrabandMult, greaterThan(1.0));
    });

    test('tech + lieutenant stack multiplicatively', () {
      final mods = PassiveModifiers.fromIds(
        ['lt_hacker'],
        ['quantum_encryption'],
      );
      expect(mods.heatMult, closeTo(0.55 * 0.8, 0.001));
    });

    test('ghost ledger requires stealth + neural', () {
      final tech = BlackMarketTechCatalog.byId('ghost_ledger')!;
      expect(tech.requirements, containsAll(['stealth_drones', 'neural_bribes']));
    });
  });
}
