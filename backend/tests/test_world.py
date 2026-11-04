import pytest

@pytest.mark.asyncio
async def test_get_world_map(client):
    response = await client.get("/v1/world/tiles")
    assert response.status_code == 200
    data = response.json()
    assert data["width"] == 32
    assert data["height"] == 32
    assert len(data["tiles"]) == 32 * 32

@pytest.mark.asyncio
async def test_get_specific_tile(client):
    # Capital sector at (15, 15)
    response = await client.get("/v1/world/tiles/15/15")
    assert response.status_code == 200
    tile = response.json()
    assert tile["coord"]["x"] == 15
    assert tile["coord"]["y"] == 15
    assert tile["entity"]["name"] == "New Alexandria"
    assert tile["entity"]["type"] == "city"

@pytest.mark.asyncio
async def test_get_tile_out_of_bounds(client):
    response = await client.get("/v1/world/tiles/99/99")
    assert response.status_code == 404
