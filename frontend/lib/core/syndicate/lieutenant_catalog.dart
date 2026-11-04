import 'package:flutter/material.dart';

import '../../data/lieutenants.dart' as roster;
import '../theme/game_theme.dart';

/// Aggregate passive modifiers from hired crew + black-market tech.
class PassiveModifiers {
  final double creditsMult;
  final double contrabandMult;
  final double heatMult;
  final int flatLoyalty;
  final int flatHeat;

  const PassiveModifiers({
    this.creditsMult = 1.0,
    this.contrabandMult = 1.0,
    this.heatMult = 1.0,
    this.flatLoyalty = 0,
    this.flatHeat = 0,
  });

  PassiveModifiers combine(PassiveModifiers other) {
    return PassiveModifiers(
      creditsMult: creditsMult * other.creditsMult,
      contrabandMult: contrabandMult * other.contrabandMult,
      heatMult: heatMult * other.heatMult,
      flatLoyalty: flatLoyalty + other.flatLoyalty,
      flatHeat: flatHeat + other.flatHeat,
    );
  }

  /// Maps `lib/data/lieutenants.dart` buff keys onto economy multipliers.
  factory PassiveModifiers.fromRosterBuffs(Map<String, double> buffs) {
    return PassiveModifiers(
      creditsMult: buffs['creditMultiplier'] ?? 1.0,
      contrabandMult: buffs['contrabandMultiplier'] ?? 1.0,
      heatMult: buffs['heatMultiplier'] ?? 1.0,
    );
  }

  static PassiveModifiers fromIds(
    Iterable<String> lieutenantIds,
    Iterable<String> techIds,
  ) {
    var mods = const PassiveModifiers();
    for (final id in lieutenantIds) {
      final lt = LieutenantCatalog.byId(id);
      if (lt != null) {
        mods = mods.combine(lt.buffs);
        continue;
      }
      for (final rosterLt in roster.initialLieutenants) {
        if (rosterLt.id == id) {
          mods = mods.combine(PassiveModifiers.fromRosterBuffs(rosterLt.buffs));
          break;
        }
      }
    }
    for (final id in techIds) {
      final tech = BlackMarketTechCatalog.byId(id);
      if (tech != null) mods = mods.combine(tech.buffs);
    }
    return mods;
  }
}

class LieutenantBlueprint {
  final String id;
  final String codename;
  final String role;
  final String blurb;
  final int creditCost;
  final PassiveModifiers buffs;
  final IconData icon;
  final Color accent;

  const LieutenantBlueprint({
    required this.id,
    required this.codename,
    required this.role,
    required this.blurb,
    required this.creditCost,
    required this.buffs,
    required this.icon,
    required this.accent,
  });

  String get buffLabel {
    final parts = <String>[];
    if (buffs.heatMult < 1.0) {
      final pct = ((1.0 - buffs.heatMult) * 100).round();
      parts.add('−$pct% Heat tick');
    }
    if (buffs.contrabandMult > 1.0) {
      final pct = ((buffs.contrabandMult - 1.0) * 100).round();
      parts.add('+$pct% Contraband');
    }
    if (buffs.creditsMult > 1.0) {
      final pct = ((buffs.creditsMult - 1.0) * 100).round();
      parts.add('+$pct% Credits');
    }
    if (buffs.flatLoyalty != 0) {
      parts.add('${buffs.flatLoyalty > 0 ? '+' : ''}${buffs.flatLoyalty} Loyalty/tick');
    }
    if (buffs.flatHeat != 0) {
      parts.add('${buffs.flatHeat > 0 ? '+' : ''}${buffs.flatHeat} Heat/tick');
    }
    return parts.join(' · ');
  }
}

class LieutenantCatalog {
  LieutenantCatalog._();

  static const List<LieutenantBlueprint> all = [
    LieutenantBlueprint(
      id: 'lt_hacker',
      codename: 'Nyx “Ghostwire”',
      role: 'Hacker',
      blurb: 'Spoofs patrol drones and rewrites heat signatures on the fly.',
      creditCost: 180,
      buffs: PassiveModifiers(heatMult: 0.55, flatHeat: -1),
      icon: Icons.terminal_rounded,
      accent: GameTheme.loyalty,
    ),
    LieutenantBlueprint(
      id: 'lt_enforcer',
      codename: 'Brick “Ironjaw”',
      role: 'Enforcer',
      blurb: 'Keeps street crews moving product — louder yields, heavier vibe.',
      creditCost: 220,
      buffs: PassiveModifiers(contrabandMult: 1.4, flatLoyalty: 1),
      icon: Icons.sports_mma_rounded,
      accent: GameTheme.contraband,
    ),
    LieutenantBlueprint(
      id: 'lt_smuggler',
      codename: 'Mira “Lantern”',
      role: 'Smuggler',
      blurb: 'Runs false manifests through the docks. Credits drip cleaner.',
      creditCost: 200,
      buffs: PassiveModifiers(creditsMult: 1.25, contrabandMult: 1.15),
      icon: Icons.sailing_rounded,
      accent: GameTheme.credits,
    ),
    LieutenantBlueprint(
      id: 'lt_fixer',
      codename: 'Vex “Choir”',
      role: 'Fixer',
      blurb: 'Buys silence and loyalty tokens across the lower floors.',
      creditCost: 260,
      buffs: PassiveModifiers(flatLoyalty: 2, flatHeat: -1, creditsMult: 1.1),
      icon: Icons.record_voice_over_rounded,
      accent: GameTheme.accentMagenta,
    ),
  ];

  static LieutenantBlueprint? byId(String id) {
    for (final lt in all) {
      if (lt.id == id) return lt;
    }
    return null;
  }
}

class BlackMarketTech {
  final String id;
  final String name;
  final String blurb;
  final int creditCost;
  final int contrabandCost;
  final List<String> requirements;
  final PassiveModifiers buffs;
  final IconData icon;

  const BlackMarketTech({
    required this.id,
    required this.name,
    required this.blurb,
    required this.creditCost,
    required this.contrabandCost,
    this.requirements = const [],
    required this.buffs,
    required this.icon,
  });

  String get costLabel => '$creditCost₡ / $contrabandCost◆';
}

class BlackMarketTechCatalog {
  BlackMarketTechCatalog._();

  static const List<BlackMarketTech> all = [
    BlackMarketTech(
      id: 'quantum_encryption',
      name: 'Quantum Encryption',
      blurb: 'Scrambles syndicate traffic. Cuts Heat bleed from active cells.',
      creditCost: 80,
      contrabandCost: 40,
      buffs: PassiveModifiers(heatMult: 0.8),
      icon: Icons.lock_rounded,
    ),
    BlackMarketTech(
      id: 'neural_bribes',
      name: 'Neural Bribes',
      blurb: 'Implanted loyalty scripts keep street crews aligned.',
      creditCost: 100,
      contrabandCost: 50,
      buffs: PassiveModifiers(flatLoyalty: 1),
      icon: Icons.psychology_rounded,
    ),
    BlackMarketTech(
      id: 'stealth_drones',
      name: 'Stealth Drones',
      blurb: 'Silent overwatch. Softens Heat spikes and rival pressure.',
      creditCost: 120,
      contrabandCost: 60,
      requirements: ['quantum_encryption'],
      buffs: PassiveModifiers(heatMult: 0.85, flatHeat: -1),
      icon: Icons.flight_rounded,
    ),
    BlackMarketTech(
      id: 'chrome_vault',
      name: 'Chrome Vault Protocols',
      blurb: 'Hardened stash rails — Contraband yields climb.',
      creditCost: 90,
      contrabandCost: 70,
      buffs: PassiveModifiers(contrabandMult: 1.3),
      icon: Icons.inventory_2_rounded,
    ),
    BlackMarketTech(
      id: 'ghost_ledger',
      name: 'Ghost Ledger',
      blurb: 'Double books in the fog. Credits compound quietly.',
      creditCost: 150,
      contrabandCost: 80,
      requirements: ['stealth_drones', 'neural_bribes'],
      buffs: PassiveModifiers(creditsMult: 1.3, heatMult: 0.9),
      icon: Icons.auto_graph_rounded,
    ),
  ];

  static BlackMarketTech? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}
