# Consensus Plan: Property Management System

## Source
- Spec: `.omc/specs/deep-interview-property-management-system.md`
- Product plan: `master-plan.md`
- Backend skeleton: `htr-backend/src/main/java/chez1s/htrbackend/HtrBackendApplication.java`
- Backend config: `htr-backend/src/main/resources/application.properties`
- Maven project: `htr-backend/pom.xml`

## Requirements Summary
Build the complete property/boarding-house management system described in `master-plan.md` with real PayOS, SMTP/email, and MinIO integration targets; polished responsive UI for admin, tenant, and technician; local Docker Compose runtime; and portable production deployment documentation. Keep the backend root package `chez1s.htrbackend`. Create a new React + TypeScript frontend because none exists.

## RALPLAN-DR Summary

### Principles
1. Preserve the current backend package root while expanding structure cleanly under `chez1s.htrbackend`.
2. Implement domain and billing correctness before UI polish, but do not ship without polished role-based flows.
3. Treat external integrations as real production boundaries: PayOS signature verification, SMTP configuration, MinIO object storage, and environment-based secrets.
4. Keep the system runnable locally through Docker Compose and portable for production without provider lock-in.
5. Verify money/payment behavior with automated tests before relying on manual E2E demos.

### Decision Drivers
1. Full-scope delivery with all E2E flows, not an MVP subset.
2. Security-sensitive integrations: JWT auth, PayOS webhook HMAC, credentials, file upload/storage.
3. Brownfield-light context: minimal backend skeleton, no frontend, no existing schema.

### Viable Options

#### Option A — Vertical-slice delivery by user journey (favored)
**Approach:** Build foundation, then implement E2E slices: auth/property-room, contract-billing-payment, maintenance-notification-dashboard, then polish/deploy.

**Pros:**
- Produces testable E2E value after each slice.
- Reduces risk of building large disconnected layers.
- Fits all required acceptance flows.

**Cons:**
- Requires careful shared model/API coordination early.
- Some frontend polish waits until backend contracts stabilize.

#### Option B — Backend-complete first, frontend second
**Approach:** Finish all backend domain/API/integration work first, then build the full frontend.

**Pros:**
- Strong backend/API foundation before UI work.
- Easier to automate service-level tests early.

**Cons:**
- Delays UI feedback and role-flow validation.
- Higher risk of API shapes not fitting frontend needs.
- Conflicts with “polished all” because UI risks surface late.

#### Option C — Monolithic all-at-once scaffolding
**Approach:** Generate all entities, APIs, pages, Docker, and integrations broadly, then fill details.

**Pros:**
- Fast initial visible coverage.
- Mirrors `master-plan.md` structure directly.

**Cons:**
- Highest risk of shallow/incomplete behavior.
- Payment/billing bugs may hide behind broad scaffolding.
- Harder to verify incrementally.

### Favored Option
Option A: vertical-slice delivery by user journey.

## ADR

### Decision
Use vertical-slice delivery over a layered backend-first or all-at-once scaffold. Keep backend package `chez1s.htrbackend`, create a new `frontend` Vite React app, and implement infrastructure through Docker Compose plus provider-neutral production documentation.

### Drivers
- Full product scope with all E2E flows.
- Real external integrations and security-sensitive payment webhook behavior.
- Need for polished UI across roles.
- Existing repo has only minimal backend skeleton.

### Alternatives Considered
- Backend-complete first: rejected because UI and E2E validation would arrive too late.
- Monolithic all-at-once scaffolding: rejected because it encourages shallow coverage and weak verification.

### Why Chosen
Vertical slices let each role journey become demonstrable and testable while still converging on the full plan. This is safer for billing/payment correctness and better for frontend/backend contract feedback.

### Consequences
- Requires stable DTO/API conventions early.
- Some shared foundations must be built before first slice.
- More frequent verification checkpoints are needed.

### Follow-ups
- Collect PayOS, SMTP, and MinIO credentials outside the repo before real integration testing.
- Decide final production hosting provider later; keep deployment docs portable now.
- Add git commits/checkpoints once the user requests commits.

## Implementation Plan

### Phase 0 — Repository and project foundation
1. Keep root layout:
   - `htr-backend/` for Spring Boot.
   - `frontend/` for React + Vite.
   - `docker-compose.yml` at repo root.
   - `.env.example` at repo root.
2. Update `htr-backend/pom.xml` with needed dependencies:
   - Spring Web, Spring Data JPA, PostgreSQL driver, Validation, Security, OAuth/JWT or jjwt, Mail, Thymeleaf, Quartz, Redis, MinIO SDK, PayOS SDK if available, Lombok, Testcontainers where practical.
3. Expand backend package under `htr-backend/src/main/java/chez1s/htrbackend/`:
   - `config/`, `domain/entity/`, `domain/enums/`, `domain/repository/`, `dto/request/`, `dto/response/`, `service/`, `controller/`, `scheduler/`, `payment/`, `security/`, `exception/`.
4. Configure profiles in `htr-backend/src/main/resources/application.properties` or YAML:
   - datasource, Redis, JWT, PayOS, MinIO, mail, Quartz.
5. Create `frontend/` with Vite React TypeScript, Tailwind, shadcn/ui-compatible structure, React Router, TanStack Query, Axios, Zustand.

### Phase 1 — Domain model, persistence, and validation
1. Implement enums from `master-plan.md`:
   - `PropertyType`, `RoomStatus`, `ContractStatus`, `InvoiceStatus`, `WaterMode`, `VehicleType`, `MaintenanceStatus`, `PaymentMethod`, user role enum.
2. Implement JPA entities:
   - User, Property, FeeConfig, VehicleConfig, Room, Contract, MeterReading, VehicleRecord, Invoice, MaintenanceRequest, Notification.
3. Implement repositories with uniqueness/idempotency helpers:
   - invoice exists by room/contract and invoice month.
   - active contracts by status.
   - readings by room/month.
4. Add database migrations if a migration tool is introduced; otherwise rely on JPA dev schema only for local and document production migration limitations.
5. Add DTOs and validation annotations at API boundaries.

### Phase 2 — Auth and role-based shell
1. Backend:
   - JWT login/refresh/logout endpoints from `master-plan.md`.
   - Spring Security config with public `/api/auth/**`, PayOS callback public, role-protected APIs.
   - Password hashing.
   - Current-user lookup service.
2. Frontend:
   - Login page.
   - Auth store.
   - Axios client with token handling.
   - Role-based routing/layouts for Admin, Tenant, Technician.
3. Seed/admin bootstrap:
   - Provide a safe dev seed path or documented first-admin setup.

### Phase 3 — Property, room, fee, vehicle management slice
1. Backend controllers/services:
   - `/api/properties`, property details/update.
   - fee config and vehicle config endpoints.
   - room CRUD/list/detail/status endpoints.
2. Frontend admin pages:
   - Property list/detail/form.
   - Room list/detail/form with status badge and image upload through MinIO-backed storage API.
   - Fee/vehicle config forms.
3. Verification:
   - Admin can create property, configure fees/vehicles, create room, upload images.

### Phase 4 — Contracts, readings, and billing slice
1. Backend:
   - Contract API and termination endpoint.
   - Meter reading API.
   - Vehicle record API.
   - BillingService methods from `master-plan.md`: rent, electricity, water, vehicle, service, pro-rata with BigDecimal and HALF_UP.
   - Invoice creation service with duplicate prevention.
2. Frontend:
   - Contract management forms.
   - Meter reading page.
   - Invoice list/detail pages.
3. Tests:
   - Unit tests for billing formulas.
   - Pro-rata first-month test.
   - CUBIC vs PERSON water mode tests.
   - Duplicate invoice idempotency tests.

### Phase 5 — PayOS, email, scheduler, and payment flow
1. Backend:
   - PayOS client/config.
   - Payment link generation when invoice is created.
   - Enforce PayOS description <= 25 chars and no Vietnamese accents.
   - Public `/api/payment/callback` endpoint with mandatory HMAC verification before state mutation.
   - Invoice PAID update with transaction ID and paid timestamp.
   - Admin cash mark-paid endpoint.
   - JavaMailSender + Thymeleaf email templates.
   - Quartz `BillingJob` and `OverdueReminderJob` with idempotency.
2. Frontend:
   - Tenant invoice list/detail.
   - Payment link redirect/open flow.
   - Admin invoice management and cash payment action.
3. Tests:
   - PayOS signature verification reject/accept tests.
   - Payment success updates invoice exactly once.
   - Scheduler idempotency test.

### Phase 6 — Maintenance, notifications, dashboards
1. Backend:
   - Maintenance request create/list/my/assign/resolve APIs.
   - Notification list/read/read-all APIs.
   - Admin and tenant dashboard APIs.
2. Frontend:
   - Tenant maintenance page with image upload.
   - Admin maintenance assignment page.
   - Technician work queue and resolve flow.
   - Notification bell and notification pages/states.
   - Admin dashboard charts/cards.
   - Tenant dashboard summary.
3. Verification:
   - Tenant creates request, admin assigns, technician resolves, notifications update.

### Phase 7 — Polish, Docker, production docs, final QA
1. UI polish:
   - Responsive layouts.
   - Loading/error/empty states.
   - Form validation messages.
   - Consistent badges/status colors.
2. Docker:
   - Root `docker-compose.yml` for Postgres, Redis, MinIO, backend, frontend.
   - Backend Dockerfile.
   - Frontend Dockerfile/Nginx or static serving.
   - `.env.example` for all required variables.
3. Production docs:
   - Provider-neutral deployment guide.
   - Required env vars and secret handling.
   - PayOS webhook URL configuration.
   - SMTP and MinIO setup.
4. Final verification:
   - Backend tests pass.
   - Frontend typecheck/build pass.
   - Docker Compose starts all services.
   - Manual E2E: Admin, Billing/Payment, Tenant, Maintenance, Technician.

## Acceptance Criteria
- Admin, tenant, and technician authentication works with role-based routing and API authorization.
- Admin can manage property, room, fee config, vehicle config, contracts, meter readings, invoices, maintenance, and dashboard.
- Tenant can view dashboard, invoices, payment links, maintenance requests, and notifications.
- Technician can view assigned maintenance and mark requests resolved.
- Billing calculations use `BigDecimal`, not `double`, and round with `RoundingMode.HALF_UP`.
- First-month pro-rata applies only when invoice month matches contract move-in month.
- Missing meter readings cause invoice generation to skip and alert admin, not create incorrect invoices.
- Invoice generation is idempotent by room/contract/month.
- PayOS webhook endpoint is public but rejects invalid HMAC signatures.
- Successful PayOS webhook updates invoice to PAID with transaction metadata.
- SMTP email sends invoice, reminder, and payment confirmation templates.
- MinIO stores and serves contract files and images.
- Local Docker Compose runs backend, frontend, Postgres, Redis, and MinIO.
- Production deployment documentation is provider-neutral and complete enough to configure secrets and services.
- Frontend is polished and responsive for all role surfaces.

## Risks and Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Full scope is large. | Long implementation and many integration points. | Use vertical slices and verify after each slice. |
| PayOS SDK/API mismatch. | Payment flow blocked. | Isolate in `payment/PayOSClient`; write contract tests around request/response mapping. |
| Webhook security bug. | Unauthorized invoice mutation. | Verify HMAC before lookup/update; test invalid signatures. |
| Money calculation bugs. | Incorrect billing. | BigDecimal-only service tests for every formula and edge case. |
| Real credentials unavailable. | Real E2E cannot complete. | Keep env-driven config and document required credentials; use test/sandbox credentials when supplied. |
| Frontend polish delays backend validation. | Late discovery of API mismatch. | Build UI per vertical slice, not at the end. |
| Production provider undecided. | Deployment docs may be too abstract. | Provide Docker-based provider-neutral docs and required reverse proxy/env guidance. |

## Verification Steps
1. Backend:
   - Run Maven tests in `htr-backend`.
   - Verify context loads.
   - Verify billing service tests.
   - Verify payment webhook tests.
   - Verify repository/idempotency tests.
2. Frontend:
   - Install dependencies.
   - Run TypeScript check.
   - Run build.
   - Run UI smoke test in browser for login and role routes.
3. Docker:
   - Run Docker Compose from repo root.
   - Confirm backend health, frontend loading, Postgres/Redis/MinIO connectivity.
4. Manual E2E:
   - Admin creates property/room/config/contract.
   - Admin enters readings and generates invoice.
   - Tenant receives/sees invoice and opens PayOS checkout.
   - PayOS callback marks invoice paid.
   - Tenant creates maintenance request.
   - Admin assigns technician.
   - Technician resolves request.
   - Notifications and dashboards reflect state.

## Plan Changelog
- Created from deep-interview spec.
- Favored vertical-slice delivery after comparing backend-first and all-at-once approaches.
- Preserved backend package root `chez1s.htrbackend` per user decision.
- Included provider-neutral production deployment instead of locking to VPS/cloud/Vercel.
