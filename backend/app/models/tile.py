from enum import Enum
from typing import Optional, List, Dict
from pydantic import BaseModel, Field
from app.models.common import GridCoord, ResourceYield

class TileType(str, Enum):
    PLAINS = "plains"
    FOREST = "forest"
    MOUNTAIN = "mountain"
    WATER = "water"
    HILLS = "hills"
    DESERT = "desert"

class TileEntity(BaseModel):
    id: str = Field(..., description="Unique entity GUID")
    name: str = Field(..., description="Display title (e.g. Hydroponic Farm, New Alexandria)")
    type: str = Field(..., description="Entity classification: 'city', 'scout', 'farm', 'mine'")
    owner_faction: str = Field(default="Player 1", description="Controlling faction ID")
    health: int = Field(default=100, ge=0, description="Current structural health")
    max_health: int = Field(default=100, ge=1, description="Maximum health capacity")
    ready_at: Optional[int] = None # Unix timestamp (seconds) for when construction

class TileState(BaseModel):
    coord: GridCoord = Field(..., description="Isometric tile grid coordinate")
    type: TileType = Field(..., description="Terrain biome")
    yields: ResourceYield = Field(..., description="Base resource yield harvested per turn")
    entity: Optional[TileEntity] = Field(default=None, description="Occupying structure or unit")
    unit: Optional[TileEntity] = Field(default=None, description="Occupying mobile unit")
    is_explored: bool = Field(default=True, description="Fog of war explored flag")
    is_visible: bool = Field(default=True, description="Line-of-sight visibility")
    territory_owner: Optional[str] = Field(default=None, description="Controlling faction for territory borders")

class WorldMapResponse(BaseModel):
    width: int = Field(..., description="Total map width in tiles")
    height: int = Field(..., description="Total map height in tiles")
    tiles: List[TileState] = Field(..., description="List of all serialized tile sectors")
