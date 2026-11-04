from enum import Enum
from typing import Dict, Any, Optional
from pydantic import BaseModel, Field
from app.models.common import PlayerResources, ResourceYield
from app.models.tile import TileState

class ActionType(str, Enum):
    BUILD_FARM = "build_farm"
    FOUND_OUTPOST = "found_outpost"
    BUILD_MINE = "build_mine"
    TRAIN_SCOUT = "train_scout"
    CLEAR_FEATURE = "clear_feature"
    BUILD_BARRACKS = "build_barracks"
    TRAIN_WARRIOR = "train_warrior"
    BUILD_TAVERN = "build_tavern"
    SUMMON_COMMANDER = "summon_commander"

class ActionRequest(BaseModel):
    action_type: ActionType = Field(..., description="Tactical action code")
    target_x: int = Field(..., ge=0, description="Target tile grid column")
    target_y: int = Field(..., ge=0, description="Target tile grid row")
    parameters: Dict[str, Any] = Field(default_factory=dict, description="Action-specific parameters")

class ActionResponse(BaseModel):
    success: bool = Field(default=True, description="Action execution status")
    message: str = Field(..., description="Action result or tactical readout")
    tile: TileState = Field(..., description="Authoritative server tile state after mutation")
    updated_resources: PlayerResources = Field(..., description="Authoritative player resource balance")

class EndTurnRequest(BaseModel):
    turn: int = Field(..., ge=1, description="Client's expected current turn number")

class EndTurnResponse(BaseModel):
    current_turn: int = Field(..., description="New authoritative server turn counter")
    resources: PlayerResources = Field(..., description="Total player resources after turn harvest")
    harvested_yields: ResourceYield = Field(..., description="Incremental resources collected this turn")
    message: str = Field(..., description="Turn report message")

class MoveRequest(BaseModel):
    from_x: int
    from_y: int
    to_x: int
    to_y: int
    player_id: str = "Player 1"

class ResearchRequest(BaseModel):
    tech_id: str
    player_id: str = "Player 1"

