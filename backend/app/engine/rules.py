from typing import Tuple, Dict, Optional, List
import time
import random
from app.models.common import PlayerResources, ResourceYield
from app.models.tile import TileState, TileType, TileEntity
from app.models.action import ActionType
from app.core.exceptions import (
    GameRuleViolation,
    InsufficientResourcesError,
    TileConflictError,
    TileNotFoundError,
)

# Canonical action costs: (Gold, Production)
ACTION_COSTS: Dict[ActionType, Tuple[int, int]] = {
    ActionType.BUILD_FARM: (30, 20),
    ActionType.FOUND_OUTPOST: (75, 50),
    ActionType.BUILD_MINE: (40, 25),
    ActionType.TRAIN_SCOUT: (45, 30),
    ActionType.CLEAR_FEATURE: (15, 10),
    ActionType.BUILD_BARRACKS: (60, 40),
    ActionType.TRAIN_WARRIOR: (25, 15),
    ActionType.BUILD_TAVERN: (100, 50),
    ActionType.SUMMON_COMMANDER: (100, 0),
}

# Construction / training times in seconds
ACTION_DURATIONS: Dict[ActionType, int] = {
    ActionType.BUILD_FARM: 30,
    ActionType.BUILD_MINE: 45,
    ActionType.FOUND_OUTPOST: 120,
    ActionType.BUILD_BARRACKS: 60,
    ActionType.BUILD_TAVERN: 45,
    ActionType.TRAIN_SCOUT: 20,
    ActionType.TRAIN_WARRIOR: 15,
    ActionType.SUMMON_COMMANDER: 5,
    ActionType.CLEAR_FEATURE: 10,
}

ACTION_PREREQUISITES: Dict[ActionType, str] = {
    ActionType.BUILD_MINE: "mining",
    ActionType.BUILD_FARM: "agriculture",
    ActionType.FOUND_OUTPOST: "currency",
    ActionType.BUILD_TAVERN: "bronze_working",
    ActionType.BUILD_BARRACKS: "bronze_working",
    ActionType.TRAIN_SCOUT: "bronze_working",
    ActionType.TRAIN_WARRIOR: "bronze_working",
    ActionType.SUMMON_COMMANDER: "bronze_working",
}

STRUCTURE_ACTIONS = {
    ActionType.BUILD_FARM,
    ActionType.FOUND_OUTPOST,
    ActionType.BUILD_MINE,
    ActionType.BUILD_BARRACKS,
    ActionType.BUILD_TAVERN,
}

UNIT_ACTIONS = {
    ActionType.TRAIN_SCOUT,
    ActionType.TRAIN_WARRIOR,
    ActionType.SUMMON_COMMANDER,
}

class GameRulesEngine:
    """Authoritative strategy rules validation and math engine."""

    @staticmethod
    def validate_bounds(x: int, y: int, max_w: int = 32, max_h: int = 32) -> None:
        if x < 0 or x >= max_w or y < 0 or y >= max_h:
            raise TileNotFoundError(x, y)

    @staticmethod
    def validate_technology(action_type: ActionType, unlocked_techs: List[str]) -> None:
        """Checks if the player has the required technology to perform an action."""
        required_tech = ACTION_PREREQUISITES.get(action_type)

        # If a tech is required but the player doesn't have it, block the action
        if required_tech and required_tech not in unlocked_techs:
            raise GameRuleViolation(
                f"Missing technology. You must research '{required_tech}' before you can use {action_type.value}."
            )

    @staticmethod
    def validate_affordability(action_type: ActionType, resources: PlayerResources) -> Tuple[int, int]:
        if action_type not in ACTION_COSTS:
            raise GameRuleViolation(f"Unrecognized action type: {action_type}")
        
        gold_cost, prod_cost = ACTION_COSTS[action_type]
        if resources.gold < gold_cost or resources.production < prod_cost:
            raise InsufficientResourcesError(
                message=f"Insufficient funds for {action_type.value}. Requires {gold_cost}G, {prod_cost}P.",
                required={"gold": gold_cost, "production": prod_cost},
                available={"gold": resources.gold, "production": resources.production},
            )
        return gold_cost, prod_cost

    @staticmethod
    def validate_action_target(action_type: ActionType, tile: TileState) -> None:
        # Check impassable / invalid biomes
        if tile.type == TileType.WATER:
            raise GameRuleViolation("Cannot construct civilian or military structures in deep ocean.")
        
        if tile.type == TileType.MOUNTAIN:
            if action_type in (ActionType.BUILD_FARM, ActionType.FOUND_OUTPOST, ActionType.BUILD_BARRACKS, ActionType.BUILD_TAVERN):
                raise GameRuleViolation("Impassable mountain peaks cannot support farms or outposts.")
            if action_type in UNIT_ACTIONS:
                raise GameRuleViolation("Impassable mountain peaks cannot support military or scout units.")

        # Check structure occupation conflicts (only structures conflict with existing structures)
        if action_type in STRUCTURE_ACTIONS and tile.entity is not None:
            raise TileConflictError(
                f"Tile ({tile.coord.x}, {tile.coord.y}) already contains structure: {tile.entity.name}."
            )

        # Units cannot stack on the same tile
        if action_type in UNIT_ACTIONS and tile.unit is not None:
            raise TileConflictError(
                f"Tile ({tile.coord.x}, {tile.coord.y}) is occupied by unit: {tile.unit.name}."
            )

        # Feature clearing validation
        if action_type == ActionType.CLEAR_FEATURE and tile.type != TileType.FOREST:
            raise GameRuleViolation("Feature clearing can only be performed on forest tiles.")

    @staticmethod
    def apply_action_mutation(action_type: ActionType, tile: TileState, faction: str = "Player 1") -> TileState:
        """Computes the new TileState after validated action execution."""
        new_entity: Optional[TileEntity] = tile.entity
        new_unit: Optional[TileEntity] = tile.unit
        updated_yields: ResourceYield = tile.yields
        updated_type: TileType = tile.type

        # Calculate when this building or unit will be finished
        duration = ACTION_DURATIONS.get(action_type, 0)
        completion_time = int(time.time()) + duration

        if action_type == ActionType.BUILD_FARM:
            new_entity = TileEntity(
                id=f"farm_{tile.coord.x}_{tile.coord.y}",
                name="Hydroponic Farm",
                type="farm",
                owner_faction=faction,
                health=50,
                max_health=50,
                ready_at=completion_time
            )
            # Farm enhances food yield by +2
            updated_yields = ResourceYield(
                food=tile.yields.food + 2,
                production=tile.yields.production,
                gold=tile.yields.gold,
                science=tile.yields.science,
            )
        elif action_type == ActionType.FOUND_OUTPOST:
            new_entity = TileEntity(
                id=f"outpost_{tile.coord.x}_{tile.coord.y}",
                name="Frontier Outpost",
                type="city",
                owner_faction=faction,
                health=200,
                max_health=200,
                ready_at=completion_time
            )
            # Outpost adds production +2, science +1
            updated_yields = ResourceYield(
                food=tile.yields.food + 1,
                production=tile.yields.production + 2,
                gold=tile.yields.gold + 1,
                science=tile.yields.science + 1,
            )
        elif action_type == ActionType.BUILD_MINE:
            new_entity = TileEntity(
                id=f"mine_{tile.coord.x}_{tile.coord.y}",
                name="Extraction Mine",
                type="mine",
                owner_faction=faction,
                health=75,
                max_health=75,
                ready_at=completion_time
            )
            updated_yields = ResourceYield(
                food=tile.yields.food,
                production=tile.yields.production + 3,
                gold=tile.yields.gold + 1,
                science=tile.yields.science,
            )
        elif action_type == ActionType.BUILD_BARRACKS:
            new_entity = TileEntity(
                id=f"barracks_{tile.coord.x}_{tile.coord.y}",
                name="Garrison Barracks",
                type="barracks",
                owner_faction=faction,
                health=200,
                max_health=200,
                ready_at=completion_time
            )
            updated_yields = ResourceYield(
                food=tile.yields.food,
                production=tile.yields.production + 2,
                gold=tile.yields.gold,
                science=tile.yields.science,
            )
        elif action_type == ActionType.BUILD_TAVERN:
            new_entity = TileEntity(
                id=f"tavern_{tile.coord.x}_{tile.coord.y}",
                name="Grand Tavern",
                type="tavern",
                owner_faction=faction,
                health=300,
                max_health=300,
                ready_at=completion_time
            )
            updated_yields = tile.yields

        elif action_type == ActionType.TRAIN_WARRIOR:
            new_unit = TileEntity(
                id=f"warrior_{tile.coord.x}_{tile.coord.y}_{int(time.time())}",
                name="Axe Warrior",
                type="warrior",
                owner_faction=faction,
                health=150,
                max_health=150,
                ready_at=completion_time
            )
            updated_yields = tile.yields

        elif action_type == ActionType.TRAIN_SCOUT:
            new_unit = TileEntity(
                id=f"scout_{tile.coord.x}_{tile.coord.y}_{int(time.time())}",
                name="Pioneer Scout",
                type="scout",
                owner_faction=faction,
                health=100,
                max_health=100,
                ready_at=completion_time
            )
            updated_yields = tile.yields

        elif action_type == ActionType.SUMMON_COMMANDER:
            roll = random.randint(1, 100)
            if roll >= 95:  # 5% chance for SSR
                hero_name = "SSR King Arthur"
                hp = 1000
            elif roll >= 75:  # 20% chance for SR
                hero_name = "SR Mercenary Captain"
                hp = 400
            else:  # 75% chance for R
                hero_name = "R Local Militia"
                hp = 150

            new_unit = TileEntity(
                id=f"hero_{tile.coord.x}_{tile.coord.y}_{int(time.time())}",
                name=hero_name,
                type="hero",
                owner_faction=faction,
                health=hp,
                max_health=hp,
                ready_at=completion_time
            )
            updated_yields = tile.yields

        elif action_type == ActionType.CLEAR_FEATURE:
            updated_type = TileType.PLAINS
            updated_yields = ResourceYield(
                food=2,
                production=0,
                gold=1,
                science=0,
            )

        else:
            raise GameRuleViolation(f"Mutation logic for {action_type} not yet implemented.")

        return TileState(
            coord=tile.coord,
            type=updated_type,
            yields=updated_yields,
            entity=new_entity,
            unit=new_unit,
            is_explored=True,
            is_visible=True,
            territory_owner=faction,
        )

    @staticmethod
    def calculate_turn_harvest(tiles: List[TileState], faction: str = "Player 1") -> ResourceYield:
        """Sums yields across all territory controlled by the faction."""
        total_food = 0
        total_prod = 0
        total_gold = 0
        total_sci = 0

        for tile in tiles:
            if tile.territory_owner == faction:
                total_food += tile.yields.food
                total_prod += tile.yields.production
                total_gold += tile.yields.gold
                total_sci += tile.yields.science

        return ResourceYield(
            food=total_food,
            production=total_prod,
            gold=total_gold,
            science=total_sci,
        )

    @staticmethod
    def is_under_construction(entity: Optional[TileEntity]) -> bool:
        if not entity or not entity.ready_at:
            return False
        return int(time.time()) < entity.ready_at

    
