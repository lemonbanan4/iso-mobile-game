import pytest

@pytest.mark.asyncio
async def test_end_turn_advances_and_harvests(client, fresh_repo):
    initial_resources = await fresh_repo.get_player_resources()

    response = await client.post("/v1/turns/end", json={"turn": 1})
    assert response.status_code == 200
    data = response.json()

    assert data["current_turn"] == 2
    # Verify resources grew by territory harvest
    assert data["resources"]["gold"] > initial_resources.gold
    assert data["resources"]["food"] > initial_resources.food

@pytest.mark.asyncio
async def test_end_turn_desynchronization_rejection(client):
    # Server is on turn 1, client sends turn 5
    response = await client.post("/v1/turns/end", json={"turn": 5})
    assert response.status_code == 409
    assert "Turn desynchronization" in response.json()["detail"]
