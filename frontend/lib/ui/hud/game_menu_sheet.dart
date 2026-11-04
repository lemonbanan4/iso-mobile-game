import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_hooks.dart';
import '../../core/theme/game_theme.dart';
import '../../state/game_state_provider.dart';
import '../components/clay_button.dart';
import '../components/glass_card.dart';

/// Save / Reset / audio toggle menu (mobile-friendly).
class GameMenuSheet extends ConsumerWidget {
  const GameMenuSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    if (!state.showGameMenu) return const SizedBox.shrink();

    return Positioned.fill(
      child: Material(
        color: const Color(0xCC070A12),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                borderRadius: 28,
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
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
                              'OPS MENU',
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
                                .closeGameMenu(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: GameTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Syndicate Vault',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: GameTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Progress autosaves to browser localStorage. Manual save/reset available here.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: GameTheme.textSecondary.withValues(alpha: 0.95),
                        ),
                      ),
                      if (state.saveStatus != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          state.saveStatus!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: GameTheme.accentNeon,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      ClayButton(
                        isAccent: true,
                        onPressed: () =>
                            ref.read(gameStateProvider.notifier).saveGame(),
                        child: const Text(
                          'SAVE GAME',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Color(0xFF070A12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClayButton(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF10182A),
                              title: const Text('Reset empire?'),
                              content: const Text(
                                'This wipes localStorage and reloads a fresh sector.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'Reset',
                                    style: TextStyle(color: GameTheme.danger),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await ref
                                .read(gameStateProvider.notifier)
                                .resetGame();
                          }
                        },
                        child: const Text(
                          'RESET GAME',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: GameTheme.danger,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClayButton(
                        onPressed: () {
                          AudioHooks.instance.enabled =
                              !AudioHooks.instance.enabled;
                          AudioHooks.instance.uiClick();
                          ref
                              .read(gameStateProvider.notifier)
                              .pushEvent(
                                AudioHooks.instance.enabled
                                    ? 'Audio hooks armed.'
                                    : 'Audio hooks muted.',
                              );
                        },
                        child: Text(
                          AudioHooks.instance.enabled
                              ? 'MUTE AUDIO HOOKS'
                              : 'ENABLE AUDIO HOOKS',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: GameTheme.textPrimary,
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
      ),
    );
  }
}
