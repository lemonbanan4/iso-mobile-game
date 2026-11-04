import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';

import '../core/constants/game_constants.dart';
import '../core/math/iso_math.dart';
import '../core/syndicate/event_log_entry.dart';
import '../state/tile_models.dart';
import 'components/damage_text.dart';
import 'components/floating_yield_text.dart';
import 'components/isometric_grid_component.dart';
import 'components/tile_highlight_component.dart';

/// Pure Flame Game instance managing isometric rendering and camera control.
/// Strictly decoupled from Flutter widgets.
class StrategyGame extends FlameGame with TapCallbacks, ScaleDetector {
  final void Function(GridCoord coord)? onTileSelected;

  late final IsometricGridComponent _gridComponent;
  late final TileHighlightComponent _highlightComponent;
  late TiledComponent mapComponent;

  double _zoomLevel = GameConstants.defaultZoom;
  Vector2 _cameraPosition = Vector2.zero();
  bool _didPanGesture = false;

  StrategyGame({this.onTileSelected});

  @override
  Color backgroundColor() => const Color(0xFF090D16);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // load map
    mapComponent = await TiledComponent.load(
      'first_map.tmx',
      Vector2(128, 64),
      prefix: 'assets/tiles/',
    );

    _gridComponent = IsometricGridComponent();
    _highlightComponent = TileHighlightComponent();

    // Add components to world
    world.add(mapComponent);
    world.add(_gridComponent);
    world.add(_highlightComponent);

    // Center camera around initial player capital at (15, 15)
    final initialCenter = IsoMath.gridToWorld(15, 15);
    _cameraPosition = initialCenter;
    camera.viewfinder.position = _cameraPosition;
    camera.viewfinder.zoom = _zoomLevel;
  }

  // Cache to remember health values for each tile to avoid unnecessary updates
  Map<GridCoord, TileState> _previousTiles = {};

  /// Synchronize world tiles from reactive state provider
  void updateWorldTiles(Map<GridCoord, TileState> newTiles) {
    for (final entry in newTiles.entries) {
      final coord = entry.key;
      final newTile = entry.value;
      final oldTile = _previousTiles[coord];

      if (oldTile != null) {
        // 1. Compare Unit HP (Safely ignores coordinate-based ID changes)
        if (oldTile.unit != null && newTile.unit != null) {
          final damage = oldTile.unit!.health - newTile.unit!.health;
          if (damage > 0 && damage < oldTile.unit!.health) {
            _spawnDamage(coord, damage);
          }
        }

        // 2. Compare Building HP
        if (oldTile.entity != null && newTile.entity != null) {
          final damage = oldTile.entity!.health - newTile.entity!.health;
          if (damage > 0 && damage < oldTile.entity!.health) {
            _spawnDamage(coord, damage);
          }
        }
      }
    }

    _previousTiles = newTiles;

    // Make sure your grid actually updates!
    _gridComponent.updateTiles(newTiles);
  }

  void _spawnDamage(GridCoord coord, int damage) {
    final screenPos = IsoMath.gridToWorld(coord.x, coord.y);

    // Spawn the text floating slightly above the center of the tile
    final floatingText = DamageText(
      text: '-$damage',
      position: Vector2(screenPos.x, screenPos.y - 40),
    );

    _gridComponent.add(floatingText);
  }

  /// Spawn colored +Credits / +Heat style floaters from economy ticks.
  void spawnFloatingYields(List<FloatingYieldEvent> events) {
    for (var i = 0; i < events.length; i++) {
      final e = events[i];
      final screenPos = IsoMath.gridToWorld(e.x, e.y);
      _gridComponent.add(
        FloatingYieldText(
          text: e.label,
          color: e.color,
          position: Vector2(screenPos.x, screenPos.y - 36.0 - (i * 18.0)),
        ),
      );
    }
  }

  /// Synchronize selection highlight
  void setSelectedCoord(GridCoord? coord) {
    _highlightComponent.setSelectedCoord(coord);
  }

  /// Center camera on specific tile with smooth transition
  void focusOnTile(GridCoord coord) {
    final target = IsoMath.gridToWorld(coord.x, coord.y);
    camera.viewfinder.position = target;
    _cameraPosition = target;
  }

  @override
  void onTapDown(TapDownEvent event) {
    _didPanGesture = false;
  }

  @override
  void onTapUp(TapUpEvent event) {
    // Ignore selection if the gesture was a camera pan
    if (_didPanGesture) return;

    final worldPos = camera.viewfinder.globalToLocal(event.localPosition);
    final gridCoord = IsoMath.worldToGrid(worldPos);

    if (IsoMath.isInBounds(gridCoord)) {
      setSelectedCoord(gridCoord);
      onTileSelected?.call(gridCoord);
    }
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    // 1. Handle Multi-touch Zoom
    final scaleDelta = info.scale.global.x;
    if (scaleDelta != 1.0) {
      _zoomLevel = (_zoomLevel * scaleDelta).clamp(
        GameConstants.minZoom,
        GameConstants.maxZoom,
      );
      camera.viewfinder.zoom = _zoomLevel;
    }

    // 2. Handle pan / drag (mark gesture so tap-up does not select)
    final translationDelta = info.delta.global;
    if (translationDelta.x != 0 || translationDelta.y != 0) {
      if (translationDelta.length > 2.0) {
        _didPanGesture = true;
      }
      _cameraPosition -= translationDelta / _zoomLevel;
      camera.viewfinder.position = _cameraPosition;
    }
  }
}
