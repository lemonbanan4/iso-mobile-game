import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/game_theme.dart';
import '../../state/game_state_provider.dart';
import '../components/clay_button.dart';
import '../components/glass_card.dart';
import '../screens/tech_tree_screen.dart';

/// Top floating Liquid Glass Resource Dashboard (syndicate ledger).
class ResourceDashboard extends ConsumerWidget {
  const ResourceDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            ClayButton(
              padding: const EdgeInsets.all(12),
              borderRadius: 16,
              onPressed: () =>
                  ref.read(gameStateProvider.notifier).openGameMenu(),
              child: const Icon(
                Icons.menu_rounded,
                size: 18,
                color: GameTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
                borderRadius: 24.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ResourceItem(
                      icon: Icons.payments_rounded,
                      color: GameTheme.credits,
                      value: '${gameState.credits}',
                      label: 'Credits',
                    ),
                    _ResourceItem(
                      icon: Icons.inventory_2_rounded,
                      color: GameTheme.contraband,
                      value: '${gameState.contraband}',
                      label: 'Contraband',
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TechTreeScreen(),
                          ),
                        );
                      },
                      child: _ResourceItem(
                        icon: Icons.groups_rounded,
                        color: GameTheme.loyalty,
                        value: '${gameState.loyalty}%',
                        label: 'Loyalty',
                      ),
                    ),
                    _ResourceItem(
                      icon: Icons.local_fire_department_rounded,
                      color: gameState.heat >= 80
                          ? GameTheme.danger
                          : GameTheme.heat,
                      value: '${gameState.heat}%',
                      label: 'Heat',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            ClayButton(
              isAccent: true,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              borderRadius: 22,
              onPressed: gameState.isGameOver
                  ? null
                  : () {
                      ref.read(gameStateProvider.notifier).nextTurn();
                    },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${gameState.controlledSectors}/${GameState.victorySectorTarget}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF070A12),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Text(
                    'CYCLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF070A12),
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    '${gameState.currentTurn}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF070A12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _ResourceItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: GameTheme.textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: GameTheme.textSecondary.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
