import pytest
from app.models.common import PlayerResources

@pytest.mark.asyncio
async def test_build_farm_success(client, fresh_repo):
    # Target plains sector at (14, 14) inside Player 1 territory
    payload = {
        "action_type": "build_farm",
        "target_x": 14,
        "target_y": 14,
        "parameters": {},
    }
    response = await client.post("/v1/actions", json=payload)
    assert response.status_code == 200
    tile = response.json()
    assert tile["entity"]["name"] == "Hydroponic Farm"
    assert tile["entity"]["type"] == "farm"
    assert tile["territory_owner"] == "Player 1"

    # Verify resource deduction (Farm costs 30G, 20P; initial is 150G, 80P)
    resources = await fresh_repo.get_player_resources()
    assert resources.gold == 120
    assert resources.production == 60

@pytest.mark.asyncio
async def test_action_insufficient_resources_rejection(client, fresh_repo):
    # Set resources to 0
    await fresh_repo.update_player_resources(PlayerResources(gold=0, production=0))

    payload = {
        "action_type": "build_farm",
        "target_x": 14,
        "target_y": 14,
        "parameters": {},
    }
    response = await client.post("/v1/actions", json=payload)
    assert response.status_code == 400
    assert "Insufficient funds" in response.json()["detail"]

@pytest.mark.asyncio
async def test_action_ocean_terrain_violation(client):
    # Coordinate (8, 8) is procedural ocean
    payload = {
        "action_type": "build_farm",
        "target_x": 8,
        "target_y": 8,
        "parameters": {},
    }
    response = await client.post("/v1/actions", json=payload)
    assert response.status_code == 400
    assert "deep ocean" in response.json()["detail"].lower()

@pytest.mark.asyncio
async def test_action_conflict_on_occupied_tile(client):
    # (15, 15) already has capital city New Alexandria
    payload = {
        "action_type": "build_farm",
        "target_x": 15,
        "target_y": 15,
        "parameters": {},
    }
    response = await client.post("/v1/actions", json=payload)
    assert response.status_code == 409
    assert "already contains structure" in response.json()["detail"]
