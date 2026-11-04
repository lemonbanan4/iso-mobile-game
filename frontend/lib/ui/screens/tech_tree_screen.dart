import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/game_theme.dart';
import '../../state/game_state_provider.dart';

class TechNode {
  final String id;
  final String name;
  final int cost;
  final IconData icon;
  final String description;
  final List<String> requirements;

  const TechNode(
    this.id,
    this.name,
    this.cost,
    this.icon,
    this.description, [
    this.requirements = const [],
  ]);
}

const List<TechNode> techTree = [
  TechNode(
    'mining',
    'Mining',
    50,
    Icons.landscape_rounded,
    'Allows construction of Mines for +2 Production.',
    [],
  ),
  TechNode(
    'bronze_working',
    'Bronze Working',
    100,
    Icons.hardware_rounded,
    'Unlocks the Barracks and Axe Warriors.',
    ['mining'],
  ),
  TechNode(
    'masonry',
    'Masonry',
    150,
    Icons.account_balance_rounded,
    'Allows construction of Defensive Walls.',
    ['mining'],
  ),
  TechNode(
    'iron_working',
    'Iron Working',
    200,
    Icons.construction_rounded,
    'Unlocks Heavy Swordsmen and Forges.',
    ['bronze_working'],
  ),
];

class TechTreeScreen extends ConsumerWidget {
  const TechTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final unlocked = gameState.unlockedTechs;
    final currentScience = gameState.science;

    return Scaffold(
      backgroundColor: const Color(
        0xFF0F172A,
      ).withValues(alpha: 0.95), // Semi-transparent dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'RESEARCH & TECHNOLOGY',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '$currentScience 🧪',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: GameTheme.science,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24.0),
        itemCount: techTree.length,
        itemBuilder: (context, index) {
          final tech = techTree[index];
          final isUnlocked = unlocked.contains(tech.id);

          // Check if all prerequisites are met
          final canAfford = currentScience >= tech.cost;
          final meetsRequirements = tech.requirements.every(
            (req) => unlocked.contains(req),
          );
          final isLocked = !isUnlocked && !meetsRequirements;

          Color cardColor = isUnlocked
              ? GameTheme.science.withValues(alpha: 0.2)
              : Colors.black45;
          Color borderColor = isUnlocked ? GameTheme.science : Colors.white12;

          return Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: isUnlocked
                    ? GameTheme.science
                    : Colors.grey[800],
                child: Icon(tech.icon, color: Colors.white),
              ),
              title: Text(
                tech.name,
                style: TextStyle(
                  color: isUnlocked ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  isLocked
                      ? 'Requires: ${tech.requirements.join(", ")}'
                      : tech.description,
                  style: TextStyle(
                    color: isLocked ? Colors.redAccent : Colors.grey[400],
                  ),
                ),
              ),
              trailing: isUnlocked
                  ? const Icon(
                      Icons.check_circle,
                      color: GameTheme.science,
                      size: 32,
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (canAfford && !isLocked)
                            ? GameTheme.science
                            : Colors.grey[800],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: (canAfford && !isLocked)
                          ? () {
                              ref
                                  .read(gameStateProvider.notifier)
                                  .researchTech(tech.id);
                            }
                          : null,
                      child: Text(
                        'Research\n(${tech.cost})',
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
