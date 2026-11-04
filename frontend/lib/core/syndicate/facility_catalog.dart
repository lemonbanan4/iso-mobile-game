import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// Placeable underground facilities (Credits / Contraband costs + passive tick yields).
class FacilityBlueprint {
  final String id;
  final String name;
  final String blurb;
  final String actionType;
  final String entityType;
  final int creditCost;
  final int contrabandCost;
  final int tickCredits;
  final int tickContraband;
  final int tickHeat;
  final int tickLoyalty;
  final IconData icon;
  final Color accent;

  const FacilityBlueprint({
    required this.id,
    required this.name,
    required this.blurb,
    required this.actionType,
    required this.entityType,
    required this.creditCost,
    this.contrabandCost = 0,
    required this.tickCredits,
    required this.tickContraband,
    required this.tickHeat,
    required this.tickLoyalty,
    required this.icon,
    required this.accent,
  });

  String get costLabel {
    if (contrabandCost > 0) {
      return '$creditCost₡ / $contrabandCost◆';
    }
    return '$creditCost₡';
  }

  String get tickLabel {
    final parts = <String>[];
    if (tickCredits != 0) {
      parts.add('${tickCredits > 0 ? '+' : ''}$tickCredits Credits');
    }
    if (tickContraband != 0) {
      parts.add('${tickContraband > 0 ? '+' : ''}$tickContraband Contraband');
    }
    if (tickHeat != 0) {
      parts.add('${tickHeat > 0 ? '+' : ''}$tickHeat Heat');
    }
    if (tickLoyalty != 0) {
      parts.add('${tickLoyalty > 0 ? '+' : ''}$tickLoyalty Loyalty');
    }
    return parts.join(' · ');
  }
}

class FacilityCatalog {
  FacilityCatalog._();

  static const List<FacilityBlueprint> all = [
    FacilityBlueprint(
      id: 'smuggling_ring',
      name: 'Smuggling Ring',
      blurb: 'Runs quiet freight through the district. Credits + Contraband, raises Heat.',
      actionType: 'build_mine',
      entityType: 'mine',
      creditCost: 40,
      tickCredits: 10,
      tickContraband: 6,
      tickHeat: 2,
      tickLoyalty: 0,
      icon: Icons.local_shipping_rounded,
      accent: GameTheme.contraband,
    ),
    FacilityBlueprint(
      id: 'bribe_network',
      name: 'Bribe Network',
      blurb: 'Pays clerks and drones to look elsewhere. Softens Heat, steadies Loyalty.',
      actionType: 'build_farm',
      entityType: 'farm',
      creditCost: 35,
      tickCredits: 4,
      tickContraband: 0,
      tickHeat: -2,
      tickLoyalty: 1,
      icon: Icons.handshake_rounded,
      accent: GameTheme.loyalty,
    ),
    FacilityBlueprint(
      id: 'chem_lab',
      name: 'Chem Lab',
      blurb: 'Cooks high-grade product. Heavy Contraband yield; Heat and Loyalty risk.',
      actionType: 'build_barracks',
      entityType: 'barracks',
      creditCost: 55,
      contrabandCost: 15,
      tickCredits: 2,
      tickContraband: 12,
      tickHeat: 3,
      tickLoyalty: -1,
      icon: Icons.science_rounded,
      accent: GameTheme.accentMagenta,
    ),
    FacilityBlueprint(
      id: 'contraband_vault',
      name: 'Contraband Vault',
      blurb: 'Hardened stash + fence rails. Balanced Credits/Contraband drip.',
      actionType: 'build_tavern',
      entityType: 'tavern',
      creditCost: 90,
      contrabandCost: 25,
      tickCredits: 14,
      tickContraband: 8,
      tickHeat: 1,
      tickLoyalty: 0,
      icon: Icons.lock_rounded,
      accent: GameTheme.credits,
    ),
  ];

  static FacilityBlueprint? byActionType(String actionType) {
    for (final f in all) {
      if (f.actionType == actionType) return f;
    }
    return null;
  }

  static FacilityBlueprint? byEntityType(String entityType) {
    for (final f in all) {
      if (f.entityType == entityType) return f;
    }
    return null;
  }
}
