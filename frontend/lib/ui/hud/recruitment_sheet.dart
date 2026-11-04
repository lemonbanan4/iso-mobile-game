import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_hooks.dart';
import '../../core/syndicate/lieutenant_catalog.dart';
import '../../core/theme/game_theme.dart';
import '../../state/game_state_provider.dart';
import '../components/clay_button.dart';
import '../components/glass_card.dart';

/// Mobile-first lieutenant hiring panel.
class RecruitmentSheet extends ConsumerWidget {
  const RecruitmentSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    if (!state.showRecruitment) return const SizedBox.shrink();

    final height = MediaQuery.sizeOf(context).height;

    return Positioned.fill(
      child: Material(
        color: const Color(0xCC070A12),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: GlassCard(
                borderRadius: 28,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: height * 0.78,
                    maxWidth: 480,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: GameTheme.accentMagenta.withValues(
                                alpha: 0.18,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: GameTheme.accentMagenta.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: const Text(
                              'CREW BAY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: GameTheme.accentMagenta,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              AudioHooks.instance.uiClick();
                              ref
                                  .read(gameStateProvider.notifier)
                                  .closeRecruitment();
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: GameTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Recruit Lieutenants',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: GameTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hire unique cyberpunk crew. Passiveuffs stack into every facility tick.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: GameTheme.textSecondary.withValues(alpha: 0.95),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: LieutenantCatalog.all.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final lt = LieutenantCatalog.all[index];
                            final hired = state.hiredLieutenants.contains(lt.id);
                            final canAfford =
                                !hired && state.credits >= lt.creditCost;
                            return _LieutenantCard(
                              lieutenant: lt,
                              hired: hired,
                              canAfford: canAfford,
                              onHire: canAfford
                                  ? () => ref
                                      .read(gameStateProvider.notifier)
                                      .hireLieutenant(lt.id)
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

class _LieutenantCard extends StatelessWidget {
  final LieutenantBlueprint lieutenant;
  final bool hired;
  final bool canAfford;
  final VoidCallback? onHire;

  const _LieutenantCard({
    required this.lieutenant,
    required this.hired,
    required this.canAfford,
    required this.onHire,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x3310182A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: lieutenant.accent.withValues(
            alpha: hired ? 0.65 : (canAfford ? 0.4 : 0.18),
          ),
        ),
        boxShadow: hired
            ? [
                BoxShadow(
                  color: lieutenant.accent.withValues(alpha: 0.22),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(lieutenant.icon, color: lieutenant.accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lieutenant.codename,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: GameTheme.textPrimary,
                      ),
                    ),
                    Text(
                      lieutenant.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: lieutenant.accent.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                hired ? 'ON PAYROLL' : '${lieutenant.creditCost}₡',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: hired ? GameTheme.accentNeon : lieutenant.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lieutenant.blurb,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: GameTheme.textSecondary.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lieutenant.buffLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: GameTheme.accentNeon.withValues(alpha: 0.9),
            ),
          ),
          if (!hired) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ClayButton(
                isAccent: canAfford,
                onPressed: onHire,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                borderRadius: 14,
                child: Text(
                  canAfford ? 'HIRE' : 'LOCKED',
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
        ],
      ),
    );
  }
}
