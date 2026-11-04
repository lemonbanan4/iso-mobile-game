## --- FIREBASE REPOSITORY ---
from typing import Dict, Tuple, List, Optional
import firebase_admin
from firebase_admin import credentials, firestore

from app.models.tile import TileState, TileEntity, GridCoord, ResourceYield
from app.models.common import PlayerResources, PlayerState

# Initialize Firebase
if not firebase_admin._apps:
    firebase_admin.initialize_app()

db = firestore.client()
tiles_ref = db.collection('tiles')
state_ref = db.collection('game_state').document('global')


class IGameStateRepository:
    def __init__(self):
        self._seed_world_if_empty()

    def _seed_world_if_empty(self):
        """Checks Firestore. If empty, procedurally generates and uploads the map."""
        existing_tiles = list(tiles_ref.limit(1).stream())
        if len(existing_tiles) > 0:
            print("World already exists in Firestore. Skipping generation.")
            return

        print("Generating new world in Firestore...")
        
        # Initialize turn and resources in the global doc
        state_ref.set({
            'current_turn': 1,
            'resources': {'gold': 150, 'science': 45, 'production': 80, 'food': 120},
            'unlocked_techs': ['agriculture']
        })

        width = 32
        height = 32
        tiles_data = []

        for y in range(height):
            for x in range(width):
                terrain = "plains"
                y_food, y_prod, y_gold, y_sci = 2, 0, 1, 0

                if abs(x - 8) + abs(y - 8) < 4:
                    terrain = "water"
                    y_food, y_prod, y_gold, y_sci = 1, 0, 2, 0
                elif abs(x - 22) + abs(y - 20) < 5:
                    terrain = "mountain"
                    y_food, y_prod, y_gold, y_sci = 0, 2, 0, 1
                elif x % 5 == 0 and y % 3 == 0:
                    terrain = "forest"
                    y_food, y_prod, y_gold, y_sci = 1, 2, 0, 0
                elif x > 25 or y > 25:
                    terrain = "hills"
                    y_food, y_prod, y_gold, y_sci = 1, 1, 1, 0

                entity = None
                unit = None
                territory_owner = None

                # Player 1 Start
                if x == 15 and y == 15:
                    entity = {"id": "city_capital", "name": "New Alexandria", "type": "city", "owner_faction": "Player 1", "health": 100, "max_health": 100}
                    y_sci += 50
                    y_prod += 25
                    y_gold += 25
                elif x == 16 and y == 14:
                    unit = {"id": "unit_scout", "name": "Pioneer Scout", "type": "scout", "owner_faction": "Player 1", "health": 100, "max_health": 100}
                
                # Barbarian Camp Spawn
                elif x == 17 and y == 15:
                    entity = {"id": "barb_camp_1", "name": "Barbarian Encampment", "type": "city", "owner_faction": "Barbarians", "health": 200, "max_health": 200}
                    unit = {"id": "barb_warrior_1", "name": "Savage Brute", "type": "warrior", "owner_faction": "Barbarians", "health": 150, "max_health": 150}

                # Territory mapping
                if x == 17 and y == 15:
                    territory_owner = "Barbarians"
                elif 13 <= x <= 17 and 13 <= y <= 17:
                    territory_owner = "Player 1"

                # FOG OF WAR LOGIC
                # Only reveal a 3-tile radius around the player 1 capital (15, 15)
                is_explored = False
                if abs(x - 15) <= 3 and abs(y - 15) <= 3:
                    is_explored = True

                tiles_data.append({
                    "id": f"{x}_{y}",
                    "coord": {"x": x, "y": y},
                    "type": terrain,
                    "yields": {"food": y_food, "production": y_prod, "gold": y_gold, "science": y_sci},
                    "entity": entity,
                    "unit": unit,
                    "is_explored": is_explored,
                    "is_visible": is_explored,
                    "territory_owner": territory_owner
                })
        
        # Firestore batch writing
        chunk_size = 400
        for i in range(0, len(tiles_data), chunk_size):
            batch = db.batch()
            for tile in tiles_data[i:i + chunk_size]:
                doc_ref = tiles_ref.document(tile["id"])
                t_data = tile.copy()
                del t_data["id"]
                batch.set(doc_ref, t_data)
            batch.commit()
            
        print("World generation complete.")

    async def get_all_tiles(self) -> List[TileState]:
        docs = tiles_ref.stream()
        tiles = []
        for doc in docs:
            data = doc.to_dict() or {}
            if data:
                tiles.append(TileState(**data))
        return tiles

    async def get_tile(self, x: int, y: int) -> Optional[TileState]:
        doc = tiles_ref.document(f"{x}_{y}").get()
        if doc.exists:
            data = doc.to_dict() or {}
            if data:
                return TileState(**data)
        return None

    async def update_tile(self, tile: TileState) -> None:
        tiles_ref.document(f"{tile.coord.x}_{tile.coord.y}").set(tile.dict())

    async def move_entity(self, from_coord: Tuple[int, int], to_coord: Tuple[int, int]) -> None:
        source_doc = tiles_ref.document(f"{from_coord[0]}_{from_coord[1]}")
        target_doc = tiles_ref.document(f"{to_coord[0]}_{to_coord[1]}")
        
        source_snap = source_doc.get()
        target_snap = target_doc.get()
        
        if source_snap.exists and target_snap.exists:
            source_data = source_snap.to_dict() or {}
            unit = source_data.get("unit")
            
            batch = db.batch()
            batch.update(source_doc, {"unit": None})
            batch.update(target_doc, {"unit": unit})
            batch.commit()

    async def get_current_turn(self) -> int:
        doc = state_ref.get()
        if doc.exists:
            data = doc.to_dict() or {}
            return data.get('current_turn', 1)
        return 1

    async def set_current_turn(self, turn: int) -> None:
        state_ref.set({'current_turn': turn}, merge=True)

    async def get_player_state(self) -> PlayerState:
        doc = state_ref.get()
        if doc.exists:
            data = doc.to_dict() or {}
            res_dict = data.get('resources', {'gold': 150, 'science': 45, 'production': 80, 'food': 120})
            techs = data.get('unlocked_techs', ['agriculture'])
            return PlayerState(
                resources=PlayerResources(**res_dict),
                unlocked_techs=techs
            )
        return PlayerState(
            resources=PlayerResources(gold=150, science=45, production=80, food=120),
            unlocked_techs=['agriculture']
        )

    async def update_player_state(self, state: PlayerState):
        state_ref.set({
            'resources': state.resources.dict(),
            'unlocked_techs': state.unlocked_techs
        }, merge=True)

    async def update_turn(self, new_turn: int):
        state_ref.set({
            'current_turn': new_turn
        }, merge=True)

# Global singleton instance
_repo_instance = IGameStateRepository()

def get_game_repo() -> IGameStateRepository:
    return _repo_instance