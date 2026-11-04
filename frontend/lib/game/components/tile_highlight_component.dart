import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;
import '../../core/constants/game_constants.dart';
import '../../core/math/iso_math.dart';
import '../../core/theme/game_theme.dart';

/// Animated neon isometric diamond highlight for selected tile.
class TileHighlightComponent extends PositionComponent {
  GridCoord? _currentCoord;
  double _pulseTimer = 0.0;

  final Paint _strokePaint = Paint()
    ..color = GameTheme.accentNeon
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..isAntiAlias = true;

  final Paint _fillPaint = Paint()
    ..color = GameTheme.accentNeon.withValues(alpha: 0.18)
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  void setSelectedCoord(GridCoord? coord) {
    _currentCoord = coord;
    if (coord != null) {
      position = IsoMath.gridToWorld(coord.x, coord.y);
      priority = (coord.x + coord.y) * 100 + 50; // Render above tile surface
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_currentCoord == null) return;
    _pulseTimer += dt * 3.5;
    final double pulse = (math.sin(_pulseTimer) + 1.0) / 2.0; // 0.0 to 1.0
    _strokePaint.color = GameTheme.accentNeon.withValues(alpha: 0.6 + pulse * 0.4);
    _fillPaint.color = GameTheme.accentNeon.withValues(alpha: 0.12 + pulse * 0.15);
  }

  @override
  void render(Canvas canvas) {
    if (_currentCoord == null) return;

    // Diamond relative to local origin (0, 0)
    final path = Path()
      ..moveTo(0, -GameConstants.halfTileHeight)
      ..lineTo(GameConstants.halfTileWidth, 0)
      ..lineTo(0, GameConstants.halfTileHeight)
      ..lineTo(-GameConstants.halfTileWidth, 0)
      ..close();

    // Soft outer glow halo
    final glowPaint = Paint()
      ..color = GameTheme.accentNeon.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, _fillPaint);
    canvas.drawPath(path, _strokePaint);

    // Inner bright rim
    final rim = Paint()
      ..color = Colors.white.withValues(alpha: 0.35 + ((math.sin(_pulseTimer) + 1) / 2) * 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, rim);
  }
}
