import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/constants/game_constants.dart';
import 'package:frontend/core/math/iso_math.dart';

void main() {
  group('IsoMath Coordinate Projections', () {
    test('gridToWorld and worldToGrid roundtrip test', () {
      const testCoordinates = [
        GridCoord(0, 0),
        GridCoord(10, 5),
        GridCoord(15, 15),
        GridCoord(31, 31),
      ];

      for (final coord in testCoordinates) {
        final world = IsoMath.gridToWorld(coord.x, coord.y);
        final reconstructed = IsoMath.worldToGrid(world);

        expect(reconstructed.x, equals(coord.x), reason: 'X coord mismatch for $coord');
        expect(reconstructed.y, equals(coord.y), reason: 'Y coord mismatch for $coord');
      }
    });

    test('Tile diamond vertices count and symmetry', () {
      final vertices = IsoMath.getTileDiamondVertices(5, 5);
      expect(vertices.length, equals(4));

      final center = IsoMath.gridToWorld(5, 5);
      // Top vertex should be center.y - halfTileHeight
      expect(vertices[0].x, closeTo(center.x, 0.001));
      expect(vertices[0].y, closeTo(center.y - GameConstants.halfTileHeight, 0.001));

      // Right vertex should be center.x + halfTileWidth
      expect(vertices[1].x, closeTo(center.x + GameConstants.halfTileWidth, 0.001));
      expect(vertices[1].y, closeTo(center.y, 0.001));
    });

    test('calculateDepth correctly favors larger (x + y)', () {
      final depthNear = IsoMath.calculateDepth(0, 0);
      final depthFar = IsoMath.calculateDepth(5, 5);

      expect(depthFar, greaterThan(depthNear));
    });
  });
}
