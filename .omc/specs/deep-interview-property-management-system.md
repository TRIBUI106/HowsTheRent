# Deep Interview Spec: Property Management System

## Metadata
- Interview ID: 8f652e5b-e25e-4b5f-8fd4-5e9b54654f85
- Rounds: 7
- Final Ambiguity Score: 20%
- Type: brownfield
- Generated: 2026-05-07
- Threshold: 0.2
- Initial Context Summarized: yes
- Status: PASSED

## Clarity Breakdown
| Dimension | Score | Weight | Weighted |
|-----------|-------|--------|----------|
| Goal Clarity | 0.85 | 0.35 | 0.30 |
| Constraint Clarity | 0.74 | 0.25 | 0.19 |
| Success Criteria | 0.78 | 0.25 | 0.20 |
| Context Clarity | 0.82 | 0.15 | 0.12 |
| **Total Clarity** | | | **0.80** |
| **Ambiguity** | | | **0.20** |

## Goal
Implement the full property/boarding-house management system described in `master-plan.md`, including backend, frontend, database, authentication, billing, PayOS payment, email, MinIO storage, maintenance, notifications, dashboards, Docker local runtime, and portable production deployment documentation.

## Constraints
- Implement the full plan, not only Phase 1 or a backend-only subset.
- Use real external integrations for PayOS, SMTP/email, and MinIO rather than mocks as the target behavior.
- The system must support both local Docker-based execution and production-ready Docker/deployment documentation.
- Production deployment target is intentionally not locked to a specific provider yet; produce portable configuration and docs.
- All UI surfaces should be polished and responsive, not merely API-first placeholders.
- Keep the current backend Java package root: `chez1s.htrbackend`.
- Existing backend is a minimal Spring Boot skeleton and may be expanded/restructured under the current package.
- Frontend does not currently exist and should be created as a new React + TypeScript + Vite project.
- Secrets and real service credentials must be provided through environment variables or `.env` examples, not hardcoded.

## Non-Goals
- Do not rename the backend root package to `com.propms`.
- Do not lock production deployment to a single provider such as VPS, Vercel, or managed cloud at this stage.
- Do not treat mocked PayOS/email/MinIO behavior as final acceptance, though test doubles may be used in automated tests.
- Do not stop at backend-only or minimal unpolished UI.

## Acceptance Criteria
- [ ] Admin can authenticate and access an admin dashboard.
- [ ] Tenant can authenticate and access tenant pages.
- [ ] Technician role is represented and can handle assigned maintenance work.
- [ ] Admin can create and manage properties, fee configs, vehicle configs, rooms, and contracts.
- [ ] Room status changes correctly across empty/rented/maintenance lifecycle where applicable.
- [ ] Admin can enter meter readings and vehicle records.
- [ ] Billing logic calculates rent, electricity, water, vehicle, service fees, total amount, due date, and first-month pro-rata according to `master-plan.md`.
- [ ] Invoice generation is idempotent and does not create duplicates for the same room/month.
- [ ] PayOS payment links are created with valid constraints, including short non-accented descriptions.
- [ ] PayOS webhook verifies HMAC signature before mutating invoice state.
- [ ] Successful PayOS payment updates invoice to PAID with transaction details and paid timestamp.
- [ ] Cash payment can be marked by admin.
- [ ] Email notifications are sent for invoice creation, reminders, and payment confirmation through real SMTP configuration.
- [ ] MinIO stores room images, maintenance images, and contract files through real object storage configuration.
- [ ] Tenant can view invoices, open payment links, create maintenance requests, and see notifications.
- [ ] Admin can view, assign, and track maintenance requests.
- [ ] Technician can resolve assigned maintenance requests.
- [ ] Admin dashboard shows room availability, monthly revenue, and pending/overdue invoice summary.
- [ ] Tenant dashboard shows current invoice status and open maintenance requests.
- [ ] Frontend pages are polished, responsive, and include loading/error/empty states.
- [ ] Local Docker Compose can run backend, frontend, PostgreSQL, Redis, and MinIO.
- [ ] Production-ready Docker/deployment documentation exists with required environment variables and service setup guidance.
- [ ] Automated tests cover critical billing calculations, pro-rata behavior, invoice idempotency, and PayOS webhook signature handling.

## Assumptions Exposed & Resolved
| Assumption | Challenge | Resolution |
|------------|-----------|------------|
| The first implementation could be only Phase 1 or billing MVP. | Asked what the first result should be. | User chose full plan. |
| External services might be mocked initially. | Asked whether PayOS/email/MinIO should be real or mocked. | User chose real services as target behavior. |
| One E2E flow might be enough for acceptance. | Asked which single demo is mandatory. | User chose all E2E flows. |
| Production deployment might not be required. | Contrarian challenge: local Docker only vs production. | User requires both local Docker and production-ready deployment. |
| Production target must be chosen now. | Asked VPS/cloud/Vercel/provider choice. | User chose not to lock provider yet. |
| Full plan could still use basic UI. | Simplifier challenge: what is the simplest acceptable polish level. | User chose polished UI for all roles/surfaces. |
| Backend package could follow master-plan `com.propms`. | Cited current `chez1s.htrbackend` entrypoint and asked package decision. | User chose keeping current package. |

## Technical Context
- `master-plan.md` defines the intended database schema, backend package structure, billing engine, Quartz jobs, PayOS webhook flow, API endpoints, frontend structure, and Docker Compose outline.
- Existing repo is brownfield-light: `htr-backend` exists as a minimal Spring Boot project.
- Current backend entrypoint: `htr-backend/src/main/java/chez1s/htrbackend/HtrBackendApplication.java`.
- Current backend config: `htr-backend/src/main/resources/application.properties` only contains `spring.application.name=htr-backend`.
- Current Maven project: `htr-backend/pom.xml` uses Java 21 and Spring Boot starter/test/Lombok skeleton dependencies.
- No frontend project was found during initial exploration.
- A minimal project vault was created at `docs/czHTR-vault/` to preserve project overview and state.

## Ontology (Key Entities)
| Entity | Type | Fields | Relationships |
|--------|------|--------|---------------|
| User | core domain | id, fullName, email, phone, passwordHash, role, avatarUrl, isActive | Owns properties; tenant signs contracts; technician handles maintenance; receives notifications |
| Property | core domain | id, ownerId, name, address, type, description | Belongs to owner; has rooms, fee config, vehicle config |
| Room | core domain | id, propertyId, roomNumber, floor, areaM2, maxPeople, rentOverride, status, images | Belongs to property; has contracts, meter readings, vehicle records, invoices, maintenance requests |
| Contract | core domain | id, roomId, tenantId, moveInDate, moveOutDate, status, depositAmount, fileUrl | Links tenant to room; drives billing/invoices |
| Invoice | core domain | id, roomId, contractId, invoiceMonth, amounts, status, payment data, dueDate, paidAt | Generated from contract/readings/config; paid by tenant via Payment |
| Payment | external/domain event | method, paymentLinkId, checkoutUrl, transactionId, webhook payload | Updates invoice status; integrates with PayOS |
| MaintenanceRequest | core domain | id, roomId, tenantId, title, description, images, status, assignedTo, resolvedAt | Created by tenant; assigned by admin; resolved by technician |
| Notification | supporting | id, userId, title, body, isRead, type, refId | Sent to users for invoices, maintenance, contract expiry |
| FeeConfig | supporting config | rentDefault, elecPrice, waterMode, waterPrice, serviceFee, proRata flags | Belongs to property; used by billing |
| MeterReading | supporting domain | readingMonth, elecOld, elecNew, waterOld, waterNew, recordedBy | Belongs to room; used by billing |
| ExternalService | external system | PayOS, SMTP, MinIO | Provides payments, email delivery, object storage |
| DeploymentEnvironment | supporting technical | local Docker, production-ready Docker, env vars, docs | Runs backend/frontend/datastores/services |

## Ontology Convergence
| Round | Entity Count | New | Changed | Stable | Stability Ratio |
|-------|--------------|-----|---------|--------|-----------------|
| 1 | 10 | 10 | - | - | - |
| 2 | 11 | 1 | 0 | 10 | 91% |
| 3 | 11 | 0 | 0 | 11 | 100% |
| 4 | 12 | 1 | 0 | 11 | 92% |
| 5 | 12 | 0 | 0 | 12 | 100% |
| 6 | 12 | 0 | 0 | 12 | 100% |
| 7 | 12 | 0 | 0 | 12 | 100% |

## Interview Transcript
<details>
<summary>Full Q&A (7 rounds)</summary>

### Round 1
**Q:** With `master-plan.md` covering backend, frontend, billing, PayOS, email, MinIO, and dashboard, what should the first implementation result be?

**A:** Full plan.

**Ambiguity:** 55% (Goal: 0.65, Constraints: 0.25, Criteria: 0.30, Context: 0.55)

### Round 2
**Q:** Should PayOS, email, and MinIO work with real credentials/services, or use interfaces and mock/dev implementations first?

**A:** Real services.

**Ambiguity:** 46% (Goal: 0.70, Constraints: 0.45, Criteria: 0.35, Context: 0.60)

### Round 3
**Q:** If choosing one most important end-to-end demo to prove success, which is mandatory?

**A:** All E2E.

**Ambiguity:** 36% (Goal: 0.78, Constraints: 0.48, Criteria: 0.62, Context: 0.62)

### Round 4
**Q:** Contrarian challenge: if the goal were stable demo rather than production-ready, would local Docker only be enough?

**A:** Both required.

**Ambiguity:** 30% (Goal: 0.80, Constraints: 0.62, Criteria: 0.66, Context: 0.65)

### Round 5
**Q:** What should the default production deployment target be?

**A:** Chưa cần chọn.

**Ambiguity:** 26% (Goal: 0.82, Constraints: 0.70, Criteria: 0.68, Context: 0.68)

### Round 6
**Q:** Simplifier challenge: what is the simplest acceptable polish/data level that still counts as All E2E?

**A:** Polished all.

**Ambiguity:** 23% (Goal: 0.84, Constraints: 0.72, Criteria: 0.76, Context: 0.70)

### Round 7
**Q:** Current backend package is `chez1s.htrbackend`, while the plan suggests `com.propms`. Should implementation keep current package or switch?

**A:** Keep current.

**Ambiguity:** 20% (Goal: 0.85, Constraints: 0.74, Criteria: 0.78, Context: 0.82)

</details>
