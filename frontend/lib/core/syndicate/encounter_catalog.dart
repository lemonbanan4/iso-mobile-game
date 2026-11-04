import 'dart:math';

import 'encounter_models.dart';

/// Passive blurbs + choice-driven encounters for the syndicate event system.
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

  /// Weighted chance to surface a choice-driven prompt after a cycle closes.
  static SyndicateEncounter? maybePrompt({double chance = 0.55}) {
    if (_rng.nextDouble() > chance) return null;
    return randomPrompt();
  }

  static SyndicateEncounter randomPrompt() {
    final prompts = _choicePrompts;
    return prompts[_rng.nextInt(prompts.length)];
  }

  static const List<SyndicateEncounter> _choicePrompts = [
    SyndicateEncounter(
      id: 'bribe_patrol',
      title: 'Sector Gate Sweep',
      body:
          'Marked patrols are idling at the gate. A clerk will look the other way — for a price.',
      choices: [
        EncounterChoice(
          id: 'pay',
          label: 'Pay the bribe (−40 Credits)',
          outcome: 'Gate clerks pocket the Credits. Heat cools for now.',
          delta: ResourceDelta(credits: -40, heat: -18),
        ),
        EncounterChoice(
          id: 'scatter',
          label: 'Scatter the runners',
          outcome: 'Crews bolt into the alleys. Heat spikes; Loyalty steadies.',
          delta: ResourceDelta(heat: 12, loyalty: 5),
        ),
        EncounterChoice(
          id: 'ignore',
          label: 'Ignore the sweep',
          outcome: 'You gamble. Drones linger — Heat climbs.',
          delta: ResourceDelta(heat: 22),
        ),
      ],
    ),
    SyndicateEncounter(
      id: 'rival_offer',
      title: 'Rival Syndicate Wire',
      body:
          'The Neon Vipers propose a quiet swap: Contraband for street cover across District 4.',
      choices: [
        EncounterChoice(
          id: 'deal',
          label: 'Take the deal (−25 Contraband)',
          outcome: 'Vipers move product. Your Heat dips; Loyalty softens.',
          delta: ResourceDelta(contraband: -25, heat: -10, loyalty: -8),
        ),
        EncounterChoice(
          id: 'refuse',
          label: 'Refuse cold',
          outcome: 'Respect holds. No favors owed.',
          delta: ResourceDelta(loyalty: 10),
        ),
        EncounterChoice(
          id: 'double',
          label: 'Double-cross (+Credits, +Heat)',
          outcome: 'You skim both sides. Credits flood in; Heat detonates.',
          delta: ResourceDelta(credits: 55, heat: 28, loyalty: -12),
        ),
      ],
    ),
    SyndicateEncounter(
      id: 'informant',
      title: 'Whisper Net Tip',
      body:
          'An informant slides a drive across the bar: patrol routes for tonight — if you can pay.',
      choices: [
        EncounterChoice(
          id: 'buy',
          label: 'Buy the ledger (−30 Credits)',
          outcome: 'Routes decoded. Heat drops; crews stay sharp.',
          delta: ResourceDelta(credits: -30, heat: -15, loyalty: 6),
        ),
        EncounterChoice(
          id: 'threaten',
          label: 'Squeeze them free',
          outcome: 'They talk. Loyalty frays; free intel cools Heat slightly.',
          delta: ResourceDelta(loyalty: -15, heat: -8),
        ),
        EncounterChoice(
          id: 'walk',
          label: 'Walk away',
          outcome: 'No deal. The night stays noisy.',
          delta: ResourceDelta(),
        ),
      ],
    ),
    SyndicateEncounter(
      id: 'street_payout',
      title: 'Street Payout Window',
      body:
          'Lower-floor crews expect their cut. Skip it and the net gets restless.',
      choices: [
        EncounterChoice(
          id: 'pay_full',
          label: 'Full payout (−50 Credits)',
          outcome: 'Wallets fat. Loyalty surges across the cells.',
          delta: ResourceDelta(credits: -50, loyalty: 20, heat: -5),
        ),
        EncounterChoice(
          id: 'short',
          label: 'Short them (−20 Credits)',
          outcome: 'Partial quiet. Grumbling stays under the neon.',
          delta: ResourceDelta(credits: -20, loyalty: 5, heat: 8),
        ),
        EncounterChoice(
          id: 'skip',
          label: 'Skip the cut',
          outcome: 'Mutters turn to leaks. Heat rises; Loyalty tanks.',
          delta: ResourceDelta(loyalty: -25, heat: 18),
        ),
      ],
    ),
    SyndicateEncounter(
      id: 'black_market_drop',
      title: 'Black Market Drop',
      body:
          'A van dumps unmarked crates behind the lounge. Claim them, fence them, or torch the evidence.',
      choices: [
        EncounterChoice(
          id: 'claim',
          label: 'Stash the haul',
          outcome: 'Contraband vaults swell. Heat ticks up.',
          delta: ResourceDelta(contraband: 35, heat: 14),
        ),
        EncounterChoice(
          id: 'fence',
          label: 'Fence for Credits',
          outcome: 'Credits clear. Louder than you hoped.',
          delta: ResourceDelta(credits: 45, heat: 20),
        ),
        EncounterChoice(
          id: 'torch',
          label: 'Torch the crates',
          outcome: 'Smoke and silence. Heat cools; crews stay loyal.',
          delta: ResourceDelta(heat: -12, loyalty: 8),
        ),
      ],
    ),
  ];
}
