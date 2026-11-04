import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/audio/audio_hooks.dart';
import '../core/math/iso_math.dart';
import '../core/syndicate/encounter_catalog.dart';
import '../core/syndicate/encounter_models.dart';
import '../core/syndicate/event_log_entry.dart';
import '../core/syndicate/facility_catalog.dart';
import '../core/syndicate/rival_ai.dart';
import '../core/theme/game_theme.dart';
import 'save_repository.dart';
import 'tile_models.dart';

class GameState {
  static const int victoryCreditTarget = 50000;
  static const int victorySectorTarget = 15;
  static const int heatCrisisThreshold = 100;
  static const int loyaltyMutinyThreshold = 0;

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
  final List<EventLogEntry> eventLog;
  final SyndicateEncounter? pendingEncounter;
  final bool showBuildMenu;
  final bool showGameMenu;
  final String? endgameReason;
  final bool economyPaused;
  final List<FloatingYieldEvent> pendingFloaters;
  final String? saveStatus;

  const GameState({
    required this.tiles,
    this.selectedCoord,
    this.gold = 420,
    this.science = 68,
    this.production = 55,
    this.food = 18,
    this.currentTurn = 1,
    this.isSyncingWithServer = false,
    this.lastMessage,
    this.unlockedTechs = const [],
    this.gachaPull,
    this.eventLog = const [],
    this.pendingEncounter,
    this.showBuildMenu = false,
    this.showGameMenu = false,
    this.endgameReason,
    this.economyPaused = false,
    this.pendingFloaters = const [],
    this.saveStatus,
  });

  // Syndicate HUD aliases (UI terminology ↔ API fields)
  int get credits => gold;
  int get contraband => production;
  int get loyalty => science;
  int get heat => food;

  TileState? get selectedTile =>
      selectedCoord != null ? tiles[selectedCoord] : null;

  int get controlledSectors => tiles.values
      .where((t) => t.territoryOwner == 'Player 1')
      .length;

  bool get isGameOver => endgameReason != null || isVictory || isDefeat;

  // --- ENDGAME CONDITIONS ---
  bool get isDefeat {
    if (tiles.isEmpty) return false;
    if (heat >= heatCrisisThreshold) return true;
    if (loyalty <= loyaltyMutinyThreshold) return true;

    final hasCapital = tiles.values.any(
      (t) => t.entity?.type == 'city' && t.entity?.ownerFaction == 'Player 1',
    );
    return !hasCapital;
  }

  bool get isVictory {
    if (tiles.isEmpty) return false;
    return credits >= victoryCreditTarget &&
        controlledSectors >= victorySectorTarget;
  }

  String get defeatDetail {
    if (heat >= heatCrisisThreshold) {
      return 'Heat hit $heatCrisisThreshold%. Police raided the net — syndicate burned.';
    }
    if (loyalty <= loyaltyMutinyThreshold) {
      return 'Loyalty collapsed. The crews mutinied and walked.';
    }
    return 'Your capital cell fell. The syndicate is dust.';
  }

  String get victoryDetail =>
      'Ledger cleared $victoryCreditTarget Credits across $controlledSectors districts. Sector is yours.';

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
    List<EventLogEntry>? eventLog,
    SyndicateEncounter? pendingEncounter,
    bool clearPendingEncounter = false,
    bool? showBuildMenu,
    bool? showGameMenu,
    String? endgameReason,
    bool clearEndgame = false,
    bool? economyPaused,
    List<FloatingYieldEvent>? pendingFloaters,
    bool clearFloaters = false,
    String? saveStatus,
    bool clearSaveStatus = false,
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
      pendingEncounter: clearPendingEncounter
          ? null
          : (pendingEncounter ?? this.pendingEncounter),
      showBuildMenu: showBuildMenu ?? this.showBuildMenu,
      showGameMenu: showGameMenu ?? this.showGameMenu,
      endgameReason: clearEndgame ? null : (endgameReason ?? this.endgameReason),
      economyPaused: economyPaused ?? this.economyPaused,
      pendingFloaters:
          clearFloaters ? const [] : (pendingFloaters ?? this.pendingFloaters),
      saveStatus: clearSaveStatus ? null : (saveStatus ?? this.saveStatus),
    );
  }
}

class GameNotifier extends Notifier<GameState> {
  static const int _maxEventLog = 16;
  static const Duration _economyInterval = Duration(seconds: 5);
  static const Duration _rivalInterval = Duration(seconds: 9);

  final RivalAiSimulator _rivalAi = RivalAiSimulator();
  final SaveRepository _saves = SaveRepository();
  Timer? _autosaveDebounce;

  @override
  GameState build() {
    final economyTimer = Timer.periodic(_economyInterval, (_) => tickEconomy());
    final rivalTimer = Timer.periodic(_rivalInterval, (_) => tickRivalAi());
    ref.onDispose(() {
      economyTimer.cancel();
      rivalTimer.cancel();
      _autosaveDebounce?.cancel();
    });

    Future.microtask(() => _bootstrap());
    return GameState(
      tiles: const {},
      eventLog: EncounterCatalog.seedLog()
          .map(
            (m) => EventLogEntry(
              message: m,
              kind: EventLogEntry.infer(m),
              at: DateTime.now(),
            ),
          )
          .toList(),
    );
  }

  Future<void> _bootstrap() async {
    final saved = await _saves.load();
    if (saved != null && saved.tiles.isNotEmpty) {
      state = saved;
      pushEvent('Local vault restored — empire intact.', kind: EventKind.system);
      return;
    }
    await fetchWorldState();
  }

  void pushEvent(String message, {EventKind? kind}) {
    final entry = EventLogEntry(
      message: message,
      kind: kind ?? EventLogEntry.infer(message),
      at: DateTime.now(),
    );
    final next = [entry, ...state.eventLog];
    if (next.length > _maxEventLog) {
      next.removeRange(_maxEventLog, next.length);
    }
    state = state.copyWith(eventLog: next, lastMessage: message);

    switch (entry.kind) {
      case EventKind.rival:
        AudioHooks.instance.rivalPing();
      case EventKind.heat:
      case EventKind.crisis:
        AudioHooks.instance.alertSiren();
      case EventKind.gain:
        AudioHooks.instance.gainChime();
      default:
        break;
    }
  }

  void openBuildMenu() {
    if (state.isGameOver) return;
    final tile = state.selectedTile;
    if (tile == null || tile.entity != null) return;
    AudioHooks.instance.uiClick();
    state = state.copyWith(showBuildMenu: true);
  }

  void closeBuildMenu() {
    state = state.copyWith(showBuildMenu: false);
  }

  void openGameMenu() {
    AudioHooks.instance.uiClick();
    state = state.copyWith(showGameMenu: true);
  }

  void closeGameMenu() {
    state = state.copyWith(showGameMenu: false);
  }

  Future<void> saveGame({bool manual = true}) async {
    await _saves.save(state);
    if (manual) {
      state = state.copyWith(
        saveStatus: 'Empire vaulted to localStorage.',
        showGameMenu: false,
      );
      pushEvent('Manual save committed to local vault.', kind: EventKind.system);
      AudioHooks.instance.uiClick();
    }
  }

  void _scheduleAutosave() {
    _autosaveDebounce?.cancel();
    _autosaveDebounce = Timer(const Duration(milliseconds: 800), () {
      _saves.save(state);
    });
  }

  Future<void> resetGame() async {
    await _saves.clear();
    state = state.copyWith(
      showGameMenu: false,
      clearEndgame: true,
      economyPaused: false,
      showBuildMenu: false,
      clearPendingEncounter: true,
      clearFloaters: true,
      gold: 420,
      science: 68,
      production: 55,
      food: 18,
      currentTurn: 1,
      tiles: const {},
      eventLog: EncounterCatalog.seedLog()
          .map(
            (m) => EventLogEntry(
              message: m,
              kind: EventLogEntry.infer(m),
              at: DateTime.now(),
            ),
          )
          .toList(),
      saveStatus: 'Save wiped. Rebooting sector…',
    );
    pushEvent('Reset — criminal empire wiped from local vault.', kind: EventKind.system);
    AudioHooks.instance.alertSiren();
    await fetchWorldState();
  }

  void clearPendingFloaters() {
    if (state.pendingFloaters.isEmpty) return;
    state = state.copyWith(clearFloaters: true);
  }

  void _evaluateEndgame() {
    if (state.endgameReason != null) return;
    if (state.isVictory) {
      state = state.copyWith(
        endgameReason: 'victory',
        economyPaused: true,
        showBuildMenu: false,
        clearPendingEncounter: true,
        lastMessage: state.victoryDetail,
      );
      pushEvent('DOMINANCE — ${state.victoryDetail}', kind: EventKind.crisis);
      AudioHooks.instance.alertSiren();
      _scheduleAutosave();
      return;
    }
    if (state.isDefeat) {
      state = state.copyWith(
        endgameReason: 'defeat',
        economyPaused: true,
        showBuildMenu: false,
        clearPendingEncounter: true,
        lastMessage: state.defeatDetail,
      );
      pushEvent('CRISIS — ${state.defeatDetail}', kind: EventKind.crisis);
      AudioHooks.instance.alertSiren();
      _scheduleAutosave();
    }
  }

  /// Passive income from owned facilities every 5 seconds.
  void tickEconomy() {
    if (state.economyPaused || state.isGameOver || state.tiles.isEmpty) return;

    var creditsGain = 0;
    var contrabandGain = 0;
    var heatGain = 0;
    var loyaltyGain = 0;
    var facilityCount = 0;

    for (final tile in state.tiles.values) {
      final entity = tile.entity;
      if (entity == null || entity.ownerFaction != 'Player 1') continue;
      final blueprint = FacilityCatalog.byEntityType(entity.type);
      if (blueprint == null) continue;
      facilityCount++;
      creditsGain += blueprint.tickCredits;
      contrabandGain += blueprint.tickContraband;
      heatGain += blueprint.tickHeat;
      loyaltyGain += blueprint.tickLoyalty;
    }

    // Capital cell soft income so empty starts still drip
    final capitals = state.tiles.values.where(
      (t) => t.entity?.type == 'city' && t.entity?.ownerFaction == 'Player 1',
    );
    creditsGain += capitals.length * 3;

    if (facilityCount == 0 && capitals.isEmpty) return;

    final floaters = <FloatingYieldEvent>[];
    // Anchor popups on capital / first facility for feedback
    final anchor = state.tiles.values.firstWhere(
      (t) =>
          t.entity?.ownerFaction == 'Player 1' &&
          (FacilityCatalog.byEntityType(t.entity!.type) != null ||
              t.entity!.type == 'city'),
      orElse: () => state.tiles.values.first,
    );
    if (creditsGain > 0) {
      floaters.add(
        FloatingYieldEvent(
          x: anchor.coord.x,
          y: anchor.coord.y,
          label: '+$creditsGain Credits',
          colorValue: GameTheme.credits.toARGB32(),
        ),
      );
    }
    if (contrabandGain > 0) {
      floaters.add(
        FloatingYieldEvent(
          x: anchor.coord.x,
          y: anchor.coord.y,
          label: '+$contrabandGain Contraband',
          colorValue: GameTheme.contraband.toARGB32(),
        ),
      );
    }
    if (heatGain != 0) {
      floaters.add(
        FloatingYieldEvent(
          x: anchor.coord.x,
          y: anchor.coord.y,
          label: '${heatGain > 0 ? '+' : ''}$heatGain Heat',
          colorValue: GameTheme.heat.toARGB32(),
        ),
      );
    }

    state = state.copyWith(
      gold: state.gold + creditsGain,
      production: (state.production + contrabandGain).clamp(0, 999999),
      food: (state.food + heatGain).clamp(0, 100),
      science: (state.science + loyaltyGain).clamp(0, 100),
      pendingFloaters: floaters,
      lastMessage:
          'Facility tick — +$creditsGain Credits · +$contrabandGain Contraband',
    );
    pushEvent(
      'Facility tick — +$creditsGain Credits · +$contrabandGain Contraband',
      kind: EventKind.gain,
    );
    _scheduleAutosave();
    _evaluateEndgame();
  }

  /// Background rival syndicate moves.
  void tickRivalAi() {
    if (state.economyPaused || state.isGameOver || state.tiles.isEmpty) return;

    final result = _rivalAi.tick(state.tiles);
    if (result == null) return;

    state = state.copyWith(
      tiles: result.tiles ?? state.tiles,
      gold: (state.gold + result.creditsDelta).clamp(0, 999999),
      production: (state.production + result.contrabandDelta).clamp(0, 999999),
      science: (state.science + result.loyaltyDelta).clamp(0, 100),
      food: (state.food + result.heatDelta).clamp(0, 100),
      lastMessage: result.tickerMessage,
    );
    pushEvent(result.tickerMessage, kind: EventKind.rival);
    _scheduleAutosave();
    _evaluateEndgame();
  }

  /// Place a facility from the building menu onto the selected district.
  Future<void> placeFacility(FacilityBlueprint facility) async {
    final target = state.selectedCoord;
    if (target == null || state.isGameOver) return;

    final tile = state.tiles[target];
    if (tile == null || tile.entity != null) {
      pushEvent('Cannot plant ${facility.name} — district occupied.');
      return;
    }
    if (tile.type == TileType.water || tile.type == TileType.mountain) {
      pushEvent('Terrain rejects ${facility.name}.');
      return;
    }
    if (state.credits < facility.creditCost ||
        state.contraband < facility.contrabandCost) {
      pushEvent('Insufficient ledger for ${facility.name}.');
      return;
    }

    state = state.copyWith(showBuildMenu: false);
    await executeTileAction(target: target, actionType: facility.actionType);
    AudioHooks.instance.buildPlace();
    _scheduleAutosave();
  }

  /// Apply a choice from the active encounter prompt and update the ledger.
  void resolveEncounter(String choiceId) {
    final encounter = state.pendingEncounter;
    if (encounter == null) return;

    EncounterChoice? choice;
    for (final c in encounter.choices) {
      if (c.id == choiceId) {
        choice = c;
        break;
      }
    }
    if (choice == null) return;

    final delta = choice.delta;
    state = state.copyWith(
      gold: (state.gold + delta.credits).clamp(0, 999999),
      production: (state.production + delta.contraband).clamp(0, 999999),
      science: (state.science + delta.loyalty).clamp(0, 100),
      food: (state.food + delta.heat).clamp(0, 100),
      clearPendingEncounter: true,
      lastMessage: choice.outcome,
    );
    pushEvent('${encounter.title}: ${choice.outcome}');
    if (!delta.isEmpty) {
      pushEvent('Ledger shift — ${delta.summary}');
    }
    _evaluateEndgame();
  }

  void _maybeSurfaceEncounter({double chance = 0.55}) {
    if (state.pendingEncounter != null) return;
    final prompt = EncounterCatalog.maybePrompt(chance: chance);
    if (prompt == null) return;
    state = state.copyWith(pendingEncounter: prompt);
    pushEvent('Signal spike — ${prompt.title} demands a call.');
  }

  /// Soft reboot after victory/defeat — reloads grid and resets ledger scales.
  Future<void> restartSession() async {
    await resetGame();
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
          selectedCoord: const GridCoord(15, 15),
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

    final facility = FacilityCatalog.byActionType(actionType);
    if (facility != null) {
      goldCost = facility.creditCost;
      prodCost = facility.contrabandCost;
      newEntity = TileEntity(
        id: '${facility.id}_${target.x}_${target.y}',
        name: facility.name,
        type: facility.entityType,
        ownerFaction: 'Player 1',
      );
    } else {
      switch (actionType) {
        case 'found_outpost':
          goldCost = 75;
          prodCost = 50;
          newEntity = TileEntity(
            id: 'outpost_${target.x}_${target.y}',
            name: 'Capital Cell',
            type: 'city',
            ownerFaction: 'Player 1',
          );
          break;
        case 'train_warrior':
          goldCost = 25;
          prodCost = 15;
          newUnit = TileEntity(
            id: 'warrior_${target.x}_${target.y}',
            name: 'Enforcer',
            type: 'warrior',
            ownerFaction: 'Player 1',
          );
          break;
        case 'summon_commander':
          goldCost = 100;
          prodCost = 0;
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
      lastMessage: 'Facility operation committed.',
      showBuildMenu: false,
    );
    final placedName = newEntity?.name ?? newUnit?.name ?? actionType;
    pushEvent(
      '$placedName online at (${target.x}, ${target.y}) — −$goldCost Credits'
      '${prodCost > 0 ? ' / −$prodCost Contraband' : ''}.',
      kind: EventKind.system,
    );
    _scheduleAutosave();

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
          lastMessage: 'Net confirmed cell operation.',
          gachaPull: data['gacha_result'],
        );
        // Facility noise can attract attention — chance at a live encounter
        _maybeSurfaceEncounter(chance: 0.28);
      } else {
        // Server rejected the move (e.g., TileConflictError, GameRuleViolation)
        final errorData = jsonDecode(response.body);
        debugPrint('SERVER REJECTED ACTION: ${errorData["detail"]}');
        state = previousState.copyWith(
          isSyncingWithServer: false,
          lastMessage:
              'Server rejected move: ${errorData["detail"] ?? "Unknown error"}',
        );
      }
    } catch (e) {
      // Network failure (server is down) — keep optimistic local state playable
      debugPrint('executeTileAction error: $e');
      state = state.copyWith(
        isSyncingWithServer: false,
        lastMessage: 'Offline mode — local cell placement held.',
      );
      _maybeSurfaceEncounter(chance: 0.35);
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

        // Keep Heat/Loyalty on 0–100 syndicate scales even if server food/science diverge
        final serverGold = newResources['gold'] as int? ?? state.gold;
        final serverProd = newResources['production'] as int? ?? state.production;
        final serverSci = (newResources['science'] as int? ?? state.science)
            .clamp(0, 100);
        final serverHeat = ((newResources['food'] as int? ?? state.food) % 101)
            .clamp(0, 100);

        state = state.copyWith(
          currentTurn: data['current_turn'] ?? state.currentTurn + 1,
          gold: serverGold,
          science: serverSci,
          production: serverProd,
          food: serverHeat,
          isSyncingWithServer: false,
          lastMessage: turnMessage,
          unlockedTechs: data['unlocked_techs'] != null
              ? List<String>.from(data['unlocked_techs'])
              : state.unlockedTechs,
        );
        pushEvent(turnMessage);
        pushEvent(EncounterCatalog.randomEncounter());
        _maybeSurfaceEncounter(chance: 0.6);
        _evaluateEndgame();
      } else {
        final errorData = jsonDecode(response.body);
        state = state.copyWith(
          isSyncingWithServer: false,
          lastMessage: 'Turn error: ${errorData["detail"] ?? "Unknown"}',
        );
      }
    } catch (e, stacktrace) {
      debugPrint('NextTurn Crash: $e\n$stacktrace');
      // Offline / local cycle advance so the HUD and encounters stay playable
      final harvestCredits = 12;
      final harvestContraband = 8;
      final harvestLoyalty = 4;
      final heatCreep = 3;
      state = state.copyWith(
        currentTurn: state.currentTurn + 1,
        gold: state.gold + harvestCredits,
        production: state.production + harvestContraband,
        science: (state.science + harvestLoyalty).clamp(0, 100),
        food: (state.food + heatCreep).clamp(0, 100),
        isSyncingWithServer: false,
        lastMessage:
            'Offline cycle ${state.currentTurn + 1}: local yields applied.',
      );
      pushEvent(
        'Offline cycle — +$harvestCredits Credits · +$harvestContraband Contraband · +$heatCreep Heat.',
      );
      pushEvent(EncounterCatalog.randomEncounter());
      _maybeSurfaceEncounter(chance: 0.7);
      _evaluateEndgame();
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
