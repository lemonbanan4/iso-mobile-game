import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../../core/constants/game_constants.dart';
import '../../core/math/iso_math.dart';
import '../../core/theme/game_theme.dart';
import '../../state/tile_models.dart';
import '../strategy_game.dart'; // Import your main game class

class IsometricGridComponent extends Component with HasGameRef<StrategyGame> {
  Map<GridCoord, TileState> _tiles = {};

  final Paint _gridLinePaint = Paint()
    ..color = const Color(0x1AFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  final Paint _territoryPaint = Paint()..style = PaintingStyle.fill;

  // Sprite references
  Sprite? _citySprite;
  Sprite? _farmSprite;
  Sprite? _scoutSprite;
  Sprite? _mineSprite;
  Sprite? _barracksSprite;
  Sprite? _warriorSprite;
  Sprite? _tavernSprite;
  Sprite? _heroSprite;
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the Kenney building sprites from assets/images/
    // Ensure these filenames match the actual files you copied from the Kenney pack
    try {
      _citySprite = await gameRef.loadSprite('building-a.png');
      _farmSprite = await gameRef.loadSprite('building-e.png');
      _scoutSprite = await gameRef.loadSprite('character-c.png');
      _mineSprite = await gameRef.loadSprite('building-b.png');
      _barracksSprite = await gameRef.loadSprite('building-f.png');
      _warriorSprite = await gameRef.loadSprite('character-a.png');
      _tavernSprite = await gameRef.loadSprite('building-g.png');
      _heroSprite = await gameRef.loadSprite('character-b.png');
    } catch (e) {
      debugPrint(
        'Warning: Could not load some sprites. Missing PNGs in assets/images/.',
      );
    }
  }

  void updateTiles(Map<GridCoord, TileState> newTiles) {
    _tiles = newTiles;
  }

  @override
  void render(Canvas canvas) {
    if (_tiles.isEmpty) return;

    const double halfW = GameConstants.halfTileWidth;
    const double halfH = GameConstants.halfTileHeight;

    // Sort tiles by isometric Z-depth: (x + y) ascending so further tiles render first
    final sortedEntries = _tiles.entries.toList()
      ..sort((a, b) => (a.key.x + a.key.y).compareTo(b.key.x + b.key.y));

    for (final entry in sortedEntries) {
      final coord = entry.key;
      final tile = entry.value;
      final screen = IsoMath.gridToWorld(coord.x, coord.y);

      // --- 1. Draw Top Diamond Surface (Transparent wireframe) ---
      final topPath = Path()
        ..moveTo(screen.x, screen.y - halfH)
        ..lineTo(screen.x + halfW, screen.y)
        ..lineTo(screen.x, screen.y + halfH)
        ..lineTo(screen.x - halfW, screen.y)
        ..close();

      // FOG OF WAR
      if (!tile.isExplored) {
        // Draw a solid dark tile and skip rendering anything else
        final Paint fogPaint = Paint()..color = const Color(0xFF0F172A);
        canvas.drawPath(topPath, fogPaint);
        continue;
      }

      canvas.drawPath(topPath, _gridLinePaint);

      // --- 2. Territory Tint Overlay ---
      if (tile.territoryOwner != null) {
        _territoryPaint.color = GameTheme.accentNeon.withValues(alpha: 0.16);
        canvas.drawPath(topPath, _territoryPaint);
      }

      // --- 3. Entity Rendering (Sprites) ---
      if (tile.entity != null) {
        _renderEntity(canvas, tile.entity!, screen.x, screen.y);
      }

      // --- 4. Unit Rendering (Armies) ---
      if (tile.unit != null) {
        // Offset the unit slightly so it stands next to/in front of the building
        final unitYOffset = screen.y + 15.0;
        _renderEntity(canvas, tile.unit!, screen.x, unitYOffset);
      }
    }
  }

  void _renderEntity(
    Canvas canvas,
    TileEntity entity,
    double screenX,
    double screenY,
  ) {
    Sprite? spriteToDraw;

    // Default Kenney isometric sprite dimensions
    Vector2 spriteSize = Vector2(128, 128);

    // Offset pushes the sprite up so its base sits on the diamond center
    double yOffset = 64.0;

    switch (entity.type) {
      case 'city':
        spriteToDraw = _citySprite;
        break;
      case 'farm':
        spriteToDraw = _farmSprite;
        break;
      case 'mine':
        spriteToDraw = _mineSprite;
        break;
      case 'barracks':
        spriteToDraw = _barracksSprite;
        break;
      case 'tavern':
        spriteToDraw = _tavernSprite;
        break;
      case 'scout':
        spriteToDraw = _scoutSprite;
        // Units might be smaller than buildings, adjust if necessary
        spriteSize = Vector2(64, 64);
        yOffset = 32.0;
        break;
      case 'warrior':
        spriteToDraw = _warriorSprite;
        spriteSize = Vector2(64, 64);
        yOffset = 32.0;
        break;
      case 'hero':
        spriteToDraw = _heroSprite;
        spriteSize = Vector2(64, 64);
        yOffset = 32.0;
        break;
    }

    if (spriteToDraw != null) {
      spriteToDraw.render(
        canvas,
        position: Vector2(screenX - (spriteSize.x / 2), screenY - yOffset),
        size: spriteSize,
      );
    } else {
      // Fallback if the PNG is missing or loading failed
      final paintBase = Paint()..color = const Color(0xFF0F172A);
      final paintAccent = Paint()..color = GameTheme.accentNeon;

      canvas.drawCircle(Offset(screenX, screenY - 12), 16, paintBase);
      canvas.drawCircle(Offset(screenX, screenY - 12), 8, paintAccent);
    }

    // --- DRAW FLOATING HEALTH BAR ---
    if (entity.maxHealth != null) {
      final double hpPercent = (entity.health / entity.maxHealth).clamp(
        0.0,
        1.0,
      );

      final Paint bgPaint = Paint()
        ..color = const Color(0xFF000000); // Black background
      final Paint hpPaint = Paint()
        ..color = hpPercent > 0.4
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444); // Green, turns Red if low

      const double barWidth = 40.0;
      const double barHeight = 6.0;
      final double barX = screenX - (barWidth / 2);

      // Determine if we are currently drawing a mobile unit or a building
      final bool isUnit = ['scout', 'warrior', 'hero'].contains(entity.type);

      final double barY = isUnit
          ? screenY -
                (yOffset / 1.3) -
                4.0 // Above the unit sprite
          : screenY - yOffset - 15.0; // Above the building sprite

      // Draw background
      canvas.drawRect(Rect.fromLTWH(barX, barY, barWidth, barHeight), bgPaint);
      // Draw current HP
      canvas.drawRect(
        Rect.fromLTWH(barX, barY, barWidth * hpPercent, barHeight),
        hpPaint,
      );
    }
  }
}
