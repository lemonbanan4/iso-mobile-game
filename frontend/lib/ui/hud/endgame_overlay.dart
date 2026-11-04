import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/game_theme.dart';
import '../../state/game_state_provider.dart';
import '../components/clay_button.dart';
import '../components/glass_card.dart';

/// Victory / crisis fullscreen overlay with neon cyber accents.
class EndgameOverlay extends ConsumerWidget {
  const EndgameOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    if (!state.isVictory && !state.isDefeat) {
      return const SizedBox.shrink();
    }

    final victory = state.isVictory;
    final accent = victory ? Colors.amber : GameTheme.danger;
    final title = victory ? 'DOMINANCE' : 'BUSTED';
    final detail = victory ? state.victoryDetail : state.defeatDetail;
    final icon = victory
        ? Icons.emoji_events_rounded
        : Icons.warning_amber_rounded;

    return Positioned.fill(
      child: Material(
        color: const Color(0xF2070A12),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassCard(
                borderRadius: 32,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 88, color: accent),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accent,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      detail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: GameTheme.textPrimary,
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      victory
                          ? '${state.credits} Credits · ${state.controlledSectors} sectors'
                          : 'Heat ${state.heat}% · Loyalty ${state.loyalty}%',
                      style: TextStyle(
                        color: accent.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ClayButton(
                      isAccent: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      borderRadius: 18,
                      onPressed: () {
                        ref.read(gameStateProvider.notifier).restartSession();
                      },
                      child: Text(
                        victory ? 'REOPEN THE NET' : 'SCAN WRECKAGE',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Color(0xFF070A12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
