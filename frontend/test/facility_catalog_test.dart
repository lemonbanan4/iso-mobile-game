import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/syndicate/facility_catalog.dart';
import 'package:frontend/core/syndicate/rival_ai.dart';
import 'package:frontend/core/math/iso_math.dart';
import 'package:frontend/state/tile_models.dart';

void main() {
  group('FacilityCatalog', () {
    test('exposes four core underground facilities', () {
      expect(FacilityCatalog.all.length, 4);
      expect(
        FacilityCatalog.all.map((f) => f.id).toSet(),
        containsAll([
          'smuggling_ring',
          'bribe_network',
          'chem_lab',
          'contraband_vault',
        ]),
      );
    });

    test('byActionType resolves build hooks', () {
      expect(FacilityCatalog.byActionType('build_mine')?.name, 'Smuggling Ring');
      expect(FacilityCatalog.byActionType('build_farm')?.name, 'Bribe Network');
    });
  });

  group('RivalAiSimulator', () {
    test('tick returns a move when explored empty tiles exist', () {
      final tiles = <GridCoord, TileState>{
        const GridCoord(2, 2): const TileState(
          coord: GridCoord(2, 2),
          type: TileType.plains,
          yields: ResourceYield(gold: 1),
          isExplored: true,
        ),
        const GridCoord(3, 2): const TileState(
          coord: GridCoord(3, 2),
          type: TileType.plains,
          yields: ResourceYield(gold: 1),
          isExplored: true,
        ),
      };

      final ai = RivalAiSimulator();
      RivalMoveResult? result;
      for (var i = 0; i < 12; i++) {
        result = ai.tick(tiles);
        if (result != null) break;
      }
      expect(result, isNotNull);
      expect(result!.tickerMessage, contains('RIVAL'));
    });
  });
}
