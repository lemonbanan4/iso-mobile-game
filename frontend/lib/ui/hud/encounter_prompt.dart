import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/syndicate/encounter_models.dart';
import '../../core/theme/game_theme.dart';
import '../../state/game_state_provider.dart';
import '../components/clay_button.dart';
import '../components/glass_card.dart';

/// Modal-style choice prompt for active syndicate encounters.
class EncounterPrompt extends ConsumerWidget {
  const EncounterPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final encounter = ref.watch(
      gameStateProvider.select((s) => s.pendingEncounter),
    );
    if (encounter == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: Material(
        color: const Color(0xE0070A12),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: GlassCard(
                  borderRadius: 28,
                  padding: const EdgeInsets.all(22),
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
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: GameTheme.accentMagenta.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                            child: const Text(
                              'ENCOUNTER',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.6,
                                color: GameTheme.accentMagenta,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.sensors_rounded,
                            color: GameTheme.accentNeon.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        encounter.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                          color: GameTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        encounter.body,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: GameTheme.textSecondary.withValues(alpha: 0.95),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...encounter.choices.map(
                        (choice) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ChoiceButton(
                            choice: choice,
                            onPressed: () {
                              ref
                                  .read(gameStateProvider.notifier)
                                  .resolveEncounter(choice.id);
                            },
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

class _ChoiceButton extends StatelessWidget {
  final EncounterChoice choice;
  final VoidCallback onPressed;

  const _ChoiceButton({required this.choice, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ClayButton(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            choice.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: GameTheme.textPrimary,
            ),
          ),
          if (!choice.delta.isEmpty) ...[
            const SizedBox(height: 4),
            Text(
              choice.delta.summary,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: GameTheme.accentNeon.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
