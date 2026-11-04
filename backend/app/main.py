from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.exceptions import (
    GameRuleViolation,
    InsufficientResourcesError,
    TileConflictError,
    TileNotFoundError,
)
from app.api.v1.router import api_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup tasks (e.g. database pool connection if configured)
    yield
    # Shutdown tasks

app = FastAPI(
    title="Iso Syndicate Backend Engine",
    description="Authoritative game state, district action validation, and cycle progression API for the mobile sci-fi syndicate strategy game.",
    version=settings.VERSION,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

# CORS Middleware for mobile dev & local web debugging
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Domain Exception Handlers
@app.exception_handler(GameRuleViolation)
async def game_rule_violation_handler(request: Request, exc: GameRuleViolation):
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={"detail": exc.message, "error_type": "RULE_VIOLATION"},
    )

@app.exception_handler(InsufficientResourcesError)
async def insufficient_resources_handler(request: Request, exc: InsufficientResourcesError):
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={
            "detail": exc.message,
            "error_type": "INSUFFICIENT_RESOURCES",
            "required": exc.required,
            "available": exc.available,
        },
    )

@app.exception_handler(TileConflictError)
async def tile_conflict_handler(request: Request, exc: TileConflictError):
    return JSONResponse(
        status_code=status.HTTP_409_CONFLICT,
        content={"detail": exc.message, "error_type": "TILE_CONFLICT"},
    )

@app.exception_handler(TileNotFoundError)
async def tile_not_found_handler(request: Request, exc: TileNotFoundError):
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={"detail": exc.message, "error_type": "TILE_NOT_FOUND"},
    )

# Health Probe for Google Cloud Run
@app.get("/health", tags=["System"])
async def health_check():
    return {"status": "healthy", "service": "iso-strategy-backend"}

# Mount V1 API
app.include_router(api_router, prefix=settings.API_V1_STR)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host=settings.HOST, port=settings.PORT, reload=settings.DEBUG)
