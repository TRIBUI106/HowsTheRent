# HowsTheRent — notes for AI sessions working in this repo

Read this before starting work. It captures things that otherwise get
re-discovered (or re-asked) every session.

## Stack

React 19 + TS + Vite (`htr-frontend/`) · Spring Boot 4 + Java 21 +
PostgreSQL + Redis + MinIO (`htr-backend/`). See root `README.md` for
the full role/flow overview.

## Local dev environment gotchas (cost real time to discover — don't re-discover)

1. **The repo-root `.env` is a production-config template, not a local
   dev file.** It has literal `<placeholder>` values and silently
   overrides local defaults via `spring.config.import=optional:file:../.env[.properties]`
   in `htr-backend/src/main/resources/application.properties`:
   - `CORS_ALLOWED_ORIGINS` points only at a production Vercel URL, not
     `localhost` — the browser will get `Invalid CORS request` on login
     unless overridden.
   - `MINIO_URL`/`MINIO_PUBLIC_URL`/`MINIO_ACCESS_KEY`/`MINIO_SECRET_KEY`/
     `MINIO_AUTO_CREATE_BUCKET` point at a Cloudflare R2 endpoint with
     unfilled placeholders — any image upload fails with "No such host
     is known" unless overridden.

   **Fix**: when running the backend locally from scratch, pass these as
   env vars (they take precedence over the imported `.env` file):
   ```bash
   CORS_ALLOWED_ORIGINS="http://localhost:5173,http://localhost:3000" \
   MINIO_URL="http://localhost:9000" MINIO_PUBLIC_URL="http://localhost:9000/htr" \
   MINIO_ACCESS_KEY="minioadmin" MINIO_SECRET_KEY="minioadmin" MINIO_AUTO_CREATE_BUCKET="true" \
   ./mvnw spring-boot:run
   ```

2. **`seed.sql` is stale vs. the current `users` table schema** — it
   omits `auth_version`, which is `NOT NULL` with no default, so a plain
   `psql -f seed.sql` fails on every user insert. Fix locally (never
   commit this — it's a workaround, not a schema fix):
   ```sql
   ALTER TABLE users ALTER COLUMN auth_version SET DEFAULT 0;
   ```
   then re-run `seed.sql`.

3. **`seed.sql`'s admin password hash has no known plaintext.** To get a
   working local admin login, reset the hash after seeding:
   ```bash
   # generate a bcrypt hash without installing anything locally:
   docker run --rm httpd:alpine htpasswd -nbBC 10 admin 'Test1234!'
   # then, using the hash it prints:
   docker exec -i htr-postgres psql -U htr -d htr -c \
     "UPDATE users SET password_hash = '<hash>' WHERE email = 'admin@example.com';"
   # login with admin@example.com / Test1234!
   ```

4. **A fresh local MinIO bucket has no public-read policy**, so uploaded
   image URLs 404/403 in the browser (production R2 presumably has one
   configured). Fix once per fresh MinIO volume:
   ```bash
   docker run --rm --network htr-stack_default --entrypoint sh minio/mc:latest -c \
     "mc alias set local http://htr-minio:9000 minioadmin minioadmin && mc anonymous set download local/htr"
   ```

5. **`docker-compose.yml`'s `backend` service is commented out** — run
   the backend with `./mvnw spring-boot:run` (with the env var overrides
   above), not `docker compose up`. `docker compose up -d postgres redis
   minio` covers the rest.

## Recurring 401 root causes — read before touching auth or adding a lazy JPA relation

See `README.md`'s "Troubleshooting: API trả về 401" section for the full
write-up. Two rules that prevent re-litigating past incidents:

- **Never rename/re-scope the `accessToken`/`refreshToken` cookies**
  without also adding a legacy-cookie fallback read *and* an explicit
  clear-at-all-old-paths step on login/logout — three past incidents
  (`localStorage`→cookie, `AccessToken`→`accessToken`, path
  `/api/maintenance`→`/`) were all this same mistake in a new form.
- **Always build response DTOs for lazy-loaded relations inside
  `@Transactional(readOnly = true)`, or add `@EntityGraph` to the
  repository method** — the project runs `spring.jpa.open-in-view=false`,
  so anything touching a `FetchType.LAZY` field after the service method
  returns throws `LazyInitializationException`. This is now caught by
  `GlobalExceptionHandler` (surfaces as 500, not a confusing 401), but
  the underlying gap isn't closed project-wide — only ~7 of 15
  lazy-relation entities have `@EntityGraph` coverage today.

## Established conventions (follow, don't reinvent)

- **All new mutations use `useGuardedMutation`** (`hooks/useGuardedMutation.ts`),
  not raw `useMutation` — it blocks writes while offline, matching the
  rest of the app's offline-guard pattern.
- **Vietnamese enum→label maps** live in `lib/utils.ts` (see
  `statusLabel`, `categoryLabel`, `directionLabel`) — a plain
  `Record<string,string>` with a sensible fallback, not a switch.
- **Confirm-before-destructive-action** uses the shared `Dialog`
  component (`components/ui/dialog.tsx`), not `window.confirm`.
- **Reusable UI components live in `components/ui/`** — `DatePicker`
  (dd/mm/yyyy mask + calendar popover, emits ISO) and `ImageGallery`
  (upload/delete grid with confirm) both exist now; reach for them
  before building a new date input or photo grid from scratch.
- Styling: Tailwind v4 with the `cn()` helper (`clsx` + `tailwind-merge`)
  from `lib/utils.ts`; match existing `border-border`/`bg-surface`/
  `text-fg`/`accent` token classes rather than hardcoding colors.

## Manual full-stack verification recipe (used repeatedly this session)

For features that need a real browser/backend/DB check (not just unit
tests), this sequence works and leaves no residue:

```bash
docker compose up -d postgres redis minio          # wait for healthy
# start backend with the env var overrides from "Local dev environment gotchas" #1
# apply gotchas #2 and #3 (seed + password reset), #4 if the feature touches images
cd htr-frontend && npm run dev                      # port 5173
# drive it with Playwright (see any recent session transcript for the pattern —
# npx playwright install chromium if not cached; chromium-cli is not available here)
```

**Always tear down after**: kill the backend/frontend processes, `docker
compose down -v` (the `-v` matters — otherwise the next fresh run
inherits this session's seed data and the auth_version/password
workarounds), and confirm `git status --short` is clean before
committing.

## Where things are tracked

- `docs/superpowers/plans/2026-08-30-htr-feature-tracker.md` — status of
  the 5 originally-requested features (DatePicker, meter replacement,
  room photos, room direction, blog).
- `docs/superpowers/specs/2026-08-30-htr-blog-design.md` — full design
  spec for the property blog feature (#5), approved and ready for an
  implementation plan.
