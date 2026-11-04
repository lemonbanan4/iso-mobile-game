import 'dart:math';

/// Randomized underground syndicate encounter blurbs for the event ticker.
class EncounterCatalog {
  EncounterCatalog._();

  static final _rng = Random();

  static const List<String> pool = [
    'A courier slipped past the cordon with a crate of unregistered stimulants.',
    'District 7 lookouts report drones sweeping the alley grid — keep Heat low.',
    'Rival crew offered a quiet truce for a cut of tonight\'s Contraband haul.',
    'Safehouse radios crackle: loyalty spike after the street payout.',
    'Black-market lounge host tipped us about a bribe window at Sector Gate.',
    'Chop-shop runners converted scrap into usable Contraband overnight.',
    'An informant wants Credits for a ledger of patrol routes.',
    'Enforcement cell flexed — street loyalty holds, Heat ticks upward.',
    'Neon fog rolled in; three unmarked vans left the industrial district.',
    'Syndicate whisper net: a legendary fixer is shopping for a new cell.',
    'Contraband vault seals held. Credits cleared. Another cycle survives.',
    'Heat surge near the capital cell — divert crews or risk a raid.',
    'Smuggling den quiet for now. Too quiet.',
    'Underboss redistributed Loyalty tokens across the lower floors.',
    'Street festival cover bought us two hours of soft surveillance.',
  ];

  static String randomEncounter() => pool[_rng.nextInt(pool.length)];

  static List<String> seedLog({int count = 3}) {
    final shuffled = List<String>.from(pool)..shuffle(_rng);
    return shuffled.take(count).toList();
  }
}
