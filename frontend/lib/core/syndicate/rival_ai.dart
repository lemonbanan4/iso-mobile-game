import 'dart:math';

import '../math/iso_math.dart';
import '../../state/tile_models.dart';

enum RivalMoveKind { expand, raid, turfWar, steal }

class RivalMoveResult {
  final RivalMoveKind kind;
  final String tickerMessage;
  final Map<GridCoord, TileState>? tiles;
  final int creditsDelta;
  final int contrabandDelta;
  final int loyaltyDelta;
  final int heatDelta;

  const RivalMoveResult({
    required this.kind,
    required this.tickerMessage,
    this.tiles,
    this.creditsDelta = 0,
    this.contrabandDelta = 0,
    this.loyaltyDelta = 0,
    this.heatDelta = 0,
  });
}

/// Lightweight client-side rival syndicate simulation for the active sector.
class RivalAiSimulator {
  RivalAiSimulator({Random? rng}) : _rng = rng ?? Random();

  static const rivalFaction = 'Barbarians';
  static const playerFaction = 'Player 1';
  static const rivalNames = [
    'Neon Vipers',
    'Chrome Jackals',
    'Null Cartel',
    'Sector 9 Ghosts',
  ];

  final Random _rng;

  String get _crew => rivalNames[_rng.nextInt(rivalNames.length)];

  RivalMoveResult? tick(Map<GridCoord, TileState> tiles) {
    if (tiles.isEmpty) return null;

    final roll = _rng.nextDouble();
    if (roll < 0.28) return _expand(tiles);
    if (roll < 0.55) return _raid(tiles);
    if (roll < 0.78) return _steal(tiles);
    return _turfWar();
  }

  RivalMoveResult? _expand(Map<GridCoord, TileState> tiles) {
    final rivalTiles = tiles.values
        .where(
          (t) =>
              t.territoryOwner == rivalFaction ||
              t.entity?.ownerFaction == rivalFaction ||
              t.unit?.ownerFaction == rivalFaction,
        )
        .toList();
    if (rivalTiles.isEmpty) {
      // Seed pressure near a random explored tile if no rivals yet
      final candidates = tiles.values
          .where(
            (t) =>
                t.isExplored &&
                t.entity == null &&
                t.unit == null &&
                t.territoryOwner != playerFaction &&
                t.type != TileType.water &&
                t.type != TileType.mountain,
          )
          .toList();
      if (candidates.isEmpty) return null;
      final pick = candidates[_rng.nextInt(candidates.length)];
      final next = Map<GridCoord, TileState>.from(tiles);
      next[pick.coord] = pick.copyWith(
        territoryOwner: rivalFaction,
        entity: TileEntity(
          id: 'rival_cell_${pick.coord.x}_${pick.coord.y}',
          name: 'Rival Drop Point',
          type: 'city',
          ownerFaction: rivalFaction,
          health: 120,
          maxHealth: 120,
        ),
      );
      return RivalMoveResult(
        kind: RivalMoveKind.expand,
        tickerMessage:
            'RIVAL · $_crew planted a drop point at (${pick.coord.x}, ${pick.coord.y}).',
        tiles: next,
        heatDelta: 2,
      );
    }

    final origin = rivalTiles[_rng.nextInt(rivalTiles.length)];
    final neighbors = _neighbors(origin.coord)
        .map((c) => tiles[c])
        .whereType<TileState>()
        .where(
          (t) =>
              t.entity == null &&
              t.unit == null &&
              t.territoryOwner != rivalFaction &&
              t.type != TileType.water &&
              t.type != TileType.mountain,
        )
        .toList();
    if (neighbors.isEmpty) return null;

    final target = neighbors[_rng.nextInt(neighbors.length)];
    final next = Map<GridCoord, TileState>.from(tiles);
    next[target.coord] = target.copyWith(territoryOwner: rivalFaction);

    return RivalMoveResult(
      kind: RivalMoveKind.expand,
      tickerMessage:
          'RIVAL · $_crew claimed district (${target.coord.x}, ${target.coord.y}).',
      tiles: next,
      heatDelta: 1,
      loyaltyDelta: -1,
    );
  }

  RivalMoveResult? _raid(Map<GridCoord, TileState> tiles) {
    final playerSites = tiles.values
        .where(
          (t) =>
              t.entity != null &&
              t.entity!.ownerFaction == playerFaction &&
              t.entity!.type != 'city',
        )
        .toList();
    if (playerSites.isEmpty) return _turfWar();

    final site = playerSites[_rng.nextInt(playerSites.length)];
    final entity = site.entity!;
    final damage = 20 + _rng.nextInt(35);
    final nextHp = entity.health - damage;
    final next = Map<GridCoord, TileState>.from(tiles);

    if (nextHp <= 0) {
      next[site.coord] = site.copyWith(clearEntity: true);
      return RivalMoveResult(
        kind: RivalMoveKind.raid,
        tickerMessage:
            'RIVAL · $_crew razed your ${entity.name} at (${site.coord.x}, ${site.coord.y})!',
        tiles: next,
        contrabandDelta: -12,
        heatDelta: 6,
        loyaltyDelta: -4,
      );
    }

    next[site.coord] = site.copyWith(
      entity: TileEntity(
        id: entity.id,
        name: entity.name,
        type: entity.type,
        ownerFaction: entity.ownerFaction,
        health: nextHp,
        maxHealth: entity.maxHealth,
        readyAt: entity.readyAt,
      ),
    );
    return RivalMoveResult(
      kind: RivalMoveKind.raid,
      tickerMessage:
          'RIVAL · $_crew hit ${entity.name} (−$damage HP) at (${site.coord.x}, ${site.coord.y}).',
      tiles: next,
      contrabandDelta: -8,
      heatDelta: 4,
      loyaltyDelta: -2,
    );
  }

  RivalMoveResult? _steal(Map<GridCoord, TileState> tiles) {
    final stolen = 8 + _rng.nextInt(18);
    return RivalMoveResult(
      kind: RivalMoveKind.steal,
      tickerMessage:
          'RIVAL · $_crew skimmed $stolen Contraband off your courier lanes.',
      contrabandDelta: -stolen,
      heatDelta: 2,
    );
  }

  RivalMoveResult _turfWar() {
    return RivalMoveResult(
      kind: RivalMoveKind.turfWar,
      tickerMessage:
          'RIVAL · $_crew sparked a turf flare — street Loyalty wavers.',
      loyaltyDelta: -3,
      heatDelta: 3,
    );
  }

  List<GridCoord> _neighbors(GridCoord c) => [
        GridCoord(c.x + 1, c.y),
        GridCoord(c.x - 1, c.y),
        GridCoord(c.x, c.y + 1),
        GridCoord(c.x, c.y - 1),
        GridCoord(c.x + 1, c.y + 1),
        GridCoord(c.x - 1, c.y - 1),
      ];
}
