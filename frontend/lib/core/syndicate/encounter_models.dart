/// Resource deltas applied when a syndicate encounter choice is resolved.
/// Mapped to backend fields: Credits→gold, Contraband→production,
/// Loyalty→science, Heat→food.
class ResourceDelta {
  final int credits;
  final int contraband;
  final int loyalty;
  final int heat;

  const ResourceDelta({
    this.credits = 0,
    this.contraband = 0,
    this.loyalty = 0,
    this.heat = 0,
  });

  bool get isEmpty =>
      credits == 0 && contraband == 0 && loyalty == 0 && heat == 0;

  String get summary {
    final parts = <String>[];
    if (credits != 0) parts.add('${credits > 0 ? '+' : ''}$credits Credits');
    if (contraband != 0) {
      parts.add('${contraband > 0 ? '+' : ''}$contraband Contraband');
    }
    if (loyalty != 0) {
      parts.add('${loyalty > 0 ? '+' : ''}$loyalty Loyalty');
    }
    if (heat != 0) parts.add('${heat > 0 ? '+' : ''}$heat Heat');
    return parts.isEmpty ? 'No change' : parts.join(' · ');
  }
}

class EncounterChoice {
  final String id;
  final String label;
  final String outcome;
  final ResourceDelta delta;

  const EncounterChoice({
    required this.id,
    required this.label,
    required this.outcome,
    this.delta = const ResourceDelta(),
  });
}

/// Choice-driven underground encounter shown as a prompt over the grid.
class SyndicateEncounter {
  final String id;
  final String title;
  final String body;
  final List<EncounterChoice> choices;

  const SyndicateEncounter({
    required this.id,
    required this.title,
    required this.body,
    required this.choices,
  });
}
