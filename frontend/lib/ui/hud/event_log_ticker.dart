import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/syndicate/event_log_entry.dart';
import '../../core/theme/game_theme.dart';
import '../../state/game_state_provider.dart';
import '../components/glass_card.dart';

/// Compact horizontal ticker with color-coded syndicate alerts.
class EventLogTicker extends ConsumerWidget {
  const EventLogTicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(gameStateProvider.select((s) => s.eventLog));
    if (events.isEmpty) return const SizedBox.shrink();

    final latestKind = events.first.kind;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: GameTheme.surfaceGlass.withValues(alpha: 0.55),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: latestKind.badgeColor.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: latestKind.badgeColor.withValues(alpha: 0.55),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: latestKind.badgeColor.withValues(alpha: 0.25),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    latestKind.badgeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      color: latestKind.badgeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: events.length,
                      separatorBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '◆',
                          style: TextStyle(
                            color: GameTheme.accentNeon.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      ),
                      itemBuilder: (context, index) {
                        final entry = events[index];
                        final isLatest = index == 0;
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 220),
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.25,
                                fontWeight: isLatest
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: entry.color.withValues(
                                  alpha: isLatest ? 1.0 : 0.72,
                                ),
                              ),
                              child: Text(
                                entry.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on EventKind {
  String get badgeLabel {
    switch (this) {
      case EventKind.gain:
        return 'GAIN';
      case EventKind.heat:
        return 'HEAT';
      case EventKind.rival:
        return 'RIVAL';
      case EventKind.crisis:
        return 'ALERT';
      case EventKind.system:
        return 'NET';
      case EventKind.neutral:
        return 'NET';
    }
  }

  Color get badgeColor {
    switch (this) {
      case EventKind.gain:
        return const Color(0xFF4ADE80);
      case EventKind.heat:
        return GameTheme.heat;
      case EventKind.rival:
        return const Color(0xFFFBBF24);
      case EventKind.crisis:
        return GameTheme.danger;
      case EventKind.system:
        return GameTheme.accentNeon;
      case EventKind.neutral:
        return GameTheme.danger;
    }
  }
}
