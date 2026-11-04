import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/math/iso_math.dart';
import '../core/syndicate/encounter_catalog.dart';
import 'tile_models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GameState {
  final Map<GridCoord, TileState> tiles;
  final GridCoord? selectedCoord;
  final int gold;
  final int science;
  final int production;
  final int food;
  final int currentTurn;
  final bool isSyncingWithServer;
  final String? lastMessage;
  final List<String> unlockedTechs;
  final Map<String, dynamic>? gachaPull;
  final List<String> eventLog;

  const GameState({
    required this.tiles,
    this.selectedCoord,
    this.gold = 150,
    this.science = 45,
    this.production = 80,
    this.food = 120,
    this.currentTurn = 1,
    this.isSyncingWithServer = false,
    this.lastMessage,
    this.unlockedTechs = const [],
    this.gachaPull,
    this.eventLog = const [],
  });

  // Syndicate HUD aliases (UI terminology ↔ API fields)
  int get credits => gold;
  int get contraband => production;
  int get loyalty => science;
  int get heat => food;

  TileState? get selectedTile =>
      selectedCoord != null ? tiles[selectedCoord] : null;

  // --- ENDGAME CONDITIONS ---
  bool get isDefeat {
    if (tiles.isEmpty) return false; // Don't trigger before the game loads

    // You lose if the Barbarians destroy your Capital Colony
    final hasCapital = tiles.values.any(
      (t) => t.entity?.type == 'city' && t.entity?.ownerFaction == 'Player 1',
    );
    return !hasCapital;
  }

  bool get isVictory {
    if (tiles.isEmpty) return false;

    // You win if there are absolutely zero Barbarians left on the map
    final hasBarbarians = tiles.values.any(
      (t) =>
          t.unit?.ownerFaction == 'Barbarians' ||
          t.entity?.ownerFaction == 'Barbarians',
    );
    return !hasBarbarians;
  }

  GameState copyWith({
    Map<GridCoord, TileState>? tiles,
    GridCoord? selectedCoord,
    bool clearSelection = false,
    int? gold,
    int? science,
    int? production,
    int? food,
    int? currentTurn,
    bool? isSyncingWithServer,
    String? lastMessage,
    List<String>? unlockedTechs,
    Map<String, dynamic>? gachaPull,
    bool clearGacha = false,
    List<String>? eventLog,
  }) {
    return GameState(
      tiles: tiles ?? this.tiles,
      selectedCoord: clearSelection
          ? null
          : (selectedCoord ?? this.selectedCoord),
      gold: gold ?? this.gold,
      science: science ?? this.science,
      production: production ?? this.production,
      food: food ?? this.food,
      currentTurn: currentTurn ?? this.currentTurn,
      isSyncingWithServer: isSyncingWithServer ?? this.isSyncingWithServer,
      lastMessage: lastMessage ?? this.lastMessage,
      unlockedTechs: unlockedTechs ?? this.unlockedTechs,
      gachaPull: clearGacha ? null : (gachaPull ?? this.gachaPull),
      eventLog: eventLog ?? this.eventLog,
    );
  }
}

class GameNotifier extends Notifier<GameState> {
  static const int _maxEventLog = 12;

  @override
  GameState build() {
    // Kick off server fetch immediately when Riverpod initializes
    Future.microtask(() => fetchWorldState());
    return GameState(
      tiles: const {},
      eventLog: EncounterCatalog.seedLog(),
    );
  }

  void pushEvent(String message) {
    final next = [message, ...state.eventLog];
    if (next.length > _maxEventLog) {
      next.removeRange(_maxEventLog, next.length);
    }
    state = state.copyWith(eventLog: next, lastMessage: message);
  }

  Future<void> fetchWorldState() async {
    state = state.copyWith(isSyncingWithServer: true);

    try {
      final url = Uri.parse('http://127.0.0.1:8000/v1/world/tiles');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tilesList = data['tiles'] as List;

        final serverTiles = <GridCoord, TileState>{};

        for (final tileData in tilesList) {
          final tile = _parseServerTile(tileData);
          serverTiles[tile.coord] = tile;
        }

        state = state.copyWith(
          tiles: serverTiles,
          selectedCoord: const GridCoord(0, 0), // default camera center point
          isSyncingWithServer: false,
          lastMessage: 'District grid synchronized with syndicate net.',
        );
        pushEvent('Uplink live — district grid synchronized.');
      } else {
        state = state.copyWith(
          isSyncingWithServer: false,
          lastMessage: 'Server returned error: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Fetch world error: $e\n$stackTrace');
      state = state.copyWith(
        isSyncingWithServer: false,
        lastMessage: 'Failed to connect backend server.',
      );
    }
  }

  void selectTile(GridCoord targetCoord) {
    final currentlySelected = state.selectedTile;

    // Check if we have an active unit selected
    if (currentlySelected != null && currentlySelected.coord != targetCoord) {
      final activeUnit = currentlySelected.unit;

      if (activeUnit != null &&
          activeUnit.ownerFaction == 'Player 1' &&
          ['scout', 'warrior', 'hero'].contains(activeUnit.type)) {
        final targetTile = state.tiles[targetCoord];

        // Identify if the target tile has hostile occupants
        final hasEnemyUnit =
            targetTile?.unit != null &&
            targetTile!.unit!.ownerFaction != 'Player 1';
        final hasEnemyBuilding =
            targetTile?.entity != null &&
            targetTile!.entity!.ownerFaction != 'Player 1';

        if (hasEnemyUnit || hasEnemyBuilding) {
          attackTarget(source: currentlySelected.coord, target: targetCoord);
          return;
        } else {
          moveUnit(source: currentlySelected.coord, target: targetCoord);
          return;
        }
      }
    }

    // Default: Just selected the tile to open the inspector
    if (state.tiles.containsKey(targetCoord)) {
      state = state.copyWith(selectedCoord: targetCoord);
    }
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }

  /// Optimistically executes a tile action (e.g. Build Farm, Found Outpost)
  Future<void> executeTileAction({
    required GridCoord target,
    required String actionType,
  }) async {
    final currentTile = state.tiles[target];
    if (currentTile == null) return;

    // 1. Snapshot the old state in case the server rejects the move
    final previousState = state;

    // 2. Optimistic local update (make the UI feel instant)
    state = state.copyWith(isSyncingWithServer: true);

    TileEntity? newEntity;
    TileEntity? newUnit;
    int goldCost = 0;
    int prodCost = 0;

    switch (actionType) {
      case 'build_farm':
        goldCost = 30;
        prodCost = 20;
        newEntity = TileEntity(
          id: 'farm_${target.x}_${target.y}',
          name: 'Hydroponic Farm',
          type: 'farm',
          ownerFaction: 'Player 1',
        );
        break;
      case 'build_tavern':
        goldCost = 100;
        prodCost = 50;
        newEntity = TileEntity(
          id: 'tavern_${target.x}_${target.y}',
          name: 'Grand Tavern',
          type: 'tavern',
          ownerFaction: 'Player 1',
        );
        break;
      case 'build_mine':
        goldCost = 40;
        prodCost = 25;
        newEntity = TileEntity(
          id: 'mine_${target.x}_${target.y}',
          name: 'Extraction Mine',
          type: 'mine',
          ownerFaction: 'Player 1',
        );
        break;
      case 'build_barracks':
        goldCost = 60;
        prodCost = 40;
        newEntity = TileEntity(
          id: 'barracks_${target.x}_${target.y}',
          name: 'Garrison Barracks',
          type: 'barracks',
          ownerFaction: 'Player 1',
        );
        break;
      case 'found_outpost':
        goldCost = 75;
        prodCost = 50;
        newEntity = TileEntity(
          id: 'outpost_${target.x}_${target.y}',
          name: 'Frontier Outpost',
          type: 'city',
          ownerFaction: 'Player 1',
        );
        break;
      case 'train_warrior':
        goldCost = 25;
        prodCost = 15;
        newUnit = TileEntity(
          id: ' warrior_${target.x}_${target.y}',
          name: 'Axe Warrior',
          type: 'warrior',
          ownerFaction: 'Player 1',
        );
        break;
      case 'summon_commander':
        goldCost = 100;
        prodCost = 0;
        // The server RNG decides the actual hero.
        // Spawning placeholder unit until the server responds
        newUnit = TileEntity(
          id: 'summon_${target.x}_${target.y}',
          name: 'Summoning...',
          type: 'hero',
          ownerFaction: 'Player 1',
        );
        break;
      default:
        break;
    }

    if (state.gold < goldCost || state.production < prodCost) {
      state = state.copyWith(
        isSyncingWithServer: false,
        lastMessage: 'Insufficient resources for action: $actionType',
      );
      return;
    }

    final updatedTileOptimistic = currentTile.copyWith(
      entity: newEntity ?? currentTile.entity,
      unit: newUnit ?? currentTile.unit,
      territoryOwner: 'Player 1',
    );

    final updatedTiles = Map<GridCoord, TileState>.from(state.tiles);
    updatedTiles[target] = updatedTileOptimistic;

    state = state.copyWith(
      tiles: updatedTiles,
      gold: state.gold - goldCost,
      production: state.production - prodCost,
      lastMessage: 'Action $actionType executed successfully',
    );

    // 3. Send the actual HTTP POST request to the FastAPI Server
    try {
      // Ensure this URL matches the exact endpoint generated in actions.py router
      final url = Uri.parse('http://127.0.0.1:8000/v1/actions');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'target_x': target.x,
          'target_y': target.y,
          'action_type': actionType,
          'player_id': 'Player 1',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final updatedTile = _parseServerTile(data['tile'] ?? data);

        // Update the Map correctly using the target coordinate key
        final confirmedTiles = Map<GridCoord, TileState>.from(state.tiles);
        confirmedTiles[target] = updatedTile;

        // Server confirmed: update both the map and selectedTile with server readyAt
        state = state.copyWith(
          tiles: confirmedTiles,
          isSyncingWithServer: false,
          lastMessage: 'Action $actionType confirmed by server.',
          gachaPull: data['gacha_result'],
        );
      } else {
        // Server rejected the move (e.g., TileConflictError, GameRuleViolation)
        final errorData = jsonDecode(response.body);
        print('SERVER REJECTED ACTION: ${errorData["detail"]}');
        state = previousState.copyWith(
          isSyncingWithServer: false,
          lastMessage:
              'Server rejected move: ${errorData["detail"] ?? "Unknown error"}',
        );
      }
    } catch (e) {
      // Network failure (server is down)
      debugPrint('executeTileAction error: $e');
      state = previousState.copyWith(
        isSyncingWithServer: false,
        lastMessage: 'Network error. Cannot reach server.',
      );
    }

    // // 2. Simulate API reconciliation delay (in production: OpenAPI Client call)
    // await Future.delayed(const Duration(milliseconds: 300));
    // state = state.copyWith(isSyncingWithServer: false);
  }

  Future<void> nextTurn() async {
    state = state.copyWith(isSyncingWithServer: true);

    try {
      // Pointing to the endpoint defined in turns.py router
      final url = Uri.parse('http://127.0.0.1:8000/v1/turns/end');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          // The Python EndTurnRequest model expects the current turn to verify sync
          'turn': state.currentTurn,
          'player_id': 'Player 1',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newResources = data['resources'];

        // Download the map to show Barbarian movements and damage taken!
        fetchWorldState();

        final turnMessage =
            data['message'] as String? ?? 'Cycle closed. Yields secured.';
        final encounter = EncounterCatalog.randomEncounter();

        state = state.copyWith(
          currentTurn: data['current_turn'] ?? state.currentTurn + 1,
          gold: newResources['gold'] ?? state.gold,
          science: newResources['science'] ?? state.science,
          production: newResources['production'] ?? state.production,
          food: newResources['food'] ?? state.food,
          isSyncingWithServer: false,
          lastMessage: turnMessage,
          unlockedTechs: data['unlocked_techs'] != null
              ? List<String>.from(data['unlocked_techs'])
              : state.unlockedTechs,
        );
        pushEvent(turnMessage);
        pushEvent(encounter);
      } else {
        final errorData = jsonDecode(response.body);
        state = state.copyWith(
          isSyncingWithServer: false,
          lastMessage: 'Turn error: ${errorData["detail"] ?? "Unknown"}',
        );
      }
    } catch (e, stacktrace) {
      debugPrint('NextTurn Crash: $e\n$stacktrace');
      state = state.copyWith(
        isSyncingWithServer: false,
        lastMessage: 'Client crash parsing turn data. Check console.',
      );
    }
  }

  Future<void> moveUnit({
    required GridCoord source,
    required GridCoord target,
  }) async {
    final previousState = state;
    state = state.copyWith(isSyncingWithServer: true);

    final currentTiles = Map<GridCoord, TileState>.from(state.tiles);
    final sourceTile = currentTiles[source];
    final targetTile = currentTiles[target];

    // 1. Safety check: Ensure the tile actually has a UNIT to move
    if (sourceTile == null || targetTile == null || sourceTile.unit == null) {
      state = state.copyWith(isSyncingWithServer: false);
      return;
    }

    final unitToMove = sourceTile.unit;

    // 2. Optimistic Local Update
    // Clear the unit from the old tile (but keep the building!)
    currentTiles[source] = sourceTile.copyWith(clearUnit: true);

    // Place the unit on the new tile
    currentTiles[target] = targetTile.copyWith(unit: unitToMove);

    state = state.copyWith(
      tiles: currentTiles,
      selectedCoord: target,
      lastMessage: 'Moving unit...',
    );

    // 3. Authoritative Server Validation
    try {
      final url = Uri.parse('http://127.0.0.1:8000/v1/actions/move');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'from_x': source.x,
          'from_y': source.y,
          'to_x': target.x, // FIXED: Was previously source.x!
          'to_y': target.y, // FIXED: Was previously source.y!
          'player_id': 'Player 1',
        }),
      );

      if (response.statusCode == 200) {
        // SUCCESS: Download the newly illuminated Fog of War tiles!
        fetchWorldState();

        state = state.copyWith(
          isSyncingWithServer: false,
          lastMessage: 'Unit arrived.',
        );
      } else {
        final errorData = jsonDecode(response.body);
        state = previousState.copyWith(
          isSyncingWithServer: false,
          lastMessage: 'Invalid move: ${errorData["detail"]}',
        );
      }
    } catch (e) {
      state = previousState.copyWith(
        isSyncingWithServer: false,
        lastMessage: 'Network error. Move cancelled.',
      );
    }
  }

  Future<void> attackTarget({
    required GridCoord source,
    required GridCoord target,
  }) async {
    state = state.copyWith(
      isSyncingWithServer: true,
      lastMessage: 'Attacking...',
    );

    try {
      final url = Uri.parse('http://127.0.0.1:8000/v1/actions/combat');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'source_x': source.x,
          'source_y': source.y,
          'target_x': target.x,
          'target_y': target.y,
          'player_id': 'Player 1',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final updatedSource = _parseServerTile(data['source_tile']);
        final updatedTarget = _parseServerTile(data['target_tile']);

        final currentTiles = Map<GridCoord, TileState>.from(state.tiles);
        currentTiles[source] = updatedSource;
        currentTiles[target] = updatedTarget;

        state = state.copyWith(
          tiles: currentTiles,
          isSyncingWithServer: false,
          lastMessage: data['message'],
        );
      } else {
        final errorData = jsonDecode(response.body);
        state = state.copyWith(
          isSyncingWithServer: false,
          lastMessage: 'Attack failed: ${errorData["detail"]}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSyncingWithServer: false,
        lastMessage: 'Network error. Combat cancelled.',
      );
    }
  }

  Future<void> useSpeedUp(GridCoord target) async {
    state = state.copyWith(
      isSyncingWithServer: true,
      lastMessage: 'Applying Speed-Up...',
    );

    try {
      final url = Uri.parse('http://127.0.0.1:8000/v1/actions/speedup');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'target_x': target.x,
          'target_y': target.y,
          'player_id': 'Player 1',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedTile = _parseServerTile(data['tile']);

        final currentTiles = Map<GridCoord, TileState>.from(state.tiles);
        currentTiles[target] = updatedTile;

        state = state.copyWith(
          tiles: currentTiles,
          isSyncingWithServer: false,
          lastMessage: data['message'],
        );
      } else {
        final errorData = jsonDecode(response.body);
        state = state.copyWith(
          isSyncingWithServer: false,
          lastMessage: 'Speed-Up failed. ${errorData["detail"]}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSyncingWithServer: false,
        lastMessage: 'Network error. Could not apply item.',
      );
    }
  }

  Future<void> researchTech(String techId) async {
    state = state.copyWith(isSyncingWithServer: true);

    try {
      final url = Uri.parse('http://127.0.0.1:8000/v1/actions/research');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tech_id': techId, 'player_id': 'Player 1'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final resources = data['resources'];

        state = state.copyWith(
          isSyncingWithServer: false,
          //science: data['remaining_science'],
          science: resources != null ? resources['science'] : state.science,
          //lastMessage: data['message'],
          unlockedTechs: data['unlocked_techs'] != null
              ? List<String>.from(data['unlocked_techs'])
              : state.unlockedTechs,
          lastMessage: 'Successfully researched $techId!',
        );
      } else {
        final errorData = jsonDecode(response.body);
        state = state.copyWith(
          isSyncingWithServer: false,
          lastMessage: 'Research failed: ${errorData["detail"]}',
        );
      }
    } catch (e, stacktrace) {
      debugPrint('Research Crash: $e\n$stacktrace');
      state = state.copyWith(
        isSyncingWithServer: false,
        lastMessage: 'Client crash parsing research. Check console.',
      );
    }
  }

  TileState _parseServerTile(Map<String, dynamic> data) {
    final coord = GridCoord(data['coord']['x'], data['coord']['y']);

    TileEntity? entity;
    if (data['entity'] != null) {
      entity = TileEntity(
        id: data['entity']['id'] ?? 'entity_${coord.x}_${coord.y}',
        name:
            data['entity']['name'] ??
            data['entity']['type'].toString().toUpperCase(),
        type: data['entity']['type'],
        ownerFaction: data['entity']['owner_faction'],
        health: data['entity']['health'] ?? 100,
        maxHealth: data['entity']['max_health'] ?? 100,
        readyAt: data['entity']['ready_at'],
      );
    }

    TileEntity? unit;
    if (data['unit'] != null) {
      unit = TileEntity(
        id: data['unit']['id'] ?? 'unit_${coord.x}_${coord.y}',
        name: data['unit']['name'] ?? 'Unit',
        type: data['unit']['type'],
        ownerFaction: data['unit']['owner_faction'],
        health: data['unit']['health'] ?? 100,
        maxHealth: data['unit']['max_health'] ?? 100,
        readyAt: data['unit']['ready_at'],
      );
    }

    final terrainString = data['type'] as String;
    final tileType = TileType.values.firstWhere(
      (e) => e.name == terrainString,
      orElse: () => TileType.plains,
    );

    return TileState(
      coord: coord,
      type: tileType,
      yields: ResourceYield.forTileType(tileType),
      entity: entity,
      unit: unit,
      territoryOwner: data['territory_owner'],
    );
  }

  void clearGachaPull() {
    state = state.copyWith(clearGacha: true);
  }
}

final gameStateProvider = NotifierProvider<GameNotifier, GameState>(
  GameNotifier.new,
);
