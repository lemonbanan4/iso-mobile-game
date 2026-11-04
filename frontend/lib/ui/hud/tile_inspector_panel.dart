import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/syndicate/facility_catalog.dart';
import '../../core/theme/game_theme.dart';
import '../../state/game_state_provider.dart';
import '../components/clay_button.dart';
import '../components/glass_card.dart';
import '../components/construction_timer.dart';

/// Bottom Tile Inspector Panel overlaying the Flame Game.
class TileInspectorPanel extends ConsumerWidget {
  const TileInspectorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final tile = gameState.selectedTile;

    if (tile == null || gameState.showBuildMenu || gameState.isGameOver) {
      return const SizedBox.shrink();
    }

    final hasCity = tile.entity?.type == 'city';
    final hasBarracks = tile.entity?.type == 'barracks';
    final hasTavern = tile.entity?.type == 'tavern';
    final isEmpty = tile.entity == null && tile.unit == null;
    final facility = tile.entity != null
        ? FacilityCatalog.byEntityType(tile.entity!.type)
        : null;

    final int currentUnixTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final bool isConstructing =
        tile.entity != null &&
        tile.entity!.readyAt != null &&
        tile.entity!.readyAt! > currentUnixTime;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
          child: GlassCard(
            borderRadius: 28.0,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tile.unit?.name ??
                                facility?.name ??
                                tile.entity?.name ??
                                tile.type.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: GameTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'District (${tile.coord.x}, ${tile.coord.y}) • ${tile.type.displayName}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: GameTheme.textSecondary.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: GameTheme.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        ref.read(gameStateProvider.notifier).clearSelection();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (tile.entity?.readyAt != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: ConstructionTimer(
                      readyAtTimestamp: tile.entity!.readyAt!,
                    ),
                  ),

                if (facility != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Passive · ${facility.tickLabel}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: GameTheme.accentNeon.withValues(alpha: 0.9),
                      ),
                    ),
                  ),

                Row(
                  children: [
                    _YieldBadge(
                      label: '+${tile.yields.food}',
                      icon: Icons.local_fire_department_rounded,
                      color: GameTheme.heat,
                    ),
                    const SizedBox(width: 8),
                    _YieldBadge(
                      label: '+${tile.yields.production}',
                      icon: Icons.inventory_2_rounded,
                      color: GameTheme.contraband,
                    ),
                    const SizedBox(width: 8),
                    _YieldBadge(
                      label: '+${tile.yields.gold}',
                      icon: Icons.payments_rounded,
                      color: GameTheme.credits,
                    ),
                    const SizedBox(width: 8),
                    _YieldBadge(
                      label: '+${tile.yields.science}',
                      icon: Icons.groups_rounded,
                      color: GameTheme.loyalty,
                    ),
                    const Spacer(),
                    if (tile.territoryOwner != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: GameTheme.accentNeon.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: GameTheme.accentNeon.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          tile.territoryOwner!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: GameTheme.accentNeon,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (isEmpty)
                      ClayButton(
                        isAccent: true,
                        onPressed: () =>
                            ref.read(gameStateProvider.notifier).openBuildMenu(),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_business_rounded,
                              size: 16,
                              color: Color(0xFF070A12),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Open Facility Menu',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF070A12),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (hasBarracks)
                      ClayButton(
                        isAccent: true,
                        onPressed: () => ref
                            .read(gameStateProvider.notifier)
                            .executeTileAction(
                              target: tile.coord,
                              actionType: 'train_warrior',
                            ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Recruit Enforcer (25₡ / 15◆)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (hasTavern)
                      ClayButton(
                        isAccent: true,
                        onPressed: () => ref
                            .read(gameStateProvider.notifier)
                            .executeTileAction(
                              target: tile.coord,
                              actionType: 'summon_commander',
                            ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.diamond_rounded,
                              size: 16,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Call Fixer (100₡)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (hasCity)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            'Capital Cell • Fortified & Harvesting',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: GameTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    if (isConstructing)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.fast_forward,
                            color: Colors.white,
                          ),
                          label: const Text('Burn 1m Speed Chip (x5)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            ref
                                .read(gameStateProvider.notifier)
                                .useSpeedUp(tile.coord);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _YieldBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _YieldBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
