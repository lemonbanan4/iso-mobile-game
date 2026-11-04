import 'package:flame/extensions.dart';
import '../constants/game_constants.dart';

/// Point representation for discrete grid coordinates.
class GridCoord {
  final int x;
  final int y;

  const GridCoord(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridCoord &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => 'GridCoord($x, $y)';
}

/// Pure mathematical transforms for 2:1 Isometric Projection.
class IsoMath {
  IsoMath._();

  /// Converts discrete grid coordinate (col x, row y) to 2D isometric world coordinate (center of tile).
  static Vector2 gridToWorld(int col, int row) {
    final double worldX = (col - row) * GameConstants.halfTileWidth;
    final double worldY = (col + row) * GameConstants.halfTileHeight;
    return Vector2(worldX, worldY);
  }

  /// Converts continuous 2D isometric world coordinates into discrete grid coordinates.
  static GridCoord worldToGrid(Vector2 worldPos) {
    final double xNorm = worldPos.x / GameConstants.halfTileWidth;
    final double yNorm = worldPos.y / GameConstants.halfTileHeight;

    final int col = ((xNorm + yNorm) / 2.0).floor();
    final int row = ((yNorm - xNorm) / 2.0).floor();

    return GridCoord(col, row);
  }

  /// Returns the 4 polygon vertices forming the isometric diamond of a given grid tile.
  static List<Vector2> getTileDiamondVertices(int col, int row) {
    final center = gridToWorld(col, row);
    return [
      Vector2(center.x, center.y - GameConstants.halfTileHeight), // Top
      Vector2(center.x + GameConstants.halfTileWidth, center.y), // Right
      Vector2(center.x, center.y + GameConstants.halfTileHeight), // Bottom
      Vector2(center.x - GameConstants.halfTileWidth, center.y), // Left
    ];
  }

  /// Converts vertices to a Flutter [Path] for high-performance canvas drawing.
  static Path getTileDiamondPath(int col, int row) {
    final vertices = getTileDiamondVertices(col, row);
    final path = Path()
      ..moveTo(vertices[0].x, vertices[0].y)
      ..lineTo(vertices[1].x, vertices[1].y)
      ..lineTo(vertices[2].x, vertices[2].y)
      ..lineTo(vertices[3].x, vertices[3].y)
      ..close();
    return path;
  }

  /// Calculates the render depth index (Z-order) for proper isometric layering.
  /// In 2:1 isometric space, objects with larger (col + row) render in front.
  static double calculateDepth(double col, double row, [double elevation = 0]) {
    return (col + row) * 100.0 + elevation;
  }

  /// Distance in tile steps (Manhattan distance in isometric grid).
  static int tileDistance(GridCoord a, GridCoord b) {
    return (a.x - b.x).abs() + (a.y - b.y).abs();
  }

  /// Checks if coordinates lie within valid map boundaries.
  static bool isInBounds(
    GridCoord coord, {
    int width = GameConstants.defaultMapWidth,
    int height = GameConstants.defaultMapHeight,
  }) {
    return coord.x >= 0 && coord.x < width && coord.y >= 0 && coord.y < height;
  }
}
