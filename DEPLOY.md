# Iso Syndicate — Production Deploy

The client is a **Flutter web** app (not Vite/React). Production hosting serves the static bundle from `frontend/build/web`. Local progress uses browser `localStorage`; the FastAPI backend remains optional for online world sync.

---

## 1. Production build (local)

```bash
chmod +x scripts/build_web.sh
./scripts/build_web.sh
```

Output: `frontend/build/web`

Preview:

```bash
cd frontend
python3 -m http.server 4173 --directory build/web
# open http://127.0.0.1:4173
```

---

## 2. GitHub Pages (recommended mobile URL)

Workflow: `.github/workflows/deploy-web.yml`

1. Repo **Settings → Pages → Source: GitHub Actions**
2. Push to `main` (or run the workflow manually)
3. Live URL (project pages):

   `https://lemonbanan4.github.io/iso-mobile-game/`

The workflow builds with `--base-href /iso-mobile-game/` so assets resolve on project Pages.

---

## 3. Netlify

Config: `netlify.toml` + `scripts/netlify_flutter_build.sh`

1. New site → import `lemonbanan4/iso-mobile-game`
2. Netlify reads `netlify.toml` (Flutter install + `flutter build web`)
3. Publish dir: `frontend/build/web`
4. Site URL: `https://<your-site>.netlify.app` (mobile-friendly HTTPS)

**Faster alternative:** run `./scripts/build_web.sh` locally, then Netlify CLI:

```bash
npx netlify deploy --prod --dir=frontend/build/web
```

---

## 4. Vercel

Config: `vercel.json`

Vercel does not ship Flutter by default. Options:

**A. Prebuild + static upload**

```bash
./scripts/build_web.sh
npx vercel deploy --prebuilt --prod
# or drag-drop frontend/build/web in the Vercel dashboard
```

**B. Point `outputDirectory` at a CI artifact**  
Use GitHub Actions to build, then deploy the `build/web` folder as a static project with:

- Install / Build: leave empty or `echo skip`
- Output: `frontend/build/web`

SPA fallback rewrites are already in `vercel.json`.

---

## 5. Backend (optional for live play)

Static hosting alone runs the offline economy / AI / localStorage loop. For authoritative world sync:

```bash
cd backend
source .venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Point the Flutter client API host at your production API (Cloud Run / Docker) when leaving localhost.

Docker Compose still serves API on `:8080` for container deploys.

---

## 6. Mobile checklist

- [x] PWA manifest (`frontend/web/manifest.json`) — standalone, portrait
- [x] Touch pan / pinch zoom on isometric grid
- [x] SafeArea HUD + glass panels
- [x] `localStorage` persistence survives refresh
- [ ] Confirm live HTTPS URL on a phone after Pages/Netlify deploy
