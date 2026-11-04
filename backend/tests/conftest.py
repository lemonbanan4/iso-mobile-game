import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.state.repository import InMemoryGameStateRepository, get_game_repo

@pytest.fixture
def fresh_repo():
    """Provides an isolated in-memory repository for each test."""
    return InMemoryGameStateRepository()

@pytest_asyncio.fixture
async def client(fresh_repo):
    """Provides an asynchronous test client with fresh game state injection."""
    app.dependency_overrides[get_game_repo] = lambda: fresh_repo
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()
