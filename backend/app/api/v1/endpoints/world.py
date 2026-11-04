from typing import List
from fastapi import APIRouter, Depends, HTTPException, Query, status
from app.models.tile import TileState, WorldMapResponse
from app.state.repository import IGameStateRepository, get_game_repo

router = APIRouter()

@router.get(
    "/tiles",
    response_model=WorldMapResponse,
    summary="Fetch World Map Sectors",
    description="Returns the full isometric strategy world grid and current terrain state.",
)
async def get_world_map(
    repo: IGameStateRepository = Depends(get_game_repo),
) -> WorldMapResponse:
    tiles = await repo.get_all_tiles()
    return WorldMapResponse(width=32, height=32, tiles=tiles)

@router.get(
    "/tiles/{x}/{y}",
    response_model=TileState,
    summary="Get Specific Tile State",
    description="Retrieves authoritative state for a specific discrete grid coordinate.",
)
async def get_tile_by_coord(
    x: int,
    y: int,
    repo: IGameStateRepository = Depends(get_game_repo),
) -> TileState:
    tile = await repo.get_tile(x, y)
    if not tile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tile ({x}, {y}) not found within map bounds.",
        )
    return tile
