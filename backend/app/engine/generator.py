from typing import Dict, Tuple
from app.models.common import GridCoord, ResourceYield
from app.models.tile import TileState, TileType, TileEntity

def generate_default_world(width: int = 32, height: int = 32) -> Dict[Tuple[int, int], TileState]:
    """Deterministically populates the strategy map matching frontend visual sectors."""
    tiles: Dict[Tuple[int, int], TileState] = {}

    for y in range(height):
        for x in range(width):
            coord = GridCoord(x=x, y=y)
            tile_type = TileType.PLAINS
            base_yield = ResourceYield(food=2, gold=1)

            # Procedural biomes
            if abs(x - 8) + abs(y - 8) < 4:
                tile_type = TileType.WATER
                base_yield = ResourceYield(food=1, gold=2)
            elif abs(x - 22) + abs(y - 20) < 5:
                tile_type = TileType.MOUNTAIN
                base_yield = ResourceYield(production=3, science=1)
            elif (x % 5 == 0 and y % 3 == 0):
                tile_type = TileType.FOREST
                base_yield = ResourceYield(food=1, production=2)
            elif x > 25 or y > 25:
                tile_type = TileType.HILLS
                base_yield = ResourceYield(production=2, gold=1)

            entity = None
            territory_owner = None

            # Player 1 Capital
            if x == 15 and y == 15:
                entity = TileEntity(
                    id="city_capital",
                    name="New Alexandria",
                    type="city",
                    owner_faction="Player 1",
                )
            elif x == 16 and y == 14:
                entity = TileEntity(
                    id="unit_scout",
                    name="Pioneer Scout",
                    type="scout",
                    owner_faction="Player 1",
                )

            if 13 <= x <= 17 and 13 <= y <= 17:
                territory_owner = "Player 1"

            tiles[(x, y)] = TileState(
                coord=coord,
                type=tile_type,
                yields=base_yield,
                entity=entity,
                is_explored=True,
                is_visible=True,
                territory_owner=territory_owner,
            )

    return tiles
