# HowsTheRent — Feature Tracker (2026-08-30)

Living tracker for 5 requested features. One task per feature; each gets its
own brainstorm → design → implement cycle. Update this file's status as work
progresses — check items off, add notes on decisions made, link any spec
docs written for the architectural item.

Order chosen by user: **small bounded items first (#1, #3, #4), then the
larger/sensitive ones (#2, #5).**

---

## #1 — DatePicker for date fields (dd/mm/yyyy text → calendar picker)

**Status:** ✅ Done — implemented, tested, verified in a real browser session

**Scope (confirmed via research):** Only 2 fields in the whole frontend are
free-text `dd/mm/yyyy` inputs, both in `ContractsPage.tsx`:
- "Ngày vào" (move-in date) — create contract form
- "Ngày kết thúc mới" (new end date) — inline renew-contract row editor
  (currently a raw `<input>`, not the shared `Input` component — style
  inconsistency to fix while we're in there)

Everywhere else, dates are read-only display (`formatDate()`), not editable.

**Decisions made:**
- Keep dd/mm/yyyy display format (no change to Vietnamese convention)
- Keep manual typing supported (mask via existing `formatDateInput`) +
  add calendar icon to open a popover picker — not calendar-only
- Use `react-day-picker` (new dependency) rather than hand-rolled calendar
- Component stays ISO `yyyy-mm-dd` in/out at the value/onChange boundary —
  no backend/API changes needed

**Plan:**
1. `npm install react-day-picker` in `htr-frontend` ✅
2. New component `htr-frontend/src/components/ui/date-picker.tsx` — wraps
   `Input` (typed path via `formatDateInput`/`parseDateInput`) + icon button
   opening a `react-day-picker` popover (locale vi, week starts Monday),
   both paths converge to ISO output ✅
3. Swapped the two `ContractsPage.tsx` usages to `DatePicker` (also fixed
   the raw-`<input>` style inconsistency on the renew field) ✅
4. Verify ✅:
   - `date-picker.test.tsx` — 8 unit tests (mask-typing, invalid/impossible
     dates don't emit, clearing emits `''`, calendar-click emits ISO and
     closes popover, outside-click closes popover)
   - Full suite: 43/43 passing; `tsc --noEmit` clean; `npm run build` clean
   - Manual browser check via a throwaway Playwright script against a
     locally spun-up full stack (docker postgres/redis/minio + backend +
     frontend dev server, admin login, real Contracts → Create contract
     form): typing `15082026` masks to `15/08/2026` and auto-opens the
     popover on the correct month with that day pre-selected; clicking a
     different day (20) updates the field to `20/08/2026` and closes the
     popover. Screenshots confirmed visual styling matches the app.
   - Note: hit two pre-existing local-env snags unrelated to this feature
     while setting up the manual check — `seed.sql` is stale vs the
     `users` table schema (missing `auth_version`, worked around locally,
     not committed), and the repo-root `.env`'s `CORS_ALLOWED_ORIGINS`
     is scoped to the production Vercel URL only, not `localhost` (worked
     around via an env var override at run time, `.env` untouched). Not
     fixed as part of this task — flagging in case they bite next time
     someone needs a from-scratch local run.
   - Cleaned up afterward: killed backend/frontend processes,
     `docker compose down -v`, `git status` clean (no stray QA changes).

---

## #2 — Handle digital electric/water meter replacement

**Status:** ✅ Done (v1 — "get it working", per user's explicit "code
first, perfect later") — implemented, automated-tested, not yet
manually browser-verified this round

**Key finding from research:** `MeterReading` is one row per room+month;
each period's "old" value is force-copied from the prior period's "new"
value at write time, and the old validation flatly rejected `new < old`
— meaning a meter swap (new meter reading lower than the old one's last
reading) had **no path through the system at all** before this feature.

**Decisions made:**
- Split-segment usage calc (precise, not a manual override number):
  `usage = (oldMeterFinal − oldMeterPrevious) + (newMeterCurrent − newMeterStart)`
- Electric and water replacement are independent flags (2 physically
  separate meters)
- Admin-only, via the existing Meter Readings page (no Maintenance
  workflow tie-in)

**What was built:**
- Backend: `MeterReading` gets 6 new nullable columns (elecReplaced +
  elecOldMeterFinal + elecNewMeterStart, mirrored for water).
  `CreateMeterReadingRequest` carries the same. `MeterReadingService`
  branches validation — replaced periods validate each segment
  independently instead of the old blanket `new >= old` check.
  `BillingService.calcElec/calcWater` branch to the split formula when
  replaced. `MeterReadingResponse` exposes the new fields. 3 new
  `MeterReadingServiceTest` cases (happy path + 2 validation failures),
  2 new `BillingServiceTest` cases (split-calc math for elec and water).
- Frontend: `MeterReadingsPage.tsx` — independent "Đã thay đồng hồ
  điện/nước kỳ này" checkboxes per room card (only shown when a previous
  reading exists to lock against), revealing "chỉ số cũ trước khi tháo" /
  "chỉ số mới lúc lắp" inputs; client-side validation mirrors the
  backend's segment checks; submit payload carries the 6 new fields.
- Verify: 131/131 backend tests, 52/52 frontend tests, `tsc`/build
  clean. **Skipped the manual full-stack browser pass this round** (user
  said get it working now, polish later) — this is the one feature in
  this session's list that touches money/billing math directly, so a
  manual walkthrough (record 2 normal months, replace a meter, generate
  an invoice, check the amount) is recommended before relying on this in
  production, even though the unit-level math is tested.

**Known gaps / follow-up ideas (not done, listed for the "perfect later"
pass):**
- No UI/audit trail showing *why* a given invoice's usage looks unusual
  (e.g. a note referencing the replacement on the invoice detail page)
- No validation preventing `elecReplaced` from being toggled back off
  after fields were filled in (minor UX polish)
- `MeterReadingHistory`/seed-fetch logic in the frontend doesn't surface
  whether a *past* period was a replacement period when computing the
  "kỳ trước" hint text

---

## #3 — Room photos

**Status:** ✅ Done — implemented, tested, verified in a real browser session

**Key finding:** the backend was already half-built — `Room.images`
(`@ElementCollection` → `room_images` table), a generic `StorageService`
(MinIO), and `POST /api/properties/{propertyId}/rooms/{id}/images` all
already existed and worked. The entire gap was frontend (no upload UI, no
gallery component, no `roomApi` methods) plus one missing backend piece
(no delete-single-image endpoint).

**Decisions made:**
- Gallery (multiple photos per room), not single cover photo
- Per-image delete needed → added `DELETE .../rooms/{id}/images`
- Displayed on both `RoomDetailPage` (full gallery) and `RoomsPage` list
  (small thumbnail column, first image = de facto cover, no separate
  "mark as cover" UI)

**What was built:**
- Backend: `RoomController.deleteImage()` — removes the URL from
  `room.images` and calls `storageService.delete()` (already normalizes
  a full URL to an object name, no extra work needed). 2 new unit tests.
- Frontend: `roomApi.uploadImages()` / `roomApi.deleteImage()`; new
  reusable `components/ui/image-gallery.tsx` (grid thumbnails, add via
  hidden file input, hover-to-delete with a confirm `Dialog`, click opens
  full-size in a new tab) — this is the first *extracted* reusable
  version of a pattern that existed as copy-pasted inline JSX in the
  tenant maintenance page; wired into `RoomDetailPage` (new "Hình ảnh
  phòng" card) and `RoomsPage` (new "Ảnh" table column, `ImageOff`
  fallback icon when a room has none). 6 new component unit tests.
- Verify: 49/49 frontend tests, 122/122 backend tests, `tsc`/build clean.
  Manual browser check (real stack, real MinIO) — upload 2 images →
  gallery shows 2 thumbnails, delete 1 → 1 remains with no page reload
  needed, Rooms list thumbnail column updates in sync. Cleaned up after
  (killed processes, `docker compose down -v`, git status clean).
- **Second environment snag found and worked around (not fixed)**: the
  same root `.env` also overrides `MINIO_URL`/`MINIO_PUBLIC_URL` etc. to
  a Cloudflare R2 endpoint with literal `<placeholder>` values — local
  uploads fail with "No such host is known" unless overridden via env
  vars at run time. Also, a fresh local MinIO bucket has no public-read
  policy by default (production R2 presumably does), so uploaded images
  404/403 in the browser until `mc anonymous set download` is run once
  locally — not an app bug, just a one-time local setup step nobody has
  documented yet.

---

## #4 — Room direction note (feng shui: đông/tây/nam/bắc)

**Status:** ✅ Done — implemented, tested, verified in a real browser session

**Decisions made:**
- Fixed 8-direction enum (not free text)
- Optional field, not required on existing/new rooms
- Displayed in both `RoomsPage` list (new column) and `RoomDetailPage`

**What was built:**
- Backend: `RoomDirection` enum, `Room.direction` (nullable), threaded
  through `CreateRoomRequest` → `RoomService.create/update` →
  `RoomResponse`. 2 new `RoomResponseTest` cases (mapped / null).
- Frontend: `RoomDirection` type, `directionLabel()` in `lib/utils.ts` (8
  Vietnamese labels + em-dash fallback), dropdown in the Rooms
  create/edit form, new "Hướng" table column, display row on
  `RoomDetailPage`. 3 new `utils.test.ts` cases.
- Verify: 52/52 frontend tests, 124/124 backend tests, `tsc`/build clean.
  Manual browser check — set direction to "Đông Nam" via the edit form,
  confirmed it shows in both the Rooms list column and the Room Detail
  page, no console errors. Cleaned up after (docker down -v, processes
  killed, git status clean).

**Follow-up (same session):** user clarified they also want a freeform
description field (e.g. "Phòng sạch, mới, nội thất đầy đủ... hướng tây
bắc") alongside — not instead of — the structured direction dropdown.
Added `Room.description` (TEXT, optional), threaded through the same
DTOs/service, textarea in the Rooms form, truncated-with-tooltip column
in the Rooms list, full prose block on RoomDetailPage. 4 backend unit
tests. Skipped a fresh manual-browser pass this time (4th full-stack
spin-up in one session) — relied on `tsc`/build/52+126 automated tests,
since it reuses the exact wiring already verified for direction.

---

## #5 — Blog feature (one post per rental property)

**Status:** ⬜ Not started — needs brainstorm/interview (architectural —
will get its own full spec doc under `docs/superpowers/specs/`)

**Scope note:** User wants this developed "trên 1 nhánh" (on a separate
branch) — likely wants git branch isolation (possibly a worktree) given
it's a new subsystem (public-facing blog/content pages) rather than a
tweak to existing admin/tenant/technician flows.

**Open questions for interview:**
- Is this public-facing (no login, SEO-friendly) or still behind
  auth/admin like the rest of the app?
- Who authors posts — Admin only, or per-property owner?
- Content model: fully custom rich-text/markdown editor, or
  template-generated from existing property/room data (address, photos
  from #3, direction notes from #4, etc.) with an editable description?
- New frontend routes only, or does this need new backend
  entities/endpoints (Post, slug, published/draft state)?
- Relationship to existing `Property` entity — one blog post per
  `Property`, editable 1:1, or can a property have multiple posts?

---

## Update log

- 2026-08-30: File created. User approved #1 design, chose order
  (#1, #3, #4 → #2, #5). Starting #1 implementation next.
- 2026-08-30: #1 (DatePicker) implemented, tested, and manually verified
  in a real browser against a real backend. Moving to #3 (room photos)
  next.
- 2026-08-30: #3 (room photos) implemented, tested, and manually
  verified. Backend storage/upload already existed half-built; added the
  missing delete endpoint + all frontend UI. Moving to #4 (room
  direction note) next.
- 2026-08-30: Found the repo-root `.env` is a production-config template
  with unfilled `<placeholder>` values for both `CORS_ALLOWED_ORIGINS`
  and the MinIO/R2 vars, and it silently overrides local dev defaults
  via `spring.config.import`. Worth the user's attention independent of
  this feature work — it will trip up the next from-scratch local run.
- 2026-08-30: #4 (room direction) implemented, tested, and manually
  verified. User asked to commit after finishing each task going
  forward — committing #1, #3, #4 now as separate commits (catching up),
  then moving to #2 (meter reading) next.
- 2026-08-30: #2 (meter replacement) implemented and automated-tested;
  user explicitly asked to code the feature first and perfect it later,
  so the manual browser walkthrough was skipped this round — flagged as
  the top follow-up item since it's the one feature touching billing
  math directly. Committing now. All 5 original items have a first pass
  done except #5 (blog), which is next.
