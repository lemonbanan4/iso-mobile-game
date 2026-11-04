from fastapi import APIRouter, Depends, HTTPException, status
from app.models.action import EndTurnRequest, EndTurnResponse
from app.models.common import PlayerResources, PlayerState
from app.engine.rules import GameRulesEngine
from app.state.repository import IGameStateRepository, get_game_repo
import random

router = APIRouter()

@router.post(
    "/end",
    response_model=EndTurnResponse,
    status_code=status.HTTP_200_OK,
    summary="End Player Turn",
    description="Advances game turn, harvests territory resource yields, and returns updated ledger.",
)
async def end_turn(
    request: EndTurnRequest,
    repo: IGameStateRepository = Depends(get_game_repo),
) -> EndTurnResponse:
    current_turn = await repo.get_current_turn()

    # Client-server turn synchronization check
    if request.turn != current_turn:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Turn desynchronization. Client reported turn {request.turn}, but server is on turn {current_turn}.",
        )

    # 1. Harvest yields from all controlled territory
    all_tiles = await repo.get_all_tiles()
    harvest = GameRulesEngine.calculate_turn_harvest(all_tiles, faction="Player 1")

    # 2. Compound player resources
    current_state = await repo.get_player_state()

    # Calculate the new resources by harvesting
    new_resources = PlayerResources(
        gold=current_state.resources.gold + harvest.gold,
        science=current_state.resources.science + harvest.science,
        production=current_state.resources.production + harvest.production,
        food=current_state.resources.food + harvest.food,
    )

    # Repackage the resources and preserve the unlocked techs
    updated_state = PlayerState(
        resources=new_resources,
        unlocked_techs=current_state.unlocked_techs
    )

    # 3. Advance turn counter
    next_turn = current_turn + 1
    await repo.update_player_state(updated_state)
    await repo.set_current_turn(next_turn)

    # --- ENEMY AI PHASE (BARBARIANS) ---
    barb_tiles = [t for t in all_tiles if t.unit and t.unit.owner_faction == "Barbarians"]
    ai_combat_logs = []

    for b_tile in barb_tiles:
        b_x, b_y = b_tile.coord.x, b_tile.coord.y
        attacker = b_tile.unit
        
        # Satisfy strict type-checkers (resolves '"name" is not a known attribute of "None"')
        if not attacker:
            continue
        
        # 1. Look for adjacent Player 1 targets (Up, Down, Left, Right)
        adjacent_coords = [
            (b_x, b_y-1), (b_x, b_y+1), (b_x-1, b_y), (b_x+1, b_y), (b_x-1, b_y-1), (b_x+1, b_y+1), (b_x-1, b_y+1), (b_x+1, b_y-1)
        ]
        target_found = False
        
        for ax, ay in adjacent_coords:
            target_tile = await repo.get_tile(ax, ay)
            if not target_tile:
                continue

            # Target Player 1 units or buildings, not fellow barbarians
            target_defender = None
            if target_tile.unit and target_tile.unit.owner_faction == "Player 1":
                target_defender = target_tile.unit
            elif target_tile.entity and target_tile.entity.owner_faction == "Player 1":
                target_defender = target_tile.entity

            if target_defender:
                print(f"⚔️ BARBARIAN SPOTTED TARGET: {target_defender.name} at {ax},{ay}!")
                # Attack
                damage_dealt = random.randint(15, 35)
                target_defender.health -= damage_dealt
                ai_combat_logs.append(f"{attacker.name} hit {target_defender.name} for {damage_dealt} DMG!")

                if target_defender.health <= 0:
                    ai_combat_logs.append(f"Your {target_defender.name} was destroyed by Barbarians!")
                    # Accurately wipe the one that died
                    if target_tile.unit and target_tile.unit.id == target_defender.id:
                        target_tile.unit = None
                    else:
                        target_tile.entity = None

                await repo.update_tile(target_tile)
                target_found = True
                break

        # 2. Roam randomly if no targets are nearby
        if not target_found:
            roam_coord = random.choice(adjacent_coords)
            roam_tile = await repo.get_tile(roam_coord[0], roam_coord[1])
            
            # Ensure tile exists, isn't impassable, and is completely empty
            if roam_tile and str(roam_tile.type) not in ["water", "mountain", "TileType.WATER", "TileType.MOUNTAIN"]:
                if not roam_tile.unit and not roam_tile.entity:
                    await repo.move_entity((b_x, b_y), (roam_coord[0], roam_coord[1]))

    # Combine AI actions into the turn summary message
    turn_message = f"Turn {next_turn} begun. Harvested {harvest.food} food, {harvest.production} prod, {harvest.gold} gold, {harvest.science} sci."
    if ai_combat_logs:
        turn_message = "WARNING: " + " ".join(ai_combat_logs)
        
    # Return a single, valid EndTurnResponse model instead of two conflicting returns
    return EndTurnResponse(
        current_turn=next_turn,
        resources=new_resources,
        harvested_yields=harvest,
        message=turn_message,
    )