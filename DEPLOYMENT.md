# Deployment Guide

This project can be deployed on free tiers with:

- Frontend: Vercel
- Backend: Render Web Service
- Database: Neon Postgres or Supabase Postgres

The app uses HttpOnly cookie authentication. To avoid cross-site cookie problems, deploy the frontend on Vercel and let Vercel proxy `/api/*` to the Render backend.

## 1. Database

Create a PostgreSQL database on Neon or Supabase and copy the connection details.

Render backend env vars:

```env
DB_URL=jdbc:postgresql://<host>/<database>?sslmode=require
DB_USER=<username>
DB_PASSWORD=<password>
```

The backend currently uses `spring.jpa.hibernate.ddl-auto=update`, so Hibernate will create/update tables automatically for this demo deployment.

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

## 5. Smoke checks after deploy

- Open `https://<render-service>.onrender.com/api/health` and verify `{ "status": "ok" }`.
- Open the Vercel app.
- Login and navigate between pages; there should be no repeated 401.
- Save meter readings twice for the same room/month; the second save should update, not fail.
- Submit a maintenance request with a description of at least 10 characters.
- Confirm a cash invoice paid as admin; the row should update without refresh.
- Create PayOS checkout; if credentials are missing, the app should show a clear configuration error.
