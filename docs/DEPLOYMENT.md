# Deployment Guide — Property Management System

## Prerequisites

- Docker & Docker Compose
- JDK 21 (for local development without Docker)
- Node.js 20+ (for frontend development without Docker)
- Bun (optional, for faster frontend builds)

---

## Local Development

### 1. Clone & Configure

```bash
cp .env.example .env
# Edit .env with your values (especially JWT_SECRET and PayOS credentials)
```

### 2. Start all services

```bash
docker compose up -d
```

### 3. Verify services

| Service | URL | Default credentials |
|---------|-----|-------------------|
| Backend API | http://localhost:8080 | — |
| Frontend | http://localhost:5173 | — |
| MinIO Console | http://localhost:9001 | minioadmin / minioadmin |
| PostgreSQL | localhost:5432 | propms / secret |

### 4. Create admin user

The backend seeds no users by default. Use the `/api/users` POST endpoint (requires direct DB access or an existing admin token):

```bash
# Via backend health check or curl to an existing admin
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <admin_token>" \
  -d '{
    "fullName": "Admin User",
    "email": "admin@example.com",
    "phone": "0909123456",
    "password": "Admin123!",
    "role": "ADMIN"
  }'
```

---

## PayOS Setup

1. Register at https://payos.vn
2. Create a webhook endpoint: `https://your-domain/api/payment/callback`
3. Note your Client ID, API Key, and Checksum Key
4. Add to `.env`:
   ```
   PAYOS_CLIENT_ID=your_id
   PAYOS_API_KEY=your_key
   PAYOS_CHECKSUM_KEY=your_checksum
   ```

---

## Email (SMTP)

Supports any SMTP provider. For Gmail:
1. Enable 2FA on your Google account
2. Create an App Password: https://myaccount.google.com/apppasswords
3. Set `MAIL_USERNAME` and `MAIL_PASSWORD` in `.env`

---

## MinIO Setup

MinIO is used for file storage (contract uploads, room images).

1. Access the MinIO console at http://localhost:9001
2. Login with `minioadmin` / `minioadmin`
3. Create a bucket named `propms` (or match `MINIO_BUCKET` env var)

For production, replace the default credentials with strong values.

---

## Production Deployment

### Provider-agnostic checklist

1. **Database**: PostgreSQL 16 (Railway, Supabase, Render, VPS)
2. **Cache**: Redis 7 (Railway, Redis Cloud, VPS)
3. **Storage**: MinIO S3-compatible (self-hosted, or AWS S3 / Cloudflare R2)
4. **Domain**: Configure DNS A record pointing to your server
5. **SSL**: Use a reverse proxy (nginx, Caddy) with Let's Encrypt

### Environment variables (production)

All variables in `.env.example` are required. Key differences from local:

```
DB_URL=jdbc:postgresql://<host>:5432/propms
REDIS_HOST=<redis-host>
REDIS_PORT=6379
MINIO_URL=https://<minio-host>:9000
SERVER_PORT=8080
# Change JWT_SECRET to a strong random value
```

### Docker Compose (production)

For production, add restart policies and resource limits:

```yaml
services:
  backend:
    restart: always
    deploy:
      resources:
        limits:
          memory: 512M

  frontend:
    restart: always
    deploy:
      resources:
        limits:
          memory: 128M
```

### Reverse Proxy (nginx)

```nginx
server {
    listen 443 ssl;
    server_name yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://localhost:5173;
    }

    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### PayOS webhook URL

Update your PayOS webhook to point to your production domain:
```
https://yourdomain.com/api/payment/callback
```

### Database migrations

For production, use proper migrations instead of `jpa.hibernate.ddl-auto=update`:

```bash
# Install Flyway (recommended)
# Place migration scripts in src/main/resources/db/migration/
spring.flyway.enabled=true
spring.flyway.locations=classpath:db/migration
```

---

## Architecture

```
Browser
  └── Frontend (React, port 5173/80)
        └── /api/* → Backend (Spring Boot, port 8080)
              ├── PostgreSQL (port 5432)  — primary data
              ├── Redis (port 6379)        — session/cache
              ├── MinIO (port 9000)        — file storage
              └── PayOS API               — payment gateway
```
