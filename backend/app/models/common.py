from pydantic import BaseModel, Field, ConfigDict
from typing import List

class GridCoord(BaseModel):
    model_config = ConfigDict(frozen=True)
    x: int = Field(..., ge=0, description="Horizontal discrete column coordinate")
    y: int = Field(..., ge=0, description="Vertical discrete row coordinate")

class ResourceYield(BaseModel):
    food: int = Field(default=0, ge=0, description="Food yield for population growth")
    production: int = Field(default=0, ge=0, description="Production hammers for building structures")
    gold: int = Field(default=0, ge=0, description="Treasury income per turn")
    science: int = Field(default=0, ge=0, description="Research points for technological advancements")

class PlayerResources(BaseModel):
    gold: int = Field(default=150, description="Current treasury gold balance")
    science: int = Field(default=45, description="Accumulated science research")
    production: int = Field(default=80, description="Stored production materials")
    food: int = Field(default=120, description="Grain/food supplies")

class PlayerState(BaseModel):
    resources: PlayerResources
    unlocked_techs: List[str] = []

    