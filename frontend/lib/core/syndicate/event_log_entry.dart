import 'package:flutter/material.dart';

import '../theme/game_theme.dart';

/// Severity for color-coded event ticker rows.
enum EventKind { gain, heat, rival, crisis, system, neutral }

class EventLogEntry {
  final String message;
  final EventKind kind;
  final DateTime at;

  const EventLogEntry({
    required this.message,
    this.kind = EventKind.neutral,
    required this.at,
  });

  Color get color {
    switch (kind) {
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
        return GameTheme.textPrimary;
    }
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'kind': kind.name,
        'at': at.toIso8601String(),
      };

  factory EventLogEntry.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String? ?? 'neutral';
    return EventLogEntry(
      message: json['message'] as String? ?? '',
      kind: EventKind.values.firstWhere(
        (k) => k.name == kindName,
        orElse: () => EventKind.neutral,
      ),
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Heuristic classifier for free-form ticker strings.
  static EventKind infer(String message) {
    final m = message.toLowerCase();
    if (m.contains('rival') || m.contains('turf') || m.contains('skimmed')) {
      return EventKind.rival;
    }
    if (m.contains('heat') ||
        m.contains('police') ||
        m.contains('raid') ||
        m.contains('busted') ||
        m.contains('crisis')) {
      return EventKind.heat;
    }
    if (m.contains('dominance') ||
        m.contains('mutiny') ||
        m.contains('crisis —')) {
      return EventKind.crisis;
    }
    if (m.contains('+') &&
        (m.contains('credit') ||
            m.contains('contraband') ||
            m.contains('loyalty') ||
            m.contains('tick') ||
            m.contains('ledger'))) {
      return EventKind.gain;
    }
    if (m.contains('uplink') ||
        m.contains('saved') ||
        m.contains('reset') ||
        m.contains('synchronized')) {
      return EventKind.system;
    }
    return EventKind.neutral;
  }
}

/// One floating +/− resource popup above a district.
class FloatingYieldEvent {
  final int x;
  final int y;
  final String label;
  final int colorValue;

  const FloatingYieldEvent({
    required this.x,
    required this.y,
    required this.label,
    required this.colorValue,
  });

  Color get color => Color(colorValue);
}
