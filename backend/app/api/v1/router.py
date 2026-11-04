from fastapi import APIRouter
from app.api.v1.endpoints import world, actions, turns

api_router = APIRouter()
api_router.include_router(world.router, prefix="/world", tags=["World Map"])
api_router.include_router(actions.router, prefix="/actions", tags=["Tactical Actions"])
api_router.include_router(turns.router, prefix="/turns", tags=["Turn Management"])
