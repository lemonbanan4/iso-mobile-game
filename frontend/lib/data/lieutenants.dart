class Lieutenant {
  final String id;
  final String name;
  final String role;
  final int cost;
  final int upkeepAmount;
  final String description;
  final Map<String, double> buffs;
  bool hired;

  Lieutenant({
    required this.id,
    required this.name,
    required this.role,
    required this.cost,
    required this.upkeepAmount,
    required this.description,
    required this.buffs,
    this.hired = false,
  });
}

final List<Lieutenant> initialLieutenants = [
  Lieutenant(
    id: 'hacker_01',
    name: 'Slick "Zero-Day" Chen',
    role: 'Cyber-Infiltrator',
    cost: 500,
    upkeepAmount: 50,
    description: 'Expert netrunner who scrambles police feeds and lowers facility heat generation.',
    buffs: {'heatMultiplier': 0.75, 'creditMultiplier': 1.0},
  ),
  Lieutenant(
    id: 'enforcer_01',
    name: 'Jax "Iron" Vance',
    role: 'Syndicate Enforcer',
    cost: 800,
    upkeepAmount: 100,
    description: 'Brutal street operator who intimidates locals and boosts contraband smuggling yields.',
    buffs: {'heatMultiplier': 1.0, 'contrabandMultiplier': 1.30},
  ),
  Lieutenant(
    id: 'smuggler_01',
    name: 'Vesper Nyx',
    role: 'Black-Market Pilot',
    cost: 1200,
    upkeepAmount: 150,
    description: 'Master of off-grid transit channels, accelerating passive credit generation.',
    buffs: {'heatMultiplier': 1.0, 'creditMultiplier': 1.25},
  ),
];