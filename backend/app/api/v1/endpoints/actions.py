from unittest.mock import Base
import random
import time
from fastapi import APIRouter, Depends, HTTPException, status
from app.models.action import ActionRequest, MoveRequest, ResearchRequest
from app.models.tile import TileState, TileEntity
from app.models.common import PlayerResources, PlayerState
from app.engine.rules import GameRulesEngine
from app.core.exceptions import (
    GameRuleViolation,
    InsufficientResourcesError,
    TileConflictError,
    TileNotFoundError,
)
from app.state.repository import IGameStateRepository, get_game_repo
from pydantic import BaseModel

TECH_TREE = {
    "agriculture": {"cost": 0, "name": "Agriculture"},
    "mining": {"cost": 50, "name": "Mining"},
    "writing": {"cost": 75, "name": "Writing"},
    "bronze_working": {"cost": 100, "name": "Bronze Working"},
    "currency": {"cost": 150, "name": "Currency"},
}

router = APIRouter()

@router.post(
    "",
    response_model=TileState,
    status_code=status.HTTP_200_OK,
    summary="Submit Player Action",
    description="Validates and applies tactical actions (e.g. Build Farm, Found Outpost) on the server.",
    responses={
        400: {"description": "Action violates game rules or insufficient resources"},
        404: {"description": "Target tile coordinates out of bounds"},
        409: {"description": "Action conflicts with current tile state"},
    },
)
async def submit_action(
    request: ActionRequest,
    repo: IGameStateRepository = Depends(get_game_repo),
) -> TileState:
    # 1. Bounds Validation
    GameRulesEngine.validate_bounds(request.target_x, request.target_y)

    tile = await repo.get_tile(request.target_x, request.target_y)
    if not tile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Target sector ({request.target_x}, {request.target_y}) not found.",
        )

    # 2. Resource Affordability Check
    player_state = await repo.get_player_state()
    # Check if they have the required technology
    try:
        GameRulesEngine.validate_technology(request.action_type, player_state.unlocked_techs)
    except GameRuleViolation as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=e.message,
        )
    # Check if they have the rqeuired gold/production
    try:
        gold_cost, prod_cost = GameRulesEngine.validate_affordability(request.action_type, player_state.resources)
    except InsufficientResourcesError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=e.message,
        )

    # 3. Strategy Rules & Conflict Validation
    try:
        GameRulesEngine.validate_action_target(request.action_type, tile)
    except TileConflictError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=e.message,
        )
    except GameRuleViolation as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=e.message,
        )

    # 4. Apply State Mutations Atomically
    updated_tile = GameRulesEngine.apply_action_mutation(request.action_type, tile)

    # First, calculate the new resource math
    updated_resources = PlayerResources(
        gold=player_state.resources.gold - gold_cost,
        science=player_state.resources.science,
        production=player_state.resources.production - prod_cost,
        food=player_state.resources.food,
    )

    # Next, package it back into the PlayerState while keeping existing techs
    updated_state = PlayerState(
        resources=updated_resources,
        unlocked_techs=player_state.unlocked_techs
    )

    await repo.update_tile(updated_tile)
    await repo.update_player_state(updated_state)

    return updated_tile

# ... (keep your existing submit_action route) ...

@router.post(
    "/move",
    status_code=status.HTTP_200_OK,
    summary="Move Unit",
    description="Validates tactical movement rules and updates entity positions.",
)
async def move_unit(
    request: MoveRequest,
    repo: IGameStateRepository = Depends(get_game_repo),
):

    # 1. Execute the move in the database
    await repo.move_entity((request.from_x, request.from_y), (request.to_x, request.to_y))

    # 2. --- FOG OF WAR REVEAL ---
    vision_radius = 2 # How far the unit can see

    for dy in range(-vision_radius, vision_radius + 1):
        for dx in range(-vision_radius, vision_radius + 1):
            # Creates a diamond shaped vision radius
            if abs(dx) + abs(dy) <= vision_radius:
                target_x = request.to_x + dx
                target_y = request.to_y + dy

                tile = await repo.get_tile(target_x, target_y)
                if tile and not tile.is_explored:
                    tile.is_explored = True
                    tile.is_visible = True
                    await repo.update_tile(tile) # Save the illuminated tile

    #return {"message": "Unit moved and explored the area."}

    source = await repo.get_tile(request.from_x, request.from_y)
    target = await repo.get_tile(request.to_x, request.to_y)

    # 1. Bounds Validation
    if not source or not target:
        raise HTTPException(status_code=404, detail="Coordinates out of bounds.")

    # 2. Ownership Validation
    source_unit = source.unit or (source.entity if source.entity and source.entity.type in ("scout", "warrior", "hero") else None)
    if not source_unit or source_unit.owner_faction != request.player_id:
        raise HTTPException(status_code=403, detail="No owned unit at source tile.")

    # 3. Collision Validation
    if target.unit is not None:
        raise HTTPException(status_code=409, detail="Target tile is already occupied by another unit.")

    # 4. Movement Range Validation (Strict 1-tile adjacency for prototype)
    dx = abs(request.from_x - request.to_x)
    dy = abs(request.from_y - request.to_y)
    if dx > 1 or dy > 1:
        raise HTTPException(status_code=400, detail="Target is too far. Max movement is 1 tile.")

    # 5. Terrain Validation
    if target.type in ["water", "mountain"]:
        raise HTTPException(status_code=400, detail=f"Units cannot move onto {target.type} terrain.")

    # 6. Apply Movement
    await repo.move_entity((request.from_x, request.from_y), (request.to_x, request.to_y))

    return {
        "status": "success",
        "message": f"Unit moved to ({request.to_x}, {request.to_y})",
        "updated_source": source,
        "updated_target": target
    }

@router.post(
    "/research",
    status_code=status.HTTP_200_OK,
    summary="Research Technology",
    description="Spends science to permanently unlock a new technology.",
)
async def research_tech(
    request: ResearchRequest,
    repo: IGameStateRepository = Depends(get_game_repo),
):
    player_state = await repo.get_player_state()
    tech_id = request.tech_id.lower().strip()

    # 1. Validate the technology exists
    if tech_id not in TECH_TREE:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Technology '{request.tech_id}' not found.",
        )

    # 2. Check if the player already researched it (idempotent success)
    if tech_id in player_state.unlocked_techs:
        return {
            "status": "success",
            "message": f"Technology '{TECH_TREE[tech_id]['name']}' is already unlocked.",
            "unlocked_techs": player_state.unlocked_techs,
            "resources": player_state.resources.dict(),
            "remaining_science": player_state.resources.science,
        }

    # 3. Check if the player can afford it
    tech_cost = TECH_TREE[tech_id]["cost"]
    if player_state.resources.science < tech_cost:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Not enough science. Requires {tech_cost}, but you have {player_state.resources.science}.",
        )

    # 4. Deduct science and unlock the technology
    player_state.resources.science -= tech_cost
    player_state.unlocked_techs.append(tech_id)

    # 5. Save the updated state to repository
    await repo.update_player_state(player_state)

    return {
        "status": "success",
        "message": f"Successfully researched {TECH_TREE[tech_id]['name']}!",
        "unlocked_techs": player_state.unlocked_techs,
        "resources": player_state.resources.dict(),
        "remaining_science": player_state.resources.science,
    }

class CombatRequest(BaseModel):
    source_x: int
    source_y: int
    target_x: int
    target_y: int
    player_id: str = "Player 1"

@router.post("/combat")
async def resolve_combat(request: CombatRequest):
    repo = get_game_repo()
    source_tile = await repo.get_tile(request.source_x, request.source_y)
    target_tile = await repo.get_tile(request.target_x, request.target_y)

    if not source_tile or not target_tile:
        raise HTTPException(status_code=404, detail="Tile not found.")

    attacker = source_tile.unit
    if not attacker or attacker.owner_faction != request.player_id:
        raise HTTPException(status_code=400, detail="No valid attacking unit selected.")

    # Target the unit first; if not unit, attack the bulding
    defender = target_tile.unit or target_tile.entity
    if not defender or defender.owner_faction == request.player_id:
        raise HTTPException(status_code=400, detail="Invalid target.")


    # Roll RNG Damage
    damage_dealt = random.randint(30, 60)
    damage_taken = random.randint(10, 40)

    defender.health -= damage_dealt
    attacker.health -= damage_taken

    combat_log = f"{attacker.name} hit {defender.name} for {damage_dealt} DMG! Took {damage_taken} DMG."

    # Process Fatalities
    if defender.health <= 0:
        combat_log += f" {defender.name} was destroyed!"
        if target_tile.unit:
            target_tile.unit = None
        else:
            target_tile.entity = None

    if attacker.health <= 0:
        combat_log += f" Your {attacker.name} died in battle!"
        source_tile.unit = None

    # Save to database
    await repo.update_tile(source_tile)
    await repo.update_tile(target_tile)

    return {
        "message": combat_log,
        "source_tile": source_tile.dict(),
        "target_tile": target_tile.dict()
    }

class SpeedUpRequest(BaseModel):
    target_x: int
    target_y: int
    item_id: str = "speedup_1m"
    player_id: str = "Player 1"

@router.post('/speedup')
async def apply_speedup(request: SpeedUpRequest):
    repo = get_game_repo()
    tile = await repo.get_tile(request.target_x, request.target_y)

    if not tile or not tile.entity:
        raise HTTPException(status_code=400, detail="No building found here.")

    #  Store it in a local variable for the type checker
    current_time = int(time.time())
    current_ready_at = tile.entity.ready_at

    # Check against None explicitly
    if current_ready_at is None or current_ready_at <= current_time:
        raise HTTPException(status_code=400, detail="Building is already finished.")

    # --- INVENTORY LOGIC GOES HERE ---
    # For prototype testing, we will assume the player has infinite speedups

    # Do the math on the guaranteed integer
    new_ready_at = current_ready_at - 60
    

    # Cap it so it doesnt finish in the past
    if new_ready_at < current_time:
        new_ready_at = current_time

    # Assign the safely calculated integer back to the model
    tile.entity.ready_at = new_ready_at

    await repo.update_tile(tile)

    return {
        "message": "Speed-up applied! -1 Minute.",
        "tile": tile.dict()
    }

class TileActionRequest(BaseModel):
    target_x: int
    target_y: int
    action_type: str
    player_id: str = "Player 1"

@router.post("")
async def execute_action(request: TileActionRequest):
    print(f"🛠️ SERVER RECEIVED ACTION: {request.action_type} at {request.target_x},{request.target_y}")
    
    repo = get_game_repo()
    tile = await repo.get_tile(request.target_x, request.target_y)
    player = await repo.get_player_state()

    if not tile:
        raise HTTPException(status_code=404, detail="Tile not found.")

    # --- ADD THIS TO PREVENT STACKING ---
    if request.action_type in ["train_warrior", "summon_commander"]:
        if tile.unit is not None:
            raise HTTPException(status_code=409, detail="Tile is occupied! Move your current unit first.")
            
    if request.action_type in ["build_farm", "build_mine", "build_barracks", "build_tavern"]:
        if tile.entity is not None:
            raise HTTPException(status_code=409, detail="There is already a building here.")

    if request.action_type == "summon_commander":
        # 1. Check Gold
        if player.resources.gold < 100:
            raise HTTPException(status_code=400, detail="Not enough Gold! Need 100.")

        # 2. Check if tile is empty of armies
        if tile.unit is not None:
            raise HTTPException(status_code=409, detail="Tile already has a unit on it.")

        # 3. Deduct Gold
        player.resources.gold -= 100
        await repo.update_player_state(player)

        # 4. Gacha RNG Roll (1-100)
        roll = random.randint(1, 100)

        if roll <= 60: # 60% Common
            hero_name = "Squire of the Realm"
            rarity = "Common"
            hp = 120
        elif roll <= 90: # 30% Rare
            hero_name = "Veteran Ranger"
            rarity = "Rare"
            hp = 160
        elif roll <= 99: # 9% Epic
            hero_name = "Knight Commander"
            rarity = "Epic"
            hp = 250
        else: # 1% Legendary
            hero_name = "Paladin of the Dawn"
            rarity = "Legendary"
            hp = 400

        # 5. Create the Hero Unit
        tile.unit = TileEntity(**{
            "id": f"hero_{request.target_x}_{request.target_y}_{roll}",
            "name": hero_name,
            "type": "hero",
            "owner_faction": request.player_id,
            "health": hp,
            "max_health": hp,
        })

        await repo.update_tile(tile)

        return {
            "message": f"Summoned {rarity} {hero_name}!",
            "tile": tile.dict(),
            "gacha_result": {
                "name": hero_name,
                "health": hp,
                "rarity": rarity
            }
        }

    raise HTTPException(status_code=400, detail="ACtion not implemented yet.")
    

