# Stuff Organiser AI - backend deploy (Firebase)

Project pinned: `stuff-organiser` (see `.firebaserc`). Run everything from this `backend/` folder.

## One-time setups (before the first deploy)
1. **Firestore database** - console.firebase.google.com > your project > Build > Firestore Database > Create database > Native mode (production mode is fine) > pick any region.
2. **Blaze plan** - console bottom-left > Upgrade > Blaze. A card is required, but at this project's usage the free tiers cover everything - expect a $0 bill. (Cloud Functions v2 + secrets require the Blaze plan.)
3. **Node + CLI** - install Node LTS (nodejs.org) if missing, then `npm install -g firebase-tools`

## Deploy
```
cd backend
npm --prefix functions install        # optional, speeds the first deploy
firebase login                       # browser opens
firebase functions:secrets:set SHARED_SECRET   # paste the shared secret (provided in email)
firebase deploy --only functions,hosting,firestore:rules
```
Success = `Deploy complete`. Endpoint origin: `https://stuff-organiser.web.app` - routes:
- `POST /api/scans` - app uploads (bearer)
- `GET /api/scans?status=received` - lanes pull (bearer)
- `POST /api/renders/{scanId}` - Cellulose render return (bearer)
- `GET /api/results/{scanId}` - app fetch (open)

## CI alternative
Service-account key as a repo secret > CI deploys. Keys never in code, same rule as always.

## Privacy flags (honest)
1. v1: scan/render files are public-read bucket objects at unguessable keyed URLs - rotate to signed URLs in v2.
2. The app-side secret is build-time injected from repo secret `SOAI_API_SECRET` and is extractable from the public web build - acceptable for the steward group's debug deployment; rotate if it ever opens wider.
3. Firestore: client reads/writes denied everywhere except a user's own `users/{uid}` docs; the backend writes via Admin SDK only.
