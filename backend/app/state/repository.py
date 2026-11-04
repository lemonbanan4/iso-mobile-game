"""Game state persistence.

Default: in-memory (local + CI).
Optional: Firestore when ISO_GAME_STORAGE=firestore and firebase_admin is installed.
"""

from __future__ import annotations

import os
from typing import Dict, List, Optional, Protocol, Tuple

from app.models.common import PlayerResources, PlayerState
from app.models.tile import TileEntity, TileState, TileType
from app.models.common import GridCoord, ResourceYield


def _build_world_tiles(width: int = 32, height: int = 32) -> Dict[Tuple[int, int], TileState]:
    tiles: Dict[Tuple[int, int], TileState] = {}

    for y in range(height):
        for x in range(width):
            terrain = TileType.PLAINS
            y_food, y_prod, y_gold, y_sci = 2, 0, 1, 0

            if abs(x - 8) + abs(y - 8) < 4:
                terrain = TileType.WATER
                y_food, y_prod, y_gold, y_sci = 1, 0, 2, 0
            elif abs(x - 22) + abs(y - 20) < 5:
                terrain = TileType.MOUNTAIN
                y_food, y_prod, y_gold, y_sci = 0, 2, 0, 1
            elif x % 5 == 0 and y % 3 == 0:
                terrain = TileType.FOREST
                y_food, y_prod, y_gold, y_sci = 1, 2, 0, 0
            elif x > 25 or y > 25:
                terrain = TileType.HILLS
                y_food, y_prod, y_gold, y_sci = 1, 1, 1, 0

            entity: Optional[TileEntity] = None
            unit: Optional[TileEntity] = None
            territory_owner: Optional[str] = None

            if x == 15 and y == 15:
                entity = TileEntity(
                    id="city_capital",
                    name="New Alexandria",
                    type="city",
                    owner_faction="Player 1",
                    health=100,
                    max_health=100,
                )
                y_sci += 50
                y_prod += 25
                y_gold += 25
            elif x == 16 and y == 14:
                unit = TileEntity(
                    id="unit_scout",
                    name="Pioneer Scout",
                    type="scout",
                    owner_faction="Player 1",
                    health=100,
                    max_health=100,
                )
            elif x == 17 and y == 15:
                entity = TileEntity(
                    id="barb_camp_1",
                    name="Barbarian Encampment",
                    type="city",
                    owner_faction="Barbarians",
                    health=200,
                    max_health=200,
                )
                unit = TileEntity(
                    id="barb_warrior_1",
                    name="Savage Brute",
                    type="warrior",
                    owner_faction="Barbarians",
                    health=150,
                    max_health=150,
                )

            if x == 17 and y == 15:
                territory_owner = "Barbarians"
            elif 13 <= x <= 17 and 13 <= y <= 17:
                territory_owner = "Player 1"

            is_explored = abs(x - 15) <= 3 and abs(y - 15) <= 3

            tiles[(x, y)] = TileState(
                coord=GridCoord(x=x, y=y),
                type=terrain,
                yields=ResourceYield(
                    food=y_food,
                    production=y_prod,
                    gold=y_gold,
                    science=y_sci,
                ),
                entity=entity,
                unit=unit,
                is_explored=is_explored,
                is_visible=is_explored,
                territory_owner=territory_owner,
            )

    return tiles


class IGameStateRepository(Protocol):
    async def get_all_tiles(self) -> List[TileState]: ...
    async def get_tile(self, x: int, y: int) -> Optional[TileState]: ...
    async def update_tile(self, tile: TileState) -> None: ...
    async def move_entity(
        self, from_coord: Tuple[int, int], to_coord: Tuple[int, int]
    ) -> None: ...
    async def get_current_turn(self) -> int: ...
    async def set_current_turn(self, turn: int) -> None: ...
    async def get_player_state(self) -> PlayerState: ...
    async def update_player_state(self, state: PlayerState) -> None: ...
    async def get_player_resources(self) -> PlayerResources: ...
    async def update_player_resources(self, resources: PlayerResources) -> None: ...


class InMemoryGameStateRepository:
    """Authoritative in-process store for local play, tests, and CI."""

    def __init__(self) -> None:
        self._tiles = _build_world_tiles()
        self._turn = 1
        self._player_state = PlayerState(
            resources=PlayerResources(
                gold=150, science=45, production=80, food=120
            ),
            unlocked_techs=["agriculture"],
        )
        print("In-memory world seeded.")

    async def get_all_tiles(self) -> List[TileState]:
        return list(self._tiles.values())

    async def get_tile(self, x: int, y: int) -> Optional[TileState]:
        return self._tiles.get((x, y))

    async def update_tile(self, tile: TileState) -> None:
        self._tiles[(tile.coord.x, tile.coord.y)] = tile

    async def move_entity(
        self, from_coord: Tuple[int, int], to_coord: Tuple[int, int]
    ) -> None:
        source = self._tiles.get(from_coord)
        target = self._tiles.get(to_coord)
        if not source or not target or source.unit is None:
            return
        unit = source.unit
        self._tiles[from_coord] = source.model_copy(update={"unit": None})
        self._tiles[to_coord] = target.model_copy(update={"unit": unit})

    async def get_current_turn(self) -> int:
        return self._turn

    async def set_current_turn(self, turn: int) -> None:
        self._turn = turn

    async def update_turn(self, new_turn: int) -> None:
        await self.set_current_turn(new_turn)

    async def get_player_state(self) -> PlayerState:
        return self._player_state

    async def update_player_state(self, state: PlayerState) -> None:
        self._player_state = state

    async def get_player_resources(self) -> PlayerResources:
        return self._player_state.resources

    async def update_player_resources(self, resources: PlayerResources) -> None:
        self._player_state = PlayerState(
            resources=resources,
            unlocked_techs=self._player_state.unlocked_techs,
        )


class FirestoreGameStateRepository:
    """Optional Firestore-backed store (requires firebase_admin + credentials)."""

    def __init__(self) -> None:
        import firebase_admin
        from firebase_admin import firestore

        if not firebase_admin._apps:
            firebase_admin.initialize_app()

        self._db = firestore.client()
        self._tiles_ref = self._db.collection("tiles")
        self._state_ref = self._db.collection("game_state").document("global")
        self._seed_world_if_empty()

    def _seed_world_if_empty(self) -> None:
        existing = list(self._tiles_ref.limit(1).stream())
        if existing:
            print("World already exists in Firestore. Skipping generation.")
            return

        print("Generating new world in Firestore...")
        self._state_ref.set(
            {
                "current_turn": 1,
                "resources": {
                    "gold": 150,
                    "science": 45,
                    "production": 80,
                    "food": 120,
                },
                "unlocked_techs": ["agriculture"],
            }
        )

        tiles = _build_world_tiles()
        chunk = []
        for (x, y), tile in tiles.items():
            chunk.append((f"{x}_{y}", tile.model_dump(mode="json")))
            if len(chunk) >= 400:
                self._commit_chunk(chunk)
                chunk = []
        if chunk:
            self._commit_chunk(chunk)
        print("World generation complete.")

    def _commit_chunk(self, chunk: List[Tuple[str, dict]]) -> None:
        batch = self._db.batch()
        for doc_id, data in chunk:
            batch.set(self._tiles_ref.document(doc_id), data)
        batch.commit()

    async def get_all_tiles(self) -> List[TileState]:
        return [
            TileState(**(doc.to_dict() or {}))
            for doc in self._tiles_ref.stream()
            if doc.to_dict()
        ]

    async def get_tile(self, x: int, y: int) -> Optional[TileState]:
        doc = self._tiles_ref.document(f"{x}_{y}").get()
        if not doc.exists:
            return None
        data = doc.to_dict() or {}
        return TileState(**data) if data else None

    async def update_tile(self, tile: TileState) -> None:
        self._tiles_ref.document(f"{tile.coord.x}_{tile.coord.y}").set(
            tile.model_dump(mode="json")
        )

    async def move_entity(
        self, from_coord: Tuple[int, int], to_coord: Tuple[int, int]
    ) -> None:
        source_doc = self._tiles_ref.document(f"{from_coord[0]}_{from_coord[1]}")
        target_doc = self._tiles_ref.document(f"{to_coord[0]}_{to_coord[1]}")
        source_snap = source_doc.get()
        target_snap = target_doc.get()
        if not (source_snap.exists and target_snap.exists):
            return
        unit = (source_snap.to_dict() or {}).get("unit")
        batch = self._db.batch()
        batch.update(source_doc, {"unit": None})
        batch.update(target_doc, {"unit": unit})
        batch.commit()

    async def get_current_turn(self) -> int:
        doc = self._state_ref.get()
        if doc.exists:
            return (doc.to_dict() or {}).get("current_turn", 1)
        return 1

    async def set_current_turn(self, turn: int) -> None:
        self._state_ref.set({"current_turn": turn}, merge=True)

    async def update_turn(self, new_turn: int) -> None:
        await self.set_current_turn(new_turn)

    async def get_player_state(self) -> PlayerState:
        doc = self._state_ref.get()
        if doc.exists:
            data = doc.to_dict() or {}
            res = data.get(
                "resources",
                {"gold": 150, "science": 45, "production": 80, "food": 120},
            )
            techs = data.get("unlocked_techs", ["agriculture"])
            return PlayerState(
                resources=PlayerResources(**res), unlocked_techs=techs
            )
        return PlayerState(
            resources=PlayerResources(
                gold=150, science=45, production=80, food=120
            ),
            unlocked_techs=["agriculture"],
        )

    async def update_player_state(self, state: PlayerState) -> None:
        self._state_ref.set(
            {
                "resources": state.resources.model_dump(),
                "unlocked_techs": state.unlocked_techs,
            },
            merge=True,
        )

    async def get_player_resources(self) -> PlayerResources:
        return (await self.get_player_state()).resources

    async def update_player_resources(self, resources: PlayerResources) -> None:
        state = await self.get_player_state()
        await self.update_player_state(
            PlayerState(resources=resources, unlocked_techs=state.unlocked_techs)
        )


_repo_instance: Optional[object] = None


def get_game_repo():
    """Return the configured repository singleton."""
    global _repo_instance
    if _repo_instance is not None:
        return _repo_instance

    mode = os.getenv("ISO_GAME_STORAGE", "memory").strip().lower()
    if mode == "firestore":
        try:
            _repo_instance = FirestoreGameStateRepository()
        except Exception as exc:  # pragma: no cover - env specific
            print(f"Firestore init failed ({exc}); falling back to in-memory.")
            _repo_instance = InMemoryGameStateRepository()
    else:
        _repo_instance = InMemoryGameStateRepository()
    return _repo_instance
