import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_hooks.dart';
import '../../core/syndicate/lieutenant_catalog.dart';
import '../../core/theme/game_theme.dart';
import '../../state/game_state_provider.dart';
import '../components/clay_button.dart';
import '../components/glass_card.dart';

/// Black-market upgrade tree — spends Credits + Contraband.
class TechTreeScreen extends ConsumerWidget {
  const TechTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final unlocked = gameState.unlockedTechs;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: GameTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: GlassCard(
                borderRadius: 22,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        AudioHooks.instance.uiClick();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: GameTheme.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BLACK MARKET NET',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.6,
                              color: GameTheme.accentNeon,
                            ),
                          ),
                          const Text(
                            'Tech Tree',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: GameTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Chip(
                      icon: Icons.payments_rounded,
                      color: GameTheme.credits,
                      value: '${gameState.credits}',
                    ),
                    const SizedBox(width: 6),
                    _Chip(
                      icon: Icons.inventory_2_rounded,
                      color: GameTheme.contraband,
                      value: '${gameState.contraband}',
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                itemCount: BlackMarketTechCatalog.all.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final tech = BlackMarketTechCatalog.all[index];
                  final isUnlocked = unlocked.contains(tech.id);
                  final meetsRequirements = tech.requirements.every(
                    unlocked.contains,
                  );
                  final canAfford = gameState.credits >= tech.creditCost &&
                      gameState.contraband >= tech.contrabandCost;
                  final canBuy =
                      !isUnlocked && meetsRequirements && canAfford;

                  return _TechCard(
                    tech: tech,
                    isUnlocked: isUnlocked,
                    meetsRequirements: meetsRequirements,
                    canBuy: canBuy,
                    onUnlock: canBuy
                        ? () => ref
                            .read(gameStateProvider.notifier)
                            .unlockBlackMarketTech(tech.id)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;

  const _Chip({
    required this.icon,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechCard extends StatelessWidget {
  final BlackMarketTech tech;
  final bool isUnlocked;
  final bool meetsRequirements;
  final bool canBuy;
  final VoidCallback? onUnlock;

  const _TechCard({
    required this.tech,
    required this.isUnlocked,
    required this.meetsRequirements,
    required this.canBuy,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isUnlocked
        ? GameTheme.accentNeon
        : (meetsRequirements ? GameTheme.contraband : GameTheme.textMuted);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x3310182A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.4),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: GameTheme.accentNeon.withValues(alpha: 0.18),
                  blurRadius: 16,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.2),
                child: Icon(tech.icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tech.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isUnlocked
                        ? GameTheme.textPrimary
                        : GameTheme.textPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ),
              if (isUnlocked)
                const Icon(Icons.check_circle, color: GameTheme.accentNeon)
              else
                Text(
                  tech.costLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: canBuy ? GameTheme.credits : GameTheme.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            !meetsRequirements && !isUnlocked
                ? 'Requires: ${tech.requirements.join(", ")}'
                : tech.blurb,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: !meetsRequirements && !isUnlocked
                  ? GameTheme.danger.withValues(alpha: 0.9)
                  : GameTheme.textSecondary,
            ),
          ),
          if (!isUnlocked) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ClayButton(
                isAccent: canBuy,
                onPressed: onUnlock,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                borderRadius: 14,
                child: Text(
                  canBuy
                      ? 'UNLOCK'
                      : (!meetsRequirements ? 'GATED' : 'NEED FUNDS'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: canBuy
                        ? const Color(0xFF070A12)
                        : GameTheme.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
