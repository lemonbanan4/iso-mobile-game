import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/math/iso_math.dart';
import '../core/syndicate/event_log_entry.dart';
import 'game_state_provider.dart';
import 'tile_models.dart';

/// Browser localStorage (via SharedPreferences) persistence for syndicate progress.
class SaveRepository {
  static const storageKey = 'iso_syndicate_save_v1';
  static const int schemaVersion = 1;

  Future<bool> hasSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(storageKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  Future<void> save(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'version': schemaVersion,
      'savedAt': DateTime.now().toIso8601String(),
      'gold': state.gold,
      'science': state.science,
      'production': state.production,
      'food': state.food,
      'currentTurn': state.currentTurn,
      'unlockedTechs': state.unlockedTechs,
      'selected': state.selectedCoord == null
          ? null
          : {'x': state.selectedCoord!.x, 'y': state.selectedCoord!.y},
      'endgameReason': state.endgameReason,
      'economyPaused': state.economyPaused,
      'eventLog': state.eventLog.map((e) => e.toJson()).toList(),
      'tiles': state.tiles.values.map((t) => t.toJson()).toList(),
    };
    await prefs.setString(storageKey, jsonEncode(payload));
  }

  Future<GameState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final tilesList = (data['tiles'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      final tiles = <GridCoord, TileState>{};
      for (final tileJson in tilesList) {
        final tile = TileState.fromJson(tileJson);
        tiles[tile.coord] = tile;
      }

      final eventsRaw = (data['eventLog'] as List? ?? const []);
      final events = <EventLogEntry>[];
      for (final e in eventsRaw) {
        if (e is String) {
          events.add(
            EventLogEntry(
              message: e,
              kind: EventLogEntry.infer(e),
              at: DateTime.now(),
            ),
          );
        } else if (e is Map<String, dynamic>) {
          events.add(EventLogEntry.fromJson(e));
        }
      }

      GridCoord? selected;
      final sel = data['selected'];
      if (sel is Map<String, dynamic>) {
        selected = GridCoord(sel['x'] as int, sel['y'] as int);
      }

      return GameState(
        tiles: tiles,
        selectedCoord: selected,
        gold: data['gold'] as int? ?? 420,
        science: data['science'] as int? ?? 68,
        production: data['production'] as int? ?? 55,
        food: data['food'] as int? ?? 18,
        currentTurn: data['currentTurn'] as int? ?? 1,
        unlockedTechs: (data['unlockedTechs'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        eventLog: events,
        endgameReason: data['endgameReason'] as String?,
        economyPaused: data['economyPaused'] as bool? ?? false,
        lastMessage: 'Save restored from local vault.',
      );
    } catch (_) {
      return null;
    }
  }
}
