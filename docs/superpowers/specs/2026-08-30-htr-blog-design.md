# HowsTheRent — Property Blog (design spec)

Status: approved by user, ready for implementation planning
Related: `docs/superpowers/plans/2026-08-30-htr-feature-tracker.md` (#5)

## 1. Goal

Each rental property gets one public blog post — marketing/SEO content to
attract new tenants, an internal portfolio the owner can show off, and a
live view of which rooms in that property are currently vacant. Visitors
can comment and like a post, but must be logged in (as a new `GUEST`
role) to do either.

This stays inside the existing HowsTheRent app — same React/Vite
frontend, same Spring Boot backend, same PostgreSQL database, same JWT
auth system. It is **not** a separate site, deployment, or database. The
"full website" framing from the initial ask means the blog should behave
like a complete public site (listing, individual posts, auth, comments,
likes) — not that it needs separate infrastructure.

## 2. Non-goals for v1 (explicitly deferred)

- Google/social OAuth login (v1 is email/password only, reusing the
  existing login form)
- Comment moderation queue (comments post live immediately; admin can
  delete after the fact via a small moderation view)
- Threaded/nested comment replies (flat list only)
- Server-side rendering or prerendering for SEO (v1 relies on
  client-rendered meta tags + a sitemap; revisit only if organic search
  traffic actually becomes a bottleneck)
- Per-owner (`LANDLORD_ADMIN`) authorship scoping — every post is
  managed by whichever `ADMIN`/`PLATFORM_ADMIN` account edits it, no
  per-property ownership check on the blog admin screens
- Multiple posts per property, or post history/versioning — one post
  per property, edited in place

## 3. Data model

Three new tables (no `Meter`/`Post`-adjacent entity exists today to
build on — this is fully new). Following this repo's established
convention (see `Room.direction`/`Room.description`, added without a
Flyway migration), these rely on `spring.jpa.hibernate.ddl-auto=update`
rather than a new `V4__*.sql` migration, matching how every other
additive nullable-column change in this codebase has shipped.

### `Post`
One row per `Property`, 1:1.

| Column | Type | Notes |
|---|---|---|
| `id` | UUID | PK |
| `property_id` | UUID FK, unique | 1:1 with `Property` |
| `title` | text, not null | |
| `slug` | text, unique, not null | URL segment, generated from title on first publish, editable |
| `content` | TEXT | rich-text HTML from the WYSIWYG editor |
| `cover_image_url` | text, nullable | defaults to the property's first room image if unset |
| `published` | boolean, default false | draft vs live |
| `published_at` | timestamp, nullable | set on first publish |
| `author_id` | UUID FK → User | last admin to save |
| `created_at` / `updated_at` | timestamp | |

### `PostComment`
| Column | Type | Notes |
|---|---|---|
| `id` | UUID | PK |
| `post_id` | UUID FK | |
| `user_id` | UUID FK → User | must be authenticated (GUEST or any role) |
| `content` | text, not null | |
| `created_at` | timestamp | |

### `PostLike`
| Column | Type | Notes |
|---|---|---|
| `id` | UUID | PK |
| `post_id` | UUID FK | |
| `user_id` | UUID FK → User | |
| `created_at` | timestamp | |
| unique `(post_id, user_id)` | | prevents double-likes; a like is a toggle (create/delete) |

**Vacancy data is intentionally not stored on `Post`.** The "phòng còn
trống" section of a post page is rendered from a live API call
(`GET /api/public/properties/{id}/vacancy`) every time the page loads,
so it can never drift out of sync with the real `Room.status` data the
way a copy-pasted number in `content` eventually would.

## 4. Backend

### 4.1 New role: `GUEST`

Added to `UserRole` alongside `ADMIN, PLATFORM_ADMIN, LANDLORD_ADMIN,
TENANT, TECHNICIAN`. A `GUEST` account is created via a new public
self-registration endpoint (see below) — the first role in this system
that isn't admin-provisioned.

**Security model — and a gap this feature must close.** This repo
authorizes per-endpoint via `@PreAuthorize`, not at a router/gateway
level; `SecurityConfig`'s catch-all is `.anyRequest().authenticated()`.
Most endpoints already carry an explicit `@PreAuthorize(hasAnyRole(...))`
that simply won't list `GUEST`, so they're safe by construction. But a
research pass found several endpoints with **no `@PreAuthorize` at
all**, relying only on the blanket "any authenticated user" rule:
`GET /api/properties/{id}`, `GET /api/contracts/{id}`,
`GET /api/invoices/{id}`, the maintenance notes/materials/reviews/
sla-rules endpoints, all of `NotificationController`, and
`GET /api/users/me`. Introducing `GUEST` as a real login-capable role
means these would newly become reachable by a public visitor unless
patched. **Closing this gap (adding explicit `@PreAuthorize` that
excludes `GUEST`) is part of this feature, not a follow-up.**
`POST /api/users/me/change-password` is the one exception — deliberately
left open to `GUEST` too, since it's safe (requires the current
password) and lets guests reuse the existing change-password flow.

To minimize new surface area, the **read side of the blog itself is
fully public** (`permitAll()`, no login required to browse posts or see
vacancy) — only comment and like require `GUEST` (or any authenticated
role).

### 4.2 New endpoints

Public (`permitAll()`):
- `GET /api/public/blog/posts` — list published posts (title, slug,
  cover image, property name/address, vacancy summary)
- `GET /api/public/blog/posts/{slug}` — single post
- `GET /api/public/blog/posts/{slug}/comments` — flat list
- `GET /api/public/properties/{id}/vacancy` — `{ emptyCount, rentedCount,
  totalCount }`, built from the existing
  `RoomRepository.countByPropertyIdAndStatus` (already used by
  `DashboardController` for the same aggregation, just not exposed
  publicly per-property yet)
- `GET /sitemap.xml` — enumerates published post URLs
- `POST /api/auth/register-guest` — creates a `User` with `role=GUEST`;
  no email verification in v1 (OTP infra today is forgot-password only)

Authenticated, any role (comment/like are allowed from any logged-in
user, not just GUEST — an admin should be able to comment too):
- `POST /api/public/blog/posts/{slug}/comments`
- `POST /api/public/blog/posts/{slug}/like` / `DELETE .../like` (toggle)

Admin-only (`hasAnyRole('ADMIN','PLATFORM_ADMIN')`):
- `GET /api/admin/blog/posts` — all posts (draft + published) with
  status
- `GET/PUT /api/admin/blog/posts/{propertyId}` — read/edit a property's
  post (creates it on first PUT if it doesn't exist yet)
- `POST /api/admin/blog/posts/{propertyId}/draft` — generates a starter
  `content` HTML block from the property/room data (address, room
  photos from #3, direction + description from #4, current vacancy) for
  the admin to edit — a one-shot template fill, not a live binding
- `POST /api/admin/blog/posts/{propertyId}/publish` /
  `.../unpublish`
- `DELETE /api/admin/blog/comments/{id}` — moderation cleanup

## 5. Frontend

### 5.1 Public routes (new, unauthenticated section of `App.tsx`)

- `/blog` — listing: cards with cover image, property name/address,
  vacancy badge ("2 phòng trống" / "Hết phòng")
- `/blog/:slug` — post detail: rendered `content` HTML, live vacancy
  widget, comment list + form (form replaced by a "Đăng nhập để bình
  luận" prompt when logged out), like button (same login-gate pattern)
- `/blog/register` — new lightweight GUEST signup form
- Reused unmodified: `/login`, `/forgot-password`, `/reset-password`
  (already generic, no role assumptions per the research pass)

No dedicated public layout component exists today —
`LandingPage.tsx` builds its own nav/footer chrome inline with CSS
tokens rather than importing a shared shell. Given the blog is the
second public-facing surface, this feature extracts that into a small
shared `PublicShell` (nav + footer) used by both `LandingPage` and the
new blog pages, instead of copy-pasting the chrome a second time.

### 5.2 Auth integration fixes (small, required)

Two places currently compute a post-login redirect path from role and
fall through to `/tech` for anything unrecognized — both need an
explicit `GUEST → /blog` branch:
- `App.tsx`'s authenticated-branch `homePath` calculation
- `LoginPage.tsx`'s post-login `navigate(...)` call

### 5.3 Admin routes (added to the existing `adminRoutes.tsx`, gated
`['ADMIN','PLATFORM_ADMIN']` matching the existing narrower
`PLATFORM_ADMIN` route group used for admin-only-of-admin-only pages)

- `/admin/blog` — list of properties with post status (draft/published/
  none yet), edit link
- `/admin/blog/:propertyId` — WYSIWYG editor (new dependency, e.g. a
  lightweight React rich-text editor), "Tạo bản nháp tự động" button,
  publish/unpublish toggle, "Xem trước" link to the live `/blog/:slug`
- `/admin/blog/comments` — flat moderation list with delete

## 6. SEO (v1)

- Per-post `document.title` and `<meta name="description">` set
  dynamically (a small reusable hook — no need for a full library like
  react-helmet for two tags)
- `GET /sitemap.xml` served by the backend, listing all published post
  URLs
- `robots.txt` allowing `/blog` and `/blog/*`

No SSR/prerendering in v1 — flagged as the natural place to invest if
organic search performance matters more than expected once this ships.

## 7. Risks / open follow-ups (not blocking v1)

- OTP-based email verification for GUEST signup — today's OTP store is
  forgot-password-only and in-memory (not persisted/clustered); fine at
  current scale but worth knowing before assuming it'd generalize
  cleanly to a signup-verification flow later
- Comment spam — no moderation queue in v1, only after-the-fact delete;
  worth a rate-limit or CAPTCHA if abuse shows up in practice
- The WYSIWYG library choice is left open for the implementation plan to
  decide (no rich-text editor exists anywhere in this codebase yet, so
  there's no existing pattern to match)

## 7.1. Mandatory implementation rules (from this repo's 401-incident history — see `CLAUDE.md` / README's "Troubleshooting: API trả về 401")

This app has a documented history of 401 bugs that all trace back to two
repeated architectural mistakes. This feature adds a new role (first
ever self-registered/public one) and three new entities with relations
— exactly the shape of change that has caused both mistakes before.
These rules are not optional polish, they're how this feature avoids
becoming incident #4 and #5 in that history:

1. **Do not introduce any new or renamed auth cookie for `GUEST`.**
   Reuse the existing `accessToken`/`refreshToken` cookies, same names,
   same `/` path, same `JwtAuthFilter` flow — a `GUEST` login is just
   another row in the same `users` table with a different `role` claim.
   Three past incidents were all "we changed the cookie identity and
   didn't fully retire the old one" in different disguises; this feature
   must not create a fourth variant.
2. **Every new entity (`Post`, `PostComment`, `PostLike`) that gets
   mapped to a response DTO must either be built inside a
   `@Transactional(readOnly = true)` service method, or have
   `@EntityGraph` on the repository method that fetches it** — in
   particular `Post.property` (and through it `property.images`/
   `property.rooms` if the auto-draft generator touches them),
   `PostComment.user`, and any listing endpoint that returns multiple
   posts/comments with their relations. This project runs
   `spring.jpa.open-in-view=false`; three past bugs were exactly this
   mistake (`cf67604`, `608b465`, `8c7858b`), and it's now the
   established pattern to follow proactively rather than hit and patch.
3. **§4.1's `@PreAuthorize` hardening pass on the currently-unannotated
   endpoints is required before `GUEST` can log in**, not a nice-to-have
   — see the earlier conversation in this session for why (this repo's
   RBAC is entirely per-endpoint `@PreAuthorize`, there is no
   gateway-level role gate; endpoints without their own annotation only
   check "is anyone logged in", which was safe when every role was
   admin-provisioned and stops being safe once `GUEST` is
   self-registerable).
4. Local manual verification of the auth/comment/like flow should follow
   the recipe in `CLAUDE.md`'s "Manual full-stack verification recipe"
   section (env var overrides for `.env`'s CORS/MinIO placeholders, the
   `seed.sql` auth_version fix, the admin password reset trick) rather
   than rediscovering those from scratch.

## 8. Rollout

Additive only: new tables, new role, new endpoints, new routes — nothing
existing changes shape except the two redirect-fallback fixes (§5.2)
and the `@PreAuthorize` hardening pass (§4.1), both of which are
"tighten a gap that already existed" rather than behavior changes for
current roles.
