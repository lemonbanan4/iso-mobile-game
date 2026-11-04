import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/syndicate/facility_catalog.dart';
import '../../core/theme/game_theme.dart';
import '../../state/game_state_provider.dart';
import '../components/clay_button.dart';
import '../components/glass_card.dart';

/// Mobile-first facility placement menu (Credits / Contraband spend).
class FacilityBuildSheet extends ConsumerWidget {
  const FacilityBuildSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    if (!state.showBuildMenu) return const SizedBox.shrink();

    final tile = state.selectedTile;
    final coordLabel = tile == null
        ? '—'
        : '(${tile.coord.x}, ${tile.coord.y})';

    return Positioned.fill(
      child: Material(
        color: const Color(0xCC070A12),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: GlassCard(
                borderRadius: 28,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.72,
                    maxWidth: 480,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: GameTheme.accentNeon.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: GameTheme.accentNeon.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                            child: const Text(
                              'BUILD CELL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: GameTheme.accentNeon,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => ref
                                .read(gameStateProvider.notifier)
                                .closeBuildMenu(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: GameTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'District $coordLabel',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: GameTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Spend Credits to plant underground infrastructure. Passive yields tick every 5s.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: GameTheme.textSecondary.withValues(alpha: 0.95),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: FacilityCatalog.all.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final facility = FacilityCatalog.all[index];
                            final canAfford =
                                state.credits >= facility.creditCost &&
                                state.contraband >= facility.contrabandCost;
                            return _FacilityCard(
                              facility: facility,
                              canAfford: canAfford,
                              onBuild: canAfford
                                  ? () => ref
                                      .read(gameStateProvider.notifier)
                                      .placeFacility(facility)
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  final FacilityBlueprint facility;
  final bool canAfford;
  final VoidCallback? onBuild;

  const _FacilityCard({
    required this.facility,
    required this.canAfford,
    required this.onBuild,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x3310182A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: facility.accent.withValues(alpha: canAfford ? 0.45 : 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(facility.icon, color: facility.accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  facility.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: GameTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                facility.costLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: canAfford ? facility.accent : GameTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            facility.blurb,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: GameTheme.textSecondary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tick: ${facility.tickLabel}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: GameTheme.accentNeon.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ClayButton(
              isAccent: canAfford,
              onPressed: onBuild,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              borderRadius: 14,
              child: Text(
                canAfford ? 'DEPLOY' : 'LOCKED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: canAfford
                      ? const Color(0xFF070A12)
                      : GameTheme.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
