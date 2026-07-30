# Deployment Guide

This repository uses:

- Frontend: Vercel Git Integration (`htr-frontend`, Node.js 22)
- Backend: Render Blueprint (`hows-the-rent-api`)
- Database: the existing external Render PostgreSQL instance
- CI gate: GitHub Actions check `Release gate`

GitHub Actions validates the application but never stores deployment credentials or calls platform deployment APIs.

The app uses HttpOnly cookie authentication. To avoid cross-site cookie problems, deploy the frontend on Vercel and let Vercel proxy `/api/*` to the Render backend.

## CI/CD dashboard bootstrap

Complete these settings before merging the CI/CD implementation PR.

### GitHub ruleset for `master`

- Require pull requests.
- Require `Release gate` and require the branch to be up to date.
- Block normal direct pushes, force pushes, and branch deletion.
- Apply the rule to administrators; any temporary bypass is break-glass and must be audited.
- Do not rename `Release gate` until GitHub and Vercel settings are updated together.

### Vercel

- Keep the GitHub project root at `htr-frontend` and production branch at `master`.
- Set the project Node.js version to 22.
- Keep automatic production aliasing enabled.
- Enable Deployment Checks with the GitHub provider and select only `Release gate`.
- Deployment Checks gate production alias promotion; Vercel may build a candidate before the check passes.
- Do not configure a deploy hook, Vercel CLI deployment, or `VERCEL_TOKEN`.

### Render

- Confirm the Blueprint is attached to `hows-the-rent-api`, branch `master`, with Blueprint Auto Sync enabled.
- Before merge, set Auto-Deploy to **After CI Checks Pass**. If a Blueprint-managed service cannot be updated safely, disable auto-deploy and do not merge yet.
- After merge, confirm Blueprint sync preserves `autoDeployTrigger: checksPass` and health path `/api/health`.
- Render evaluates every CI check it detects; it does not provide the Vercel-style allowlist.

## 1. Database

Use the existing Render PostgreSQL instance. It is managed outside this repository's `render.yaml`; do not add a second Blueprint database.

Keep these values in the Render backend service environment:

```env
DB_URL=jdbc:postgresql://<render-host>/<database>?sslmode=require
DB_USER=<username>
DB_PASSWORD=<password>
```

The backend currently uses `spring.jpa.hibernate.ddl-auto=update`. Schema-breaking changes are not safe in a single release; follow the expand/contract policy in the recovery section.

## 2. Backend on Render

Use the root `render.yaml` blueprint, or create a Render Web Service manually.

Manual settings:

- Runtime: Docker
- Root directory: `htr-backend`
- Dockerfile path: `./Dockerfile`
- Plan: Free
- Health check path: `/api/health`

Required Render env vars:

```env
DB_URL=jdbc:postgresql://<host>/<database>?sslmode=require
DB_USER=<username>
DB_PASSWORD=<password>
JWT_SECRET=<generate-a-long-random-secret>
CORS_ALLOWED_ORIGINS=https://<your-vercel-app>.vercel.app
COOKIE_SECURE=true
COOKIE_SAME_SITE=Lax
```

Optional but needed for complete features:

```env
PAYOS_CLIENT_ID=<payos-client-id>
PAYOS_API_KEY=<payos-api-key>
PAYOS_CHECKSUM_KEY=<payos-checksum-key>
PAYOS_RETURN_URL=https://<your-vercel-app>.vercel.app/payment/success
PAYOS_CANCEL_URL=https://<your-vercel-app>.vercel.app/payment/cancel

MAIL_USERNAME=<smtp-user>
MAIL_PASSWORD=<smtp-app-password>

# Cloudflare R2 / S3-compatible object storage
MINIO_URL=https://<account-id>.r2.cloudflarestorage.com
MINIO_PUBLIC_URL=https://<public-r2-domain>
MINIO_ACCESS_KEY=<r2-access-key>
MINIO_SECRET_KEY=<r2-secret-key>
MINIO_BUCKET=htr
MINIO_AUTO_CREATE_BUCKET=false
```

Password reset OTP is stored in backend memory for this demo deployment, so no Redis service is required. OTPs expire after 15 minutes. If Render restarts or sleeps before the user submits the OTP, they should request a new code.

Render provides `PORT` automatically. `application.properties` reads it via `server.port=${PORT:${SERVER_PORT:8080}}`.

## 3. Frontend on Vercel

Create a Vercel project from the same repository.

Settings:

- Root directory: `htr-frontend`
- Framework preset: Vite
- Build command: `npm run build`
- Output directory: `dist`

The frontend has `htr-frontend/vercel.json`:

```json
{
  "rewrites": [
    {
      "source": "/api/:path*",
      "destination": "https://hows-the-rent-api.onrender.com/api/:path*"
    }
  ]
}
```

After you know the actual Render URL, update the `destination` to your backend URL.

Do not set `VITE_API_BASE_URL` when using this rewrite. In production the app will call same-origin `/api`, and Vercel will proxy it to Render.

## 4. PayOS callback

In PayOS dashboard, configure webhook/callback to either:

```txt
https://<your-render-service>.onrender.com/api/payment/callback
```

or, if using the Vercel rewrite path:

```txt
https://<your-vercel-app>.vercel.app/api/payment/callback
```

## First CI/CD rollout

1. Open the PR containing the H2 profile, workflow, Blueprint, and this guide.
2. Confirm `Frontend quality`, `Backend verify`, `Backend Docker build`, and `Release gate` all appear and pass.
3. Configure the GitHub ruleset and Vercel Deployment Checks before merge.
4. Configure Render for checks-pass deployment before merge.
5. Merge only after all three external settings are ready.
6. Record the merged commit SHA.
7. Confirm `Release gate` finishes before Vercel production promotion and before Render deployment starts.
8. Inspect both GitHub Check Runs and Commit Statuses for that SHA. Render does not document whether the Vercel-generated Commit Status belongs to its detected-check set.
9. Record the frontend production SHA and backend production SHA separately.
10. Run the smoke checks below.

If Render remains pending or does not start within 30 minutes after the CI gate passes, keep the current production release, disable native Render auto-deploy, and do not bypass the gate. A GitHub-controlled Render fallback requires a separate approved design.

## 5. Smoke checks after deploy

- Open `https://<render-service>.onrender.com/api/health` and verify `{ "status": "ok" }`.
- Open the Vercel app.
- Login and navigate between pages; there should be no repeated 401.
- Save meter readings twice for the same room/month; the second save should update, not fail.
- Submit a maintenance request with a description of at least 10 characters.
- Confirm a cash invoice paid as admin; the row should update without refresh.
- Create PayOS checkout; if credentials are missing, the app should show a clear configuration error.

## Recovery and break-glass

Vercel and Render release independently. The shared gate is not an atomic cross-platform deployment. API changes must remain backward/forward compatible for at least one release window.

- If Vercel succeeds and Render fails, fix-forward the backend when compatible; otherwise restore the frontend paired with the backend still serving production.
- If Render succeeds and Vercel fails, fix-forward the frontend when compatible; otherwise inspect database compatibility before restoring the backend.
- Record paired frontend/backend SHAs after every release.

Render rollback restores application image/config only. It does not restore PostgreSQL schema. Until versioned migrations exist, schema changes must use expand/contract: add compatible schema, deploy compatible code, then remove old schema in a later release. Inspect schema mutation before any backend rollback because startup migration code can execute `ALTER`, `DROP`, and rename statements before health checks finish.

Only owners/admins may use Vercel Force Promote, Render manual deploy/rollback, or temporary ruleset changes. Record both SHAs, the operator, reason, action, and result, then restore the normal gate.

## Residual verification risk

This change configures and audits the production gates and observes the passing path. Without a separate staging/shadow environment, it does not behaviorally prove that failed, missing, cancelled, or renamed production-equivalent checks remain fail-closed. That negative test and the Render/Vercel status interaction probe are follow-up work; do not claim they ran as part of this rollout.
