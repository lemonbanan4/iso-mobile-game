# Iso Syndicate

Mobile-first **sci-fi mafia / underground criminal syndicate** management and strategy game. Expand your cells across an isometric city grid, balance Credits and Contraband, keep Syndicate Loyalty high, and manage Heat before the authorities close in.

---

## Overview

You run a neon-soaked underground network. Each turn you harvest illicit yields from controlled districts, place modular cells (safehouses, dens, enforcement racks, black-market lounges), move crews, and react to randomized syndicate encounters in the event ticker.

The client is a **Flutter + Flame** isometric app optimized for touch (pan, pinch-zoom, tap-to-select). The **FastAPI** backend is the authoritative rules engine for world state, actions, combat, and turn progression.

> **Note on stack:** This repository ships Flutter/Flame (not React/Tailwind). The existing isometric math, Flame grid, and Riverpod game state are the source of truth for the mobile client.

---

## Tech stack

| Layer | Technology |
| --- | --- |
| Client | Flutter 3.x, Flame, Riverpod, Dio/HTTP, Google Fonts |
| Server | Python 3.12, FastAPI, Pydantic v2, Uvicorn |
| Contracts | OpenAPI 3.1 (`contracts/`) |
| Infra | Docker Compose, GitHub Actions CI, Cloud Run–ready Dockerfile |
| Tooling | Pytest, Flutter analyze/test/web build |

---

## Repository layout

```
iso_game/
├── frontend/          # Flutter + Flame mobile/web client
│   └── lib/
│       ├── core/      # Iso math, theme, constants
│       ├── game/      # Flame isometric world
│       ├── state/     # Riverpod game state
│       └── ui/        # HUD: resources, district inspector, event log
├── backend/           # FastAPI authoritative engine
│   └── app/
│       ├── api/       # /v1 world, actions, turns
│       ├── engine/    # Rules, world generation
│       └── state/     # Persistence repository
├── contracts/         # OpenAPI source of truth + verify scripts
├── scripts/           # build_all, test_all, deploy helpers
└── docker-compose.yml # Backend + Swagger UI
```

---

## Core gameplay loop

1. **Survey the grid** — Pan/zoom the isometric city; tap a district to inspect it.
2. **Place cells** — Spend Credits / Contraband to plant Safehouses, Smuggling Dens, Enforcement Cells, or Black Market Lounges on empty tiles.
3. **Run crews** — Move units, hit rival turf, defend your capital cell.
4. **Watch the ledger** — Track **Credits**, **Contraband**, **Syndicate Loyalty**, and **Heat** in the top dashboard.
5. **End the cycle** — Advance the turn to harvest yields, resolve rival AI pressure, and surface encounters in the **event log ticker**.
6. **Stay under the radar** — High Heat invites disaster; Loyalty and Credits keep the syndicate breathing.

### Resource mapping (UI ↔ API)

| Syndicate HUD | Backend field |
| --- | --- |
| Credits | `gold` |
| Contraband | `production` |
| Syndicate Loyalty | `science` |
| Heat | `food` |

API field names stay stable for OpenAPI compatibility; the client presents syndicate terminology.

---

## Prerequisites

- **Flutter** stable SDK (`flutter doctor` clean)
- **Python 3.12+** with `venv`
- **Docker** (optional, for Compose)
- Git

---

## Installation

### 1. Clone

```bash
git clone <your-remote-url> iso_game
cd iso_game
```

### 2. Backend

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Health check: [http://127.0.0.1:8000/health](http://127.0.0.1:8000/health)  
Docs: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

### 3. Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome          # or an iOS/Android device / emulator
```

The client expects the API at `http://127.0.0.1:8000`. Adjust host for physical devices (LAN IP / emulator aliases).

### 4. Docker (optional)

```bash
docker compose up --build
```

- Backend: `http://localhost:8080`
- Swagger UI: `http://localhost:8081`

---

## Testing & CI

```bash
# Full local orchestration
./scripts/test_all.sh

# Backend only
cd backend && pytest -v

# Frontend only
cd frontend && flutter analyze && flutter test
```

CI (`.github/workflows/ci.yml`) verifies OpenAPI contracts, runs Pytest, analyzes/builds Flutter web, and validates the backend Docker image.

---

## Branch structure

| Branch | Purpose |
| --- | --- |
| `main` | Stable release line |
| `develop` | Integration / ongoing feature work |

Feature work should branch from `develop` (e.g. `feature/event-encounters`) and merge back via PR.

---

## License / status

Private early prototype — syndicate management baseline with isometric district control, resource HUD, and encounter ticker.
