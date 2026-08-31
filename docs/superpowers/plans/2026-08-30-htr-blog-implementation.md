# Property Blog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a public property blog inside the existing HowsTheRent app — one marketing/portfolio post per property with a live vacancy widget, comments and likes gated behind a new self-registerable `GUEST` role, plus an admin authoring/moderation surface — without weakening the app's existing RBAC.

**Architecture:** Additive only. Three new JPA entities (`Post`, `PostComment`, `PostLike`) picked up by `ddl-auto=update` (no Flyway migration, matching the `Room.direction`/`Room.description` precedent). New `/api/public/**` (mostly `permitAll()`, GET-only), `/api/admin/blog/**` (`ADMIN`/`PLATFORM_ADMIN`), and `POST /api/auth/register-guest` endpoints. A security-hardening pass adds explicit `@PreAuthorize` to the endpoints identified in the spec's research as relying only on the blanket "any authenticated user" rule, so introducing `GUEST` doesn't newly expose them. Frontend adds a `PublicShell` (extracted from `LandingPage.tsx`) reused by new `/blog`, `/blog/:slug`, `/blog/register` public routes, new `/admin/blog/*` admin routes, and fixes the two role→redirect call sites that would otherwise fall through to `/tech` for `GUEST`.

**Tech Stack:** Spring Boot 4 / Java 21 / PostgreSQL (`htr-backend/`), React 19.2.5 / TypeScript / Vite / TanStack Query 5 / react-router-dom 7 (`htr-frontend/`). New dependency: `@tiptap/react` + `@tiptap/starter-kit` (React-19-compatible rich-text editor — no WYSIWYG lib exists in this repo today).

**Spec:** `docs/superpowers/specs/2026-08-30-htr-blog-design.md` — this plan implements it section by section; read both together.

## Global Constraints

These apply to every task below, copied verbatim in intent from the spec and `CLAUDE.md`:

- **No new/renamed auth cookie.** Reuse `accessToken`/`refreshToken` exactly as `AuthController` already sets them (root path `/`, `/api/auth/refresh` respectively) — `GUEST` login is just another `users` row with `role=GUEST`. (Spec §7.1.1)
- **Every new entity that reaches a response DTO is built inside `@Transactional(readOnly = true)`** (service layer), even where `@EntityGraph` is also present on the repository method — belt-and-suspenders, matching the project's `open-in-view=false` gap history (`cf67604`, `608b465`, `8c7858b`). (Spec §7.1.2)
- **No Flyway migration file.** New tables/columns/enum values are picked up by `spring.jpa.hibernate.ddl-auto=update` (already the default in `application.properties`), following the `Room.direction`/`Room.description` precedent (commits `2e72c5d`, `c87e697`). Flyway stays disabled (`spring.flyway.enabled=false` by default) — do not add a `V4__*.sql` file.
- **The `@PreAuthorize` hardening pass (Task 2) must land before `GUEST` can log in** — do not skip or defer it; `GUEST` becoming self-registerable is what turns these endpoints' current "any authenticated user" gap into a real public-access hole.
- **DTO mapping stays inline static factory methods on records** (`Response.from(entity)`), matching `RoomResponse`/`PropertyResponse` — no MapStruct, no separate mapper classes.
- **Frontend mutations use `useGuardedMutation`** (`src/hooks/useGuardedMutation.ts`), never raw `useMutation`, per this repo's offline-guard convention.
- **Vietnamese enum→label maps go in `src/lib/utils.ts`** as `Record<string,string>` + fallback, next to `statusLabel`/`categoryLabel`/`directionLabel`.
- **Confirm-before-destructive-action uses `components/ui/dialog.tsx`**, never `window.confirm`.
- **Vacancy is never persisted on `Post`** — always computed live from `Room.status` via `RoomRepository.countByPropertyIdAndStatus`, so it can't drift from reality the way copy-pasted numbers in `content` would.

---

## File Structure

**Backend** (`htr-backend/src/main/java/chez1s/htrbackend/`):

| File | Responsibility |
|---|---|
| `domain/enums/UserRole.java` | *Modify* — add `GUEST` |
| `domain/entity/Post.java` | *Create* — 1:1 with `Property` |
| `domain/entity/PostComment.java` | *Create* |
| `domain/entity/PostLike.java` | *Create* |
| `domain/repository/PostRepository.java` | *Create* |
| `domain/repository/PostCommentRepository.java` | *Create* |
| `domain/repository/PostLikeRepository.java` | *Create* |
| `dto/request/RegisterGuestRequest.java` | *Create* |
| `dto/request/CreatePostCommentRequest.java` | *Create* |
| `dto/request/UpdatePostRequest.java` | *Create* |
| `dto/response/BlogPostSummaryResponse.java` | *Create* |
| `dto/response/BlogPostDetailResponse.java` | *Create* |
| `dto/response/VacancyResponse.java` | *Create* |
| `dto/response/PostCommentResponse.java` | *Create* |
| `dto/response/LikeStatusResponse.java` | *Create* |
| `dto/response/AdminPostSummaryResponse.java` | *Create* |
| `dto/response/AdminPostDetailResponse.java` | *Create* |
| `dto/response/AdminPostCommentResponse.java` | *Create* |
| `dto/response/GeneratedDraftResponse.java` | *Create* |
| `service/AuthService.java` | *Modify* — add `registerGuest` |
| `service/PostService.java` | *Create* — all blog read/write logic |
| `controller/AuthController.java` | *Modify* — add `POST /api/auth/register-guest` |
| `controller/PublicBlogController.java` | *Create* |
| `controller/PublicPropertyController.java` | *Create* — vacancy only |
| `controller/AdminBlogController.java` | *Create* |
| `controller/SitemapController.java` | *Create* |
| `controller/PropertyController.java`, `ContractController.java`, `InvoiceController.java`, `MaintenanceController.java`, `MaintenanceReportController.java`, `NotificationController.java`, `UserController.java` | *Modify* — `@PreAuthorize` hardening pass (Task 2) |
| `config/SecurityConfig.java` | *Modify* — `permitAll()` for `GET /api/public/**` and `/sitemap.xml` |
| `src/main/resources/application.properties` | *Modify* — add `app.public-base-url` |

**Frontend** (`htr-frontend/src/`):

| File | Responsibility |
|---|---|
| `types/index.ts` | *Modify* — add `'GUEST'` to `User.role` |
| `lib/homePath.ts` | *Create* — single source of truth for role→landing-path, replacing the two divergent inline ternaries |
| `App.tsx` | *Modify* — use `homePathForRole`, add `/blog*` routes |
| `features/auth/pages/LoginPage.tsx` | *Modify* — use `homePathForRole` |
| `components/PublicShell.tsx` | *Create* — `NavPill`/`Footer` extracted from `LandingPage.tsx` |
| `pages/LandingPage.tsx` | *Modify* — use `PublicShell` |
| `api/blogApi.ts` | *Create* — public blog + vacancy calls |
| `api/adminBlogApi.ts` | *Create* — admin blog calls |
| `api/index.ts` | *Modify* — barrel-export both |
| `lib/utils.ts` | *Modify* — add `postStatusLabel` |
| `pages/blog/BlogListPage.tsx` | *Create* — `/blog` |
| `pages/blog/BlogPostPage.tsx` | *Create* — `/blog/:slug` |
| `features/auth/pages/RegisterGuestPage.tsx` | *Create* — `/blog/register` |
| `hooks/useDocumentMeta.ts` | *Create* |
| `router/adminRoutes.tsx` | *Modify* — add `/admin/blog*` routes |
| `features/admin/pages/blog/AdminBlogListPage.tsx` | *Create* — `/admin/blog` |
| `features/admin/pages/blog/AdminBlogEditorPage.tsx` | *Create* — `/admin/blog/:propertyId` |
| `features/admin/pages/blog/AdminBlogCommentsPage.tsx` | *Create* — `/admin/blog/comments` |
| `public/robots.txt` | *Create* |

---

## Phase 1 — Backend: role, security hardening, entities

### Task 1: Add `GUEST` to `UserRole`

**Files:**
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/domain/enums/UserRole.java`
- Test: `htr-backend/src/test/java/chez1s/htrbackend/domain/enums/UserRoleTest.java`

**Interfaces:**
- Produces: `UserRole.GUEST` — consumed by every task in this plan that issues or checks a `GUEST` login.

- [ ] **Step 1: Write the failing test**

```java
package chez1s.htrbackend.domain.enums;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class UserRoleTest {

    @Test
    void guestRoleExists() {
        assertThat(UserRole.valueOf("GUEST")).isEqualTo(UserRole.GUEST);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=UserRoleTest`
Expected: FAIL with `IllegalArgumentException: No enum constant ... UserRole.GUEST`

- [ ] **Step 3: Add the enum value**

```java
package chez1s.htrbackend.domain.enums;

public enum UserRole {
    ADMIN,
    PLATFORM_ADMIN,
    LANDLORD_ADMIN,
    TENANT,
    TECHNICIAN,
    GUEST
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd htr-backend && ./mvnw test -Dtest=UserRoleTest`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add htr-backend/src/main/java/chez1s/htrbackend/domain/enums/UserRole.java htr-backend/src/test/java/chez1s/htrbackend/domain/enums/UserRoleTest.java
git commit -m "feat(blog): add GUEST role"
```

### Task 2: `@PreAuthorize` hardening pass on currently-unprotected endpoints

**Context:** `SecurityConfig`'s `authorizeHttpRequests` chain is only `/api/auth/**`, `/api/health`, `/api/payment/callback`, and CORS `OPTIONS` `permitAll()` — everything else falls to `.anyRequest().authenticated()`. The 14 methods below currently carry no `@PreAuthorize`, so today "any authenticated user" (every existing role, all admin-provisioned) can reach them. Once `GUEST` becomes self-registerable (Task 6), that same rule would let an anonymous-signup visitor reach them too. This task closes that gap before Task 6 ships, by adding an explicit `@PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT','TECHNICIAN')")` (every role that exists today, excluding `GUEST`) to each one. This must merge before Task 6.

**Files:**
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/controller/PropertyController.java:39` (`getById`)
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/controller/ContractController.java:65` (`getById`)
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/controller/InvoiceController.java:55` (`getById`)
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/controller/MaintenanceController.java:232` (`listMaterials`), `:252` (`listNotes`), `:257` (`addNote`)
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/controller/MaintenanceReportController.java:96` (`getTechnicianReviews`), `:101` (`getAllReviews`), `:106` (`getAllSlaRules`)
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/controller/NotificationController.java:27` (`stream`), `:32` (`list`), `:40` (`markAsRead`), `:46` (`markAllAsRead`)
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/controller/UserController.java:59` (`getMe`)
- Test: `htr-backend/src/test/java/chez1s/htrbackend/controller/PreAuthorizeHardeningTest.java`

**Interfaces:**
- No new signatures — annotation-only change, existing method bodies untouched.

- [ ] **Step 1: Write the failing test**

Reflection-based, matching this repo's plain-Mockito (no Spring context) controller test style — asserts the SpEL string directly rather than standing up a full security filter chain:

```java
package chez1s.htrbackend.controller;

import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.prepost.PreAuthorize;

import java.lang.reflect.Method;
import java.util.UUID;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

@ExtendWith(MockitoExtension.class)
class PreAuthorizeHardeningTest {

    private static final String EXPECTED =
            "hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT','TECHNICIAN')";

    static Stream<Method> hardenedMethods() throws NoSuchMethodException {
        return Stream.of(
                PropertyController.class.getMethod("getById", UUID.class),
                ContractController.class.getMethod("getById",
                        org.springframework.security.core.Authentication.class, UUID.class),
                InvoiceController.class.getMethod("getById",
                        org.springframework.security.core.Authentication.class, UUID.class),
                MaintenanceController.class.getMethod("listMaterials", UUID.class),
                MaintenanceController.class.getMethod("listNotes", UUID.class),
                MaintenanceController.class.getMethod("addNote",
                        org.springframework.security.core.Authentication.class, UUID.class, String.class),
                MaintenanceReportController.class.getMethod("getTechnicianReviews", UUID.class),
                MaintenanceReportController.class.getMethod("getAllReviews"),
                MaintenanceReportController.class.getMethod("getAllSlaRules"),
                NotificationController.class.getMethod("stream",
                        org.springframework.security.core.Authentication.class),
                NotificationController.class.getMethod("list",
                        org.springframework.security.core.Authentication.class,
                        org.springframework.data.domain.Pageable.class),
                NotificationController.class.getMethod("markAsRead", UUID.class),
                NotificationController.class.getMethod("markAllAsRead",
                        org.springframework.security.core.Authentication.class),
                UserController.class.getMethod("getMe",
                        org.springframework.security.core.Authentication.class)
        );
    }

    @ParameterizedTest
    @MethodSource("hardenedMethods")
    void everyPreviouslyOpenEndpointNowExcludesGuest(Method method) {
        PreAuthorize annotation = method.getAnnotation(PreAuthorize.class);
        assertThat(annotation)
                .as("%s.%s must carry @PreAuthorize excluding GUEST", method.getDeclaringClass().getSimpleName(), method.getName())
                .isNotNull();
        assertThat(annotation.value()).isEqualTo(EXPECTED);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=PreAuthorizeHardeningTest`
Expected: FAIL — every parameterized case fails because `annotation` is null

- [ ] **Step 3: Add the annotation to each of the 14 methods**

Directly above each method's existing `@GetMapping`/`@PostMapping`, e.g.:

```java
// PropertyController.java
@GetMapping("/{id}")
@PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT','TECHNICIAN')")
public ResponseEntity<PropertyResponse> getById(@PathVariable UUID id) {
    return ResponseEntity.ok(PropertyResponse.from(propertyService.getById(id)));
}
```

```java
// ContractController.java — getById
@GetMapping("/contracts/{id}")
@PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT','TECHNICIAN')")
public ResponseEntity<ContractResponse> getById(Authentication authentication, @PathVariable UUID id) {
    // body unchanged
}
```

```java
// InvoiceController.java — getById
@GetMapping("/{id}")
@PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT','TECHNICIAN')")
public ResponseEntity<InvoiceResponse> getById(Authentication authentication, @PathVariable UUID id) {
    // body unchanged
}
```

```java
// MaintenanceController.java — three methods
@GetMapping("/{id}/materials")
@PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT','TECHNICIAN')")
public ResponseEntity<List<MaintenanceMaterialResponse>> listMaterials(@PathVariable UUID id) { /* unchanged */ }

@GetMapping("/{id}/notes")
@PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT','TECHNICIAN')")
public ResponseEntity<List<MaintenanceNoteResponse>> listNotes(@PathVariable UUID id) { /* unchanged */ }

@PostMapping("/{id}/notes")
@PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT','TECHNICIAN')")
public ResponseEntity<MaintenanceNoteResponse> addNote(Authentication auth, @PathVariable UUID id,
                                                       @RequestParam("note") String note) { /* unchanged */ }
```

```java
// MaintenanceReportController.java — three methods (add `import org.springframework.security.access.prepost.PreAuthorize;` if absent)
@GetMapping("/reviews/technician/{techId}")
@PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT','TECHNICIAN')")
public ResponseEntity<List<MaintenanceReviewResponse>> getTechnicianReviews(@PathVariable UUID techId) { /* unchanged */ }

@GetMapping("/reviews")
@PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT','TECHNICIAN')")
public ResponseEntity<List<MaintenanceReviewResponse>> getAllReviews() { /* unchanged */ }

@GetMapping("/sla-rules")
@PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT','TECHNICIAN')")
public ResponseEntity<List<SlaRuleResponse>> getAllSlaRules() { /* unchanged */ }
```

```java
// NotificationController.java — four methods (add `import org.springframework.security.access.prepost.PreAuthorize;`)
@GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
@PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT','TECHNICIAN')")
public SseEmitter stream(Authentication auth) { /* unchanged */ }

@GetMapping
@PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT','TECHNICIAN')")
public ResponseEntity<PageResponse<NotificationResponse>> list(Authentication auth,
        @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) { /* unchanged */ }

@PostMapping("/{id}/read")
@PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT','TECHNICIAN')")
public ResponseEntity<Map<String, String>> markAsRead(@PathVariable UUID id) { /* unchanged */ }

@PostMapping("/read-all")
@PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT','TECHNICIAN')")
public ResponseEntity<Map<String, String>> markAllAsRead(Authentication auth) { /* unchanged */ }
```

```java
// UserController.java — getMe
@GetMapping("/me")
@PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT','TECHNICIAN')")
public ResponseEntity<UserResponse> getMe(Authentication auth) { /* unchanged */ }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd htr-backend && ./mvnw test -Dtest=PreAuthorizeHardeningTest`
Expected: PASS — all 14 parameterized cases green

- [ ] **Step 5: Run the full backend test suite to confirm no existing role's access broke**

Run: `cd htr-backend && ./mvnw test`
Expected: PASS. Every existing role (`TENANT`, `TECHNICIAN`, `ADMIN`, `PLATFORM_ADMIN`, `LANDLORD_ADMIN`) was already implicitly allowed by the old catch-all and is explicitly re-included in the new annotation, so no existing caller should now 403.

- [ ] **Step 6: Commit**

```bash
git add htr-backend/src/main/java/chez1s/htrbackend/controller/PropertyController.java htr-backend/src/main/java/chez1s/htrbackend/controller/ContractController.java htr-backend/src/main/java/chez1s/htrbackend/controller/InvoiceController.java htr-backend/src/main/java/chez1s/htrbackend/controller/MaintenanceController.java htr-backend/src/main/java/chez1s/htrbackend/controller/MaintenanceReportController.java htr-backend/src/main/java/chez1s/htrbackend/controller/NotificationController.java htr-backend/src/main/java/chez1s/htrbackend/controller/UserController.java htr-backend/src/test/java/chez1s/htrbackend/controller/PreAuthorizeHardeningTest.java
git commit -m "fix(security): require explicit role on endpoints that only relied on 'any authenticated user'"
```

### Task 3: `Post` entity + `PostRepository`

**Files:**
- Create: `htr-backend/src/main/java/chez1s/htrbackend/domain/entity/Post.java`
- Create: `htr-backend/src/main/java/chez1s/htrbackend/domain/repository/PostRepository.java`
- Test: `htr-backend/src/test/java/chez1s/htrbackend/domain/repository/PostRepositoryTest.java`

**Interfaces:**
- Consumes: `Property` (`domain/entity/Property.java`), `User` (`domain/entity/User.java`), `BaseEntity` (`created_at`/`updated_at` via `@PrePersist`/`@PreUpdate`).
- Produces: `Post` entity with getters `getId()`, `getProperty()`, `getTitle()`, `getSlug()`, `getContent()`, `getCoverImageUrl()`, `isPublished()`, `getPublishedAt()`, `getAuthor()`, `getCreatedAt()`, `getUpdatedAt()`, and matching setters (Lombok `@Getter @Setter`). `PostRepository` methods: `findBySlugAndPublishedTrue(String)`, `findByPropertyId(UUID)`, `findByPublishedTrueOrderByPublishedAtDesc()`, `existsBySlug(String)`, `existsBySlugAndIdNot(String, UUID)` — consumed by Tasks 8, 12–17.

- [ ] **Step 1: Write the failing test**

This project has no `@DataJpaTest`/Testcontainers precedent for repositories (`InvoiceRepositoryTest.java` is the closest existing example — check it uses plain unit assertions on query-derivation, not an embedded DB); follow that same lightweight style: verify the entity round-trips through a `@Builder` and that repository method names compile against the entity's actual field names (a compile-time check is the meaningful "test" here, backed by one assertion on `BaseEntity`'s lifecycle callbacks, which is unit-testable without a DB):

```java
package chez1s.htrbackend.domain.entity;

import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class PostTest {

    @Test
    void builderProducesAnUnpublishedDraftByDefault() {
        Property property = Property.builder().id(UUID.randomUUID()).build();

        Post post = Post.builder()
                .property(property)
                .title("Nhà trọ Xanh")
                .slug("nha-tro-xanh")
                .content("<p>Xin chào</p>")
                .build();

        assertThat(post.isPublished()).isFalse();
        assertThat(post.getPublishedAt()).isNull();
        assertThat(post.getProperty()).isSameAs(property);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=PostTest`
Expected: FAIL to compile — `Post` does not exist yet

- [ ] **Step 3: Create the entity**

```java
package chez1s.htrbackend.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "posts")
public class Post extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "property_id", nullable = false, unique = true)
    private Property property;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(nullable = false, unique = true, length = 220)
    private String slug;

    @Column(columnDefinition = "TEXT")
    private String content;

    @Column(name = "cover_image_url")
    private String coverImageUrl;

    @Column(nullable = false)
    @Builder.Default
    private boolean published = false;

    @Column(name = "published_at")
    private LocalDateTime publishedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id")
    private User author;
}
```

- [ ] **Step 4: Create the repository**

```java
package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.Post;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PostRepository extends JpaRepository<Post, UUID> {

    @EntityGraph(attributePaths = {"property", "author"})
    Optional<Post> findBySlugAndPublishedTrue(String slug);

    @EntityGraph(attributePaths = {"property", "author"})
    Optional<Post> findByPropertyId(UUID propertyId);

    @EntityGraph(attributePaths = {"property"})
    List<Post> findByPublishedTrueOrderByPublishedAtDesc();

    boolean existsBySlug(String slug);

    boolean existsBySlugAndIdNot(String slug, UUID id);
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd htr-backend && ./mvnw test -Dtest=PostTest`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add htr-backend/src/main/java/chez1s/htrbackend/domain/entity/Post.java htr-backend/src/main/java/chez1s/htrbackend/domain/repository/PostRepository.java htr-backend/src/test/java/chez1s/htrbackend/domain/entity/PostTest.java
git commit -m "feat(blog): add Post entity and repository"
```

### Task 4: `PostComment` entity + `PostCommentRepository`

**Files:**
- Create: `htr-backend/src/main/java/chez1s/htrbackend/domain/entity/PostComment.java`
- Create: `htr-backend/src/main/java/chez1s/htrbackend/domain/repository/PostCommentRepository.java`
- Test: `htr-backend/src/test/java/chez1s/htrbackend/domain/entity/PostCommentTest.java`

**Interfaces:**
- Consumes: `Post` (Task 3), `User`.
- Produces: `PostComment` getters `getId()`, `getPost()`, `getUser()`, `getContent()`, `getCreatedAt()`. `PostCommentRepository.findByPostIdOrderByCreatedAtAsc(UUID)`, `.findAllByOrderByCreatedAtDesc()` — consumed by Tasks 9, 10, 17.

**Note:** the spec's table for `PostComment` lists only `created_at` (no `updated_at`), but this entity extends `BaseEntity` (which provides both) to match every other entity in this codebase (`Room`, `Property`, `User` all extend it, none define timestamps ad hoc) — `updated_at` is simply unused by any comment-editing flow (comments aren't editable in v1), which is harmless.

- [ ] **Step 1: Write the failing test**

```java
package chez1s.htrbackend.domain.entity;

import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class PostCommentTest {

    @Test
    void builderLinksCommentToPostAndAuthor() {
        Post post = Post.builder().id(UUID.randomUUID()).build();
        User user = User.builder().id(UUID.randomUUID()).fullName("Khách A").build();

        PostComment comment = PostComment.builder()
                .post(post)
                .user(user)
                .content("Phòng đẹp quá!")
                .build();

        assertThat(comment.getPost()).isSameAs(post);
        assertThat(comment.getUser()).isSameAs(user);
        assertThat(comment.getContent()).isEqualTo("Phòng đẹp quá!");
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=PostCommentTest`
Expected: FAIL to compile — `PostComment` does not exist yet

- [ ] **Step 3: Create the entity**

```java
package chez1s.htrbackend.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "post_comments")
public class PostComment extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "post_id", nullable = false)
    private Post post;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;
}
```

- [ ] **Step 4: Create the repository**

```java
package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.PostComment;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface PostCommentRepository extends JpaRepository<PostComment, UUID> {

    @EntityGraph(attributePaths = {"user"})
    List<PostComment> findByPostIdOrderByCreatedAtAsc(UUID postId);

    @EntityGraph(attributePaths = {"user", "post"})
    List<PostComment> findAllByOrderByCreatedAtDesc();
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd htr-backend && ./mvnw test -Dtest=PostCommentTest`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add htr-backend/src/main/java/chez1s/htrbackend/domain/entity/PostComment.java htr-backend/src/main/java/chez1s/htrbackend/domain/repository/PostCommentRepository.java htr-backend/src/test/java/chez1s/htrbackend/domain/entity/PostCommentTest.java
git commit -m "feat(blog): add PostComment entity and repository"
```

### Task 5: `PostLike` entity + `PostLikeRepository`

**Files:**
- Create: `htr-backend/src/main/java/chez1s/htrbackend/domain/entity/PostLike.java`
- Create: `htr-backend/src/main/java/chez1s/htrbackend/domain/repository/PostLikeRepository.java`
- Test: `htr-backend/src/test/java/chez1s/htrbackend/domain/entity/PostLikeTest.java`

**Interfaces:**
- Consumes: `Post` (Task 3), `User`.
- Produces: `PostLikeRepository.findByPostIdAndUserId(UUID, UUID)`, `.countByPostId(UUID)`, `.existsByPostIdAndUserId(UUID, UUID)`, `.deleteByPostIdAndUserId(UUID, UUID)` — consumed by Task 11.

- [ ] **Step 1: Write the failing test**

```java
package chez1s.htrbackend.domain.entity;

import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class PostLikeTest {

    @Test
    void builderLinksLikeToPostAndUser() {
        Post post = Post.builder().id(UUID.randomUUID()).build();
        User user = User.builder().id(UUID.randomUUID()).build();

        PostLike like = PostLike.builder()
                .post(post)
                .user(user)
                .build();

        assertThat(like.getPost()).isSameAs(post);
        assertThat(like.getUser()).isSameAs(user);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=PostLikeTest`
Expected: FAIL to compile — `PostLike` does not exist yet

- [ ] **Step 3: Create the entity**

```java
package chez1s.htrbackend.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "post_likes", uniqueConstraints = @UniqueConstraint(columnNames = {"post_id", "user_id"}))
public class PostLike extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "post_id", nullable = false)
    private Post post;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
}
```

- [ ] **Step 4: Create the repository**

```java
package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.PostLike;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface PostLikeRepository extends JpaRepository<PostLike, UUID> {

    Optional<PostLike> findByPostIdAndUserId(UUID postId, UUID userId);

    long countByPostId(UUID postId);

    boolean existsByPostIdAndUserId(UUID postId, UUID userId);

    void deleteByPostIdAndUserId(UUID postId, UUID userId);
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd htr-backend && ./mvnw test -Dtest=PostLikeTest`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add htr-backend/src/main/java/chez1s/htrbackend/domain/entity/PostLike.java htr-backend/src/main/java/chez1s/htrbackend/domain/repository/PostLikeRepository.java htr-backend/src/test/java/chez1s/htrbackend/domain/entity/PostLikeTest.java
git commit -m "feat(blog): add PostLike entity and repository"
```

---

## Phase 2 — Backend: guest self-registration

### Task 6: `POST /api/auth/register-guest`

**Files:**
- Create: `htr-backend/src/main/java/chez1s/htrbackend/dto/request/RegisterGuestRequest.java`
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/service/AuthService.java`
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/controller/AuthController.java`
- Test: `htr-backend/src/test/java/chez1s/htrbackend/service/AuthServiceRegisterGuestTest.java`
- Test: `htr-backend/src/test/java/chez1s/htrbackend/controller/AuthControllerRegisterGuestTest.java`

**Interfaces:**
- Consumes: `UserRole.GUEST` (Task 1), `AuthController`'s existing `setTokenCookies(HttpServletResponse, String, String)` private helper (already used by `login`/`refresh`).
- Produces: `AuthService.registerGuest(RegisterGuestRequest)` returning the existing `AuthResponse` record (`accessToken`, `refreshToken`, `UserResponse user`) — same shape `login` already returns, so the frontend's existing `authApi`-style handling needs no new response type.

- [ ] **Step 1: Write the failing service test**

```java
package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.domain.repository.UserRepository;
import chez1s.htrbackend.dto.request.RegisterGuestRequest;
import chez1s.htrbackend.dto.response.AuthResponse;
import chez1s.htrbackend.exception.BusinessException;
import chez1s.htrbackend.security.JwtTokenProvider;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceRegisterGuestTest {

    @Mock UserRepository userRepository;
    @Mock PasswordEncoder passwordEncoder;
    @Mock JwtTokenProvider tokenProvider;
    @Mock EmailService emailService;

    private AuthService authService() {
        return new AuthService(userRepository, passwordEncoder, tokenProvider, emailService);
    }

    @Test
    void createsAGuestUserAndReturnsTokens() {
        AuthService authService = authService();
        RegisterGuestRequest req = new RegisterGuestRequest();
        req.setFullName("Khách A");
        req.setEmail("guest@example.com");
        req.setPassword("Password1!");

        when(userRepository.existsByEmail("guest@example.com")).thenReturn(false);
        when(passwordEncoder.encode("Password1!")).thenReturn("hashed");
        when(userRepository.save(any(User.class))).thenAnswer(inv -> {
            User u = inv.getArgument(0);
            u.setId(java.util.UUID.randomUUID());
            return u;
        });
        when(tokenProvider.generateAccessToken(any(), any(), any(), anyLong())).thenReturn("access");
        when(tokenProvider.generateRefreshToken(any(), any(), any(), anyLong())).thenReturn("refresh");

        AuthResponse response = authService.registerGuest(req);

        assertThat(response.accessToken()).isEqualTo("access");
        assertThat(response.refreshToken()).isEqualTo("refresh");
        assertThat(response.user().role()).isEqualTo("GUEST");

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        org.mockito.Mockito.verify(userRepository).save(captor.capture());
        assertThat(captor.getValue().getRole()).isEqualTo(UserRole.GUEST);
        assertThat(captor.getValue().getPasswordHash()).isEqualTo("hashed");
    }

    @Test
    void rejectsDuplicateEmail() {
        AuthService authService = authService();
        RegisterGuestRequest req = new RegisterGuestRequest();
        req.setFullName("Khách B");
        req.setEmail("existing@example.com");
        req.setPassword("Password1!");

        when(userRepository.existsByEmail("existing@example.com")).thenReturn(true);

        assertThatThrownBy(() -> authService.registerGuest(req))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Email đã được sử dụng");
    }

    private static long anyLong() {
        return org.mockito.ArgumentMatchers.anyLong();
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=AuthServiceRegisterGuestTest`
Expected: FAIL to compile — `RegisterGuestRequest` and `AuthService.registerGuest` don't exist yet

- [ ] **Step 3: Create the request DTO**

```java
package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class RegisterGuestRequest {

    @NotBlank
    private String fullName;

    @NotBlank
    @Email
    private String email;

    @NotBlank
    @Size(min = 8, message = "Mật khẩu phải có ít nhất 8 ký tự")
    private String password;

    private String phone;
}
```

- [ ] **Step 4: Add `registerGuest` to `AuthService`**

```java
// AuthService.java — add import chez1s.htrbackend.domain.enums.UserRole; and chez1s.htrbackend.dto.request.RegisterGuestRequest;
public AuthResponse registerGuest(RegisterGuestRequest request) {
    String email = normalizeEmail(request.getEmail());
    if (userRepository.existsByEmail(email)) {
        throw new BusinessException("Email đã được sử dụng");
    }
    User user = User.builder()
            .fullName(request.getFullName())
            .email(email)
            .phone(request.getPhone())
            .passwordHash(passwordEncoder.encode(request.getPassword()))
            .role(UserRole.GUEST)
            .active(true)
            .build();
    user = userRepository.save(user);
    String accessToken = tokenProvider.generateAccessToken(user.getId(), user.getEmail(), user.getRole().name(), user.getAuthVersion());
    String refreshToken = tokenProvider.generateRefreshToken(user.getId(), user.getEmail(), user.getRole().name(), user.getAuthVersion());
    return new AuthResponse(accessToken, refreshToken, UserResponse.from(user));
}
```

- [ ] **Step 5: Run the service test to verify it passes**

Run: `cd htr-backend && ./mvnw test -Dtest=AuthServiceRegisterGuestTest`
Expected: PASS

- [ ] **Step 6: Write the failing controller test**

```java
package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.request.RegisterGuestRequest;
import chez1s.htrbackend.dto.response.AuthResponse;
import chez1s.htrbackend.dto.response.UserResponse;
import chez1s.htrbackend.service.AuthService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class AuthControllerRegisterGuestTest {

    private AuthService authService;
    private AuthController controller;

    @BeforeEach
    void setup() {
        authService = mock(AuthService.class);
        controller = new AuthController(authService);
        ReflectionTestUtils.setField(controller, "secureCookies", true);
        ReflectionTestUtils.setField(controller, "cookieSameSite", "Lax");
    }

    @Test
    void registerGuestReturns201AndSetsAccessTokenCookieAtRootPath() {
        UserResponse user = new UserResponse(UUID.randomUUID(), "Khách A", "guest@example.com", null, "GUEST", null, true);
        when(authService.registerGuest(any(RegisterGuestRequest.class)))
                .thenReturn(new AuthResponse("access-token", "refresh-token", user));
        MockHttpServletResponse response = new MockHttpServletResponse();

        ResponseEntity<AuthResponse> result = controller.registerGuest(new RegisterGuestRequest(), response);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(result.getBody().user().role()).isEqualTo("GUEST");
        assertThat(response.getHeaders(HttpHeaders.SET_COOKIE))
                .anySatisfy(cookie -> assertThat(cookie).startsWith("accessToken=access-token;").contains("Path=/;"));
    }
}
```

- [ ] **Step 7: Run the controller test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=AuthControllerRegisterGuestTest`
Expected: FAIL to compile — `AuthController.registerGuest` doesn't exist yet

- [ ] **Step 8: Add the endpoint to `AuthController`**

```java
// AuthController.java — add import chez1s.htrbackend.dto.request.RegisterGuestRequest;
@PostMapping("/register-guest")
public ResponseEntity<AuthResponse> registerGuest(@Valid @RequestBody RegisterGuestRequest request,
                                                  HttpServletResponse response) {
    AuthResponse authResponse = authService.registerGuest(request);
    setTokenCookies(response, authResponse.accessToken(), authResponse.refreshToken());
    return ResponseEntity.status(HttpStatus.CREATED).body(authResponse);
}
```

This lands under `/api/auth/**`, already `permitAll()` in `SecurityConfig` — no security config change needed for this endpoint.

- [ ] **Step 9: Run both tests to verify they pass**

Run: `cd htr-backend && ./mvnw test -Dtest=AuthServiceRegisterGuestTest,AuthControllerRegisterGuestTest`
Expected: PASS

- [ ] **Step 10: Commit**

```bash
git add htr-backend/src/main/java/chez1s/htrbackend/dto/request/RegisterGuestRequest.java htr-backend/src/main/java/chez1s/htrbackend/service/AuthService.java htr-backend/src/main/java/chez1s/htrbackend/controller/AuthController.java htr-backend/src/test/java/chez1s/htrbackend/service/AuthServiceRegisterGuestTest.java htr-backend/src/test/java/chez1s/htrbackend/controller/AuthControllerRegisterGuestTest.java
git commit -m "feat(blog): add guest self-registration endpoint"
```

---

## Phase 3 — Backend: public read endpoints

### Task 7: `GET /api/public/properties/{id}/vacancy` + `SecurityConfig` `permitAll()` wiring

**Files:**
- Create: `htr-backend/src/main/java/chez1s/htrbackend/dto/response/VacancyResponse.java`
- Create: `htr-backend/src/main/java/chez1s/htrbackend/controller/PublicPropertyController.java`
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/config/SecurityConfig.java`
- Test: `htr-backend/src/test/java/chez1s/htrbackend/controller/PublicPropertyControllerTest.java`

**Interfaces:**
- Consumes: `RoomRepository.countByPropertyIdAndStatus(UUID, RoomStatus)` (already exists, used identically by `DashboardController`), `PropertyService.getById(UUID)` (404s via `ResourceNotFoundException` if the property doesn't exist).
- Produces: `VacancyResponse(long emptyCount, long rentedCount, long totalCount)` — consumed by Task 8's listing DTO and the frontend's `blogApi.getVacancy` (Task 21).

- [ ] **Step 1: Write the failing test**

```java
package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.RoomRepository;
import chez1s.htrbackend.dto.response.VacancyResponse;
import chez1s.htrbackend.service.PropertyService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PublicPropertyControllerTest {

    @Mock PropertyService propertyService;
    @Mock RoomRepository roomRepository;

    private PublicPropertyController controller;
    private UUID propertyId;

    @BeforeEach
    void setup() {
        controller = new PublicPropertyController(propertyService, roomRepository);
        propertyId = UUID.randomUUID();
        when(propertyService.getById(propertyId)).thenReturn(Property.builder().id(propertyId).build());
    }

    @Test
    void vacancyReturnsCountsByStatus() {
        when(roomRepository.countByPropertyIdAndStatus(propertyId, RoomStatus.EMPTY)).thenReturn(2L);
        when(roomRepository.countByPropertyIdAndStatus(propertyId, RoomStatus.RENTED)).thenReturn(5L);
        when(roomRepository.countByPropertyIdAndStatus(propertyId, RoomStatus.MAINTENANCE)).thenReturn(1L);

        ResponseEntity<VacancyResponse> result = controller.vacancy(propertyId);

        assertThat(result.getBody().emptyCount()).isEqualTo(2L);
        assertThat(result.getBody().rentedCount()).isEqualTo(5L);
        assertThat(result.getBody().totalCount()).isEqualTo(8L);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=PublicPropertyControllerTest`
Expected: FAIL to compile — `PublicPropertyController`/`VacancyResponse` don't exist yet

- [ ] **Step 3: Create `VacancyResponse`**

```java
package chez1s.htrbackend.dto.response;

public record VacancyResponse(long emptyCount, long rentedCount, long totalCount) {
}
```

- [ ] **Step 4: Create `PublicPropertyController`**

```java
package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.RoomRepository;
import chez1s.htrbackend.dto.response.VacancyResponse;
import chez1s.htrbackend.service.PropertyService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/public/properties")
@RequiredArgsConstructor
public class PublicPropertyController {

    private final PropertyService propertyService;
    private final RoomRepository roomRepository;

    @GetMapping("/{id}/vacancy")
    public ResponseEntity<VacancyResponse> vacancy(@PathVariable UUID id) {
        propertyService.getById(id); // 404s via ResourceNotFoundException if the property doesn't exist
        long empty = roomRepository.countByPropertyIdAndStatus(id, RoomStatus.EMPTY);
        long rented = roomRepository.countByPropertyIdAndStatus(id, RoomStatus.RENTED);
        long maintenance = roomRepository.countByPropertyIdAndStatus(id, RoomStatus.MAINTENANCE);
        return ResponseEntity.ok(new VacancyResponse(empty, rented, empty + rented + maintenance));
    }
}
```

No `@PreAuthorize` here — matches the established convention for fully-public endpoints (`AuthController`'s `login`/`forgotPassword` also carry none), relying entirely on `SecurityConfig`'s `permitAll()` added in the next step.

- [ ] **Step 5: Add the `permitAll()` rule to `SecurityConfig`**

```java
// SecurityConfig.java — add import org.springframework.http.HttpMethod; if not already present
.authorizeHttpRequests(auth -> auth
    .requestMatchers("/api/auth/**").permitAll()
    .requestMatchers("/api/health").permitAll()
    .requestMatchers("/api/payment/callback").permitAll()
    .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
    .requestMatchers(HttpMethod.GET, "/api/public/**").permitAll()
    .requestMatchers("/sitemap.xml").permitAll()
    .anyRequest().authenticated()
)
```

Deliberately `HttpMethod.GET` only — `POST`/`DELETE` requests under `/api/public/**` (the comment and like endpoints added in Tasks 10–11) still fall through to `.anyRequest().authenticated()`, matching the spec's "only comment and like require login" rule.

- [ ] **Step 6: Run test to verify it passes**

Run: `cd htr-backend && ./mvnw test -Dtest=PublicPropertyControllerTest`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add htr-backend/src/main/java/chez1s/htrbackend/dto/response/VacancyResponse.java htr-backend/src/main/java/chez1s/htrbackend/controller/PublicPropertyController.java htr-backend/src/main/java/chez1s/htrbackend/config/SecurityConfig.java htr-backend/src/test/java/chez1s/htrbackend/controller/PublicPropertyControllerTest.java
git commit -m "feat(blog): add public vacancy endpoint"
```

### Task 8: `PostService` (list + detail) + `GET /api/public/blog/posts` / `GET /api/public/blog/posts/{slug}`

**Files:**
- Create: `htr-backend/src/main/java/chez1s/htrbackend/dto/response/BlogPostSummaryResponse.java`
- Create: `htr-backend/src/main/java/chez1s/htrbackend/dto/response/BlogPostDetailResponse.java`
- Create: `htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java`
- Create: `htr-backend/src/main/java/chez1s/htrbackend/controller/PublicBlogController.java`
- Test: `htr-backend/src/test/java/chez1s/htrbackend/service/PostServiceTest.java`
- Test: `htr-backend/src/test/java/chez1s/htrbackend/controller/PublicBlogControllerTest.java`

**Interfaces:**
- Consumes: `PostRepository` (Task 3), `RoomRepository.countByPropertyIdAndStatus` (Task 7's pattern), `ResourceNotFoundException`.
- Produces: `PostService.listPublished()` → `List<BlogPostSummaryResponse>`; `PostService.getPublishedBySlug(String)` → `BlogPostDetailResponse` (throws `ResourceNotFoundException` if missing/unpublished) — both consumed by `PublicBlogController` here and reused unchanged by no other task. `PostService` itself is extended by Tasks 9–17 with more methods on the same class.

- [ ] **Step 1: Write the failing service test**

```java
package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Post;
import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.*;
import chez1s.htrbackend.dto.response.BlogPostDetailResponse;
import chez1s.htrbackend.dto.response.BlogPostSummaryResponse;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import chez1s.htrbackend.service.StorageService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class PostServiceTest {

    @Mock PostRepository postRepository;
    @Mock PostCommentRepository postCommentRepository;
    @Mock PostLikeRepository postLikeRepository;
    @Mock RoomRepository roomRepository;
    @Mock PropertyRepository propertyRepository;
    @Mock UserRepository userRepository;
    @Mock PropertyService propertyService;
    @Mock StorageService storageService;

    @InjectMocks PostService postService;

    @Test
    void listPublishedIncludesLiveVacancyCounts() {
        UUID propertyId = UUID.randomUUID();
        Property property = Property.builder().id(propertyId).name("Nhà trọ Xanh").address("12 Lê Lợi").build();
        Post post = Post.builder().id(UUID.randomUUID()).property(property).title("Phòng trọ đẹp")
                .slug("phong-tro-dep").coverImageUrl("http://img/1.jpg").published(true).build();
        when(postRepository.findByPublishedTrueOrderByPublishedAtDesc()).thenReturn(List.of(post));
        when(roomRepository.countByPropertyIdAndStatus(propertyId, RoomStatus.EMPTY)).thenReturn(1L);
        when(roomRepository.countByPropertyIdAndStatus(propertyId, RoomStatus.RENTED)).thenReturn(3L);

        List<BlogPostSummaryResponse> result = postService.listPublished();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).emptyRoomCount()).isEqualTo(1L);
        assertThat(result.get(0).totalRoomCount()).isEqualTo(4L);
        assertThat(result.get(0).propertyName()).isEqualTo("Nhà trọ Xanh");
    }

    @Test
    void getPublishedBySlugReturnsDetail() {
        UUID propertyId = UUID.randomUUID();
        Property property = Property.builder().id(propertyId).name("Nhà trọ Xanh").address("12 Lê Lợi").build();
        Post post = Post.builder().id(UUID.randomUUID()).property(property).title("Phòng trọ đẹp")
                .slug("phong-tro-dep").content("<p>Nội dung</p>").published(true).build();
        when(postRepository.findBySlugAndPublishedTrue("phong-tro-dep")).thenReturn(Optional.of(post));
        when(postLikeRepository.countByPostId(post.getId())).thenReturn(7L);

        BlogPostDetailResponse result = postService.getPublishedBySlug("phong-tro-dep");

        assertThat(result.content()).isEqualTo("<p>Nội dung</p>");
        assertThat(result.likeCount()).isEqualTo(7L);
    }

    @Test
    void getPublishedBySlugThrowsWhenMissing() {
        when(postRepository.findBySlugAndPublishedTrue("missing")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> postService.getPublishedBySlug("missing"))
                .isInstanceOf(ResourceNotFoundException.class);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest`
Expected: FAIL to compile — `PostService`/`BlogPostSummaryResponse`/`BlogPostDetailResponse` don't exist yet

- [ ] **Step 3: Create the response DTOs**

```java
package chez1s.htrbackend.dto.response;

import java.time.LocalDateTime;
import java.util.UUID;

public record BlogPostSummaryResponse(
        UUID id,
        String slug,
        String title,
        String coverImageUrl,
        UUID propertyId,
        String propertyName,
        String propertyAddress,
        long emptyRoomCount,
        long totalRoomCount,
        LocalDateTime publishedAt
) {
}
```

```java
package chez1s.htrbackend.dto.response;

import java.time.LocalDateTime;
import java.util.UUID;

public record BlogPostDetailResponse(
        UUID id,
        String slug,
        String title,
        String content,
        String coverImageUrl,
        UUID propertyId,
        String propertyName,
        String propertyAddress,
        LocalDateTime publishedAt,
        long likeCount
) {
}
```

- [ ] **Step 4: Create `PostService` with the two read methods**

```java
package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Post;
import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.*;
import chez1s.htrbackend.dto.response.BlogPostDetailResponse;
import chez1s.htrbackend.dto.response.BlogPostSummaryResponse;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PostService {

    private final PostRepository postRepository;
    private final PostCommentRepository postCommentRepository;
    private final PostLikeRepository postLikeRepository;
    private final RoomRepository roomRepository;
    private final PropertyRepository propertyRepository;
    private final UserRepository userRepository;
    private final PropertyService propertyService;
    private final StorageService storageService;

    @Transactional(readOnly = true)
    public List<BlogPostSummaryResponse> listPublished() {
        return postRepository.findByPublishedTrueOrderByPublishedAtDesc().stream()
                .map(this::toSummary)
                .toList();
    }

    @Transactional(readOnly = true)
    public BlogPostDetailResponse getPublishedBySlug(String slug) {
        Post post = postRepository.findBySlugAndPublishedTrue(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Post", slug));
        return toDetail(post);
    }

    private BlogPostSummaryResponse toSummary(Post post) {
        Property property = post.getProperty();
        long empty = roomRepository.countByPropertyIdAndStatus(property.getId(), RoomStatus.EMPTY);
        long rented = roomRepository.countByPropertyIdAndStatus(property.getId(), RoomStatus.RENTED);
        long maintenance = roomRepository.countByPropertyIdAndStatus(property.getId(), RoomStatus.MAINTENANCE);
        return new BlogPostSummaryResponse(
                post.getId(), post.getSlug(), post.getTitle(), post.getCoverImageUrl(),
                property.getId(), property.getName(), property.getAddress(),
                empty, empty + rented + maintenance, post.getPublishedAt()
        );
    }

    private BlogPostDetailResponse toDetail(Post post) {
        Property property = post.getProperty();
        long likeCount = postLikeRepository.countByPostId(post.getId());
        return new BlogPostDetailResponse(
                post.getId(), post.getSlug(), post.getTitle(), post.getContent(), post.getCoverImageUrl(),
                property.getId(), property.getName(), property.getAddress(), post.getPublishedAt(), likeCount
        );
    }
}
```

- [ ] **Step 5: Run the service test to verify it passes**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest`
Expected: PASS

- [ ] **Step 6: Write the failing controller test**

```java
package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.response.BlogPostDetailResponse;
import chez1s.htrbackend.dto.response.BlogPostSummaryResponse;
import chez1s.htrbackend.service.PostService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PublicBlogControllerTest {

    @Mock PostService postService;

    private PublicBlogController controller;

    @BeforeEach
    void setup() {
        controller = new PublicBlogController(postService);
    }

    @Test
    void listReturnsAllPublishedPosts() {
        BlogPostSummaryResponse summary = new BlogPostSummaryResponse(
                UUID.randomUUID(), "phong-tro-dep", "Phòng trọ đẹp", null,
                UUID.randomUUID(), "Nhà trọ Xanh", "12 Lê Lợi", 1L, 4L, null);
        when(postService.listPublished()).thenReturn(List.of(summary));

        ResponseEntity<List<BlogPostSummaryResponse>> result = controller.list();

        assertThat(result.getBody()).containsExactly(summary);
    }

    @Test
    void getBySlugDelegatesToService() {
        BlogPostDetailResponse detail = new BlogPostDetailResponse(
                UUID.randomUUID(), "phong-tro-dep", "Phòng trọ đẹp", "<p>Nội dung</p>", null,
                UUID.randomUUID(), "Nhà trọ Xanh", "12 Lê Lợi", null, 0L);
        when(postService.getPublishedBySlug("phong-tro-dep")).thenReturn(detail);

        ResponseEntity<BlogPostDetailResponse> result = controller.getBySlug("phong-tro-dep");

        assertThat(result.getBody()).isEqualTo(detail);
    }
}
```

- [ ] **Step 7: Run the controller test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=PublicBlogControllerTest`
Expected: FAIL to compile — `PublicBlogController` doesn't exist yet

- [ ] **Step 8: Create `PublicBlogController` (list + detail only — comments/like added in Tasks 9–11)**

```java
package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.response.BlogPostDetailResponse;
import chez1s.htrbackend.dto.response.BlogPostSummaryResponse;
import chez1s.htrbackend.service.PostService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/public/blog")
@RequiredArgsConstructor
public class PublicBlogController {

    private final PostService postService;

    @GetMapping("/posts")
    public ResponseEntity<List<BlogPostSummaryResponse>> list() {
        return ResponseEntity.ok(postService.listPublished());
    }

    @GetMapping("/posts/{slug}")
    public ResponseEntity<BlogPostDetailResponse> getBySlug(@PathVariable String slug) {
        return ResponseEntity.ok(postService.getPublishedBySlug(slug));
    }
}
```

- [ ] **Step 9: Run both tests to verify they pass**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest,PublicBlogControllerTest`
Expected: PASS

- [ ] **Step 10: Commit**

```bash
git add htr-backend/src/main/java/chez1s/htrbackend/dto/response/BlogPostSummaryResponse.java htr-backend/src/main/java/chez1s/htrbackend/dto/response/BlogPostDetailResponse.java htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java htr-backend/src/main/java/chez1s/htrbackend/controller/PublicBlogController.java htr-backend/src/test/java/chez1s/htrbackend/service/PostServiceTest.java htr-backend/src/test/java/chez1s/htrbackend/controller/PublicBlogControllerTest.java
git commit -m "feat(blog): add public post list and detail endpoints"
```

### Task 9: `GET /api/public/blog/posts/{slug}/comments`

**Files:**
- Create: `htr-backend/src/main/java/chez1s/htrbackend/dto/response/PostCommentResponse.java`
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java`
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/controller/PublicBlogController.java`
- Test: extend `htr-backend/src/test/java/chez1s/htrbackend/service/PostServiceTest.java`
- Test: extend `htr-backend/src/test/java/chez1s/htrbackend/controller/PublicBlogControllerTest.java`

**Interfaces:**
- Consumes: `PostCommentRepository.findByPostIdOrderByCreatedAtAsc(UUID)` (Task 4), `postRepository.findBySlugAndPublishedTrue` (already used by Task 8's `getPublishedBySlug` — this method needs the `Post` entity, not the DTO, so it resolves the post itself rather than calling `getPublishedBySlug`).
- Produces: `PostCommentResponse.from(PostComment)`, `PostService.listComments(String slug)` → `List<PostCommentResponse>` — consumed here and by Task 10 (`addComment` returns the same DTO for the newly-created comment).

- [ ] **Step 1: Add the failing test to `PostServiceTest`**

```java
// add to PostServiceTest.java
@Test
void listCommentsReturnsInChronologicalOrder() {
    UUID postId = UUID.randomUUID();
    Post post = Post.builder().id(postId).published(true).build();
    User commenter = User.builder().id(UUID.randomUUID()).fullName("Khách A").build();
    PostComment comment = PostComment.builder().id(UUID.randomUUID()).post(post).user(commenter).content("Đẹp quá").build();
    when(postRepository.findBySlugAndPublishedTrue("phong-tro-dep")).thenReturn(Optional.of(post));
    when(postCommentRepository.findByPostIdOrderByCreatedAtAsc(postId)).thenReturn(List.of(comment));

    List<PostCommentResponse> result = postService.listComments("phong-tro-dep");

    assertThat(result).hasSize(1);
    assertThat(result.get(0).content()).isEqualTo("Đẹp quá");
    assertThat(result.get(0).userName()).isEqualTo("Khách A");
}
```

Add the matching imports (`chez1s.htrbackend.domain.entity.PostComment`, `chez1s.htrbackend.domain.entity.User`, `chez1s.htrbackend.dto.response.PostCommentResponse`) to the top of `PostServiceTest.java`.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest#listCommentsReturnsInChronologicalOrder`
Expected: FAIL to compile — `PostCommentResponse`/`PostService.listComments` don't exist yet

- [ ] **Step 3: Create `PostCommentResponse`**

```java
package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.PostComment;

import java.time.LocalDateTime;
import java.util.UUID;

public record PostCommentResponse(
        UUID id,
        String content,
        UUID userId,
        String userName,
        LocalDateTime createdAt
) {
    public static PostCommentResponse from(PostComment comment) {
        return new PostCommentResponse(
                comment.getId(),
                comment.getContent(),
                comment.getUser().getId(),
                comment.getUser().getFullName(),
                comment.getCreatedAt()
        );
    }
}
```

- [ ] **Step 4: Add `listComments` to `PostService`**

```java
// PostService.java — add import chez1s.htrbackend.dto.response.PostCommentResponse;
@Transactional(readOnly = true)
public List<PostCommentResponse> listComments(String slug) {
    Post post = postRepository.findBySlugAndPublishedTrue(slug)
            .orElseThrow(() -> new ResourceNotFoundException("Post", slug));
    return postCommentRepository.findByPostIdOrderByCreatedAtAsc(post.getId()).stream()
            .map(PostCommentResponse::from)
            .toList();
}
```

- [ ] **Step 5: Run the service test to verify it passes**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest`
Expected: PASS

- [ ] **Step 6: Add the failing test to `PublicBlogControllerTest`**

```java
// add to PublicBlogControllerTest.java
@Test
void listCommentsDelegatesToService() {
    PostCommentResponse comment = new PostCommentResponse(UUID.randomUUID(), "Đẹp quá", UUID.randomUUID(), "Khách A", null);
    when(postService.listComments("phong-tro-dep")).thenReturn(List.of(comment));

    ResponseEntity<List<PostCommentResponse>> result = controller.listComments("phong-tro-dep");

    assertThat(result.getBody()).containsExactly(comment);
}
```

Add `import chez1s.htrbackend.dto.response.PostCommentResponse;` to the top of the test file.

- [ ] **Step 7: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=PublicBlogControllerTest#listCommentsDelegatesToService`
Expected: FAIL to compile — `controller.listComments` doesn't exist yet

- [ ] **Step 8: Add the endpoint to `PublicBlogController`**

```java
// PublicBlogController.java — add import chez1s.htrbackend.dto.response.PostCommentResponse;
@GetMapping("/posts/{slug}/comments")
public ResponseEntity<List<PostCommentResponse>> listComments(@PathVariable String slug) {
    return ResponseEntity.ok(postService.listComments(slug));
}
```

- [ ] **Step 9: Run both tests to verify they pass**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest,PublicBlogControllerTest`
Expected: PASS

- [ ] **Step 10: Commit**

```bash
git add htr-backend/src/main/java/chez1s/htrbackend/dto/response/PostCommentResponse.java htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java htr-backend/src/main/java/chez1s/htrbackend/controller/PublicBlogController.java htr-backend/src/test/java/chez1s/htrbackend/service/PostServiceTest.java htr-backend/src/test/java/chez1s/htrbackend/controller/PublicBlogControllerTest.java
git commit -m "feat(blog): add public comment listing endpoint"
```

---

## Phase 4 — Backend: authenticated comment and like

### Task 10: `POST /api/public/blog/posts/{slug}/comments`

**Files:**
- Create: `htr-backend/src/main/java/chez1s/htrbackend/dto/request/CreatePostCommentRequest.java`
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java`
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/controller/PublicBlogController.java`
- Test: extend `PostServiceTest.java`, `PublicBlogControllerTest.java`

**Interfaces:**
- Consumes: `PostCommentRepository.save(PostComment)`, `UserRepository.findById(UUID)`.
- Produces: `PostService.addComment(String slug, UUID userId, String content)` → `PostCommentResponse` (throws `ResourceNotFoundException` if the post or user doesn't exist).

- [ ] **Step 1: Add the failing test to `PostServiceTest`**

```java
// add to PostServiceTest.java
@Test
void addCommentSavesAndReturnsIt() {
    UUID postId = UUID.randomUUID();
    UUID userId = UUID.randomUUID();
    Post post = Post.builder().id(postId).published(true).build();
    User user = User.builder().id(userId).fullName("Khách A").build();
    when(postRepository.findBySlugAndPublishedTrue("phong-tro-dep")).thenReturn(Optional.of(post));
    when(userRepository.findById(userId)).thenReturn(Optional.of(user));
    when(postCommentRepository.save(org.mockito.ArgumentMatchers.any(PostComment.class)))
            .thenAnswer(inv -> inv.getArgument(0));

    PostCommentResponse result = postService.addComment("phong-tro-dep", userId, "Rất hài lòng");

    assertThat(result.content()).isEqualTo("Rất hài lòng");
    assertThat(result.userName()).isEqualTo("Khách A");
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest#addCommentSavesAndReturnsIt`
Expected: FAIL to compile — `PostService.addComment` doesn't exist yet

- [ ] **Step 3: Create `CreatePostCommentRequest`**

```java
package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CreatePostCommentRequest {

    @NotBlank
    private String content;
}
```

- [ ] **Step 4: Add `addComment` to `PostService`**

```java
// PostService.java — add import chez1s.htrbackend.domain.entity.PostComment; and import chez1s.htrbackend.domain.entity.User;
@Transactional
public PostCommentResponse addComment(String slug, java.util.UUID userId, String content) {
    Post post = postRepository.findBySlugAndPublishedTrue(slug)
            .orElseThrow(() -> new ResourceNotFoundException("Post", slug));
    User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User", userId));
    PostComment comment = PostComment.builder()
            .post(post)
            .user(user)
            .content(content)
            .build();
    return PostCommentResponse.from(postCommentRepository.save(comment));
}
```

- [ ] **Step 5: Run the service test to verify it passes**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest`
Expected: PASS

- [ ] **Step 6: Add the failing test to `PublicBlogControllerTest`**

```java
// add to PublicBlogControllerTest.java
@Test
void addCommentReturns201WithCreatedComment() {
    UUID userId = UUID.randomUUID();
    Authentication auth = new UsernamePasswordAuthenticationToken(userId, null, List.of());
    CreatePostCommentRequest req = new CreatePostCommentRequest();
    req.setContent("Rất hài lòng");
    PostCommentResponse created = new PostCommentResponse(UUID.randomUUID(), "Rất hài lòng", userId, "Khách A", null);
    when(postService.addComment("phong-tro-dep", userId, "Rất hài lòng")).thenReturn(created);

    ResponseEntity<PostCommentResponse> result = controller.addComment(auth, "phong-tro-dep", req);

    assertThat(result.getStatusCode()).isEqualTo(HttpStatus.CREATED);
    assertThat(result.getBody()).isEqualTo(created);
}
```

Add imports to the test file: `chez1s.htrbackend.dto.request.CreatePostCommentRequest`, `org.springframework.http.HttpStatus`, `org.springframework.security.authentication.UsernamePasswordAuthenticationToken`, `org.springframework.security.core.Authentication`, `java.util.List`.

- [ ] **Step 7: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=PublicBlogControllerTest#addCommentReturns201WithCreatedComment`
Expected: FAIL to compile — `controller.addComment` doesn't exist yet

- [ ] **Step 8: Add the endpoint to `PublicBlogController`**

```java
// PublicBlogController.java — add imports: jakarta.validation.Valid, chez1s.htrbackend.dto.request.CreatePostCommentRequest,
// org.springframework.http.HttpStatus, org.springframework.security.access.prepost.PreAuthorize,
// org.springframework.security.core.Authentication, java.util.UUID
@PostMapping("/posts/{slug}/comments")
@PreAuthorize("isAuthenticated()")
public ResponseEntity<PostCommentResponse> addComment(Authentication auth, @PathVariable String slug,
                                                       @Valid @RequestBody CreatePostCommentRequest req) {
    UUID userId = (UUID) auth.getPrincipal();
    PostCommentResponse comment = postService.addComment(slug, userId, req.getContent());
    return ResponseEntity.status(HttpStatus.CREATED).body(comment);
}
```

`@PreAuthorize("isAuthenticated()")` is explicit rather than relying on the bare `.anyRequest().authenticated()` fallthrough, matching this feature's "always annotate explicitly" rule (Task 2) — it deliberately does **not** exclude `GUEST`, since comment/like are the one place `GUEST` (and every other role) should be let in.

- [ ] **Step 9: Run both tests to verify they pass**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest,PublicBlogControllerTest`
Expected: PASS

- [ ] **Step 10: Commit**

```bash
git add htr-backend/src/main/java/chez1s/htrbackend/dto/request/CreatePostCommentRequest.java htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java htr-backend/src/main/java/chez1s/htrbackend/controller/PublicBlogController.java htr-backend/src/test/java/chez1s/htrbackend/service/PostServiceTest.java htr-backend/src/test/java/chez1s/htrbackend/controller/PublicBlogControllerTest.java
git commit -m "feat(blog): allow authenticated users to comment on posts"
```

### Task 11: `POST` / `DELETE /api/public/blog/posts/{slug}/like` (toggle)

**Files:**
- Create: `htr-backend/src/main/java/chez1s/htrbackend/dto/response/LikeStatusResponse.java`
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java`
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/controller/PublicBlogController.java`
- Test: extend `PostServiceTest.java`, `PublicBlogControllerTest.java`

**Interfaces:**
- Consumes: `PostLikeRepository` (Task 5).
- Produces: `PostService.like(String slug, UUID userId)` and `PostService.unlike(String slug, UUID userId)`, both → `LikeStatusResponse(boolean liked, long likeCount)`.

- [ ] **Step 1: Add the failing tests to `PostServiceTest`**

```java
// add to PostServiceTest.java
@Test
void likeCreatesRowWhenNotAlreadyLiked() {
    UUID postId = UUID.randomUUID();
    UUID userId = UUID.randomUUID();
    Post post = Post.builder().id(postId).published(true).build();
    User user = User.builder().id(userId).build();
    when(postRepository.findBySlugAndPublishedTrue("phong-tro-dep")).thenReturn(Optional.of(post));
    when(userRepository.findById(userId)).thenReturn(Optional.of(user));
    when(postLikeRepository.existsByPostIdAndUserId(postId, userId)).thenReturn(false);
    when(postLikeRepository.countByPostId(postId)).thenReturn(1L);

    LikeStatusResponse result = postService.like("phong-tro-dep", userId);

    assertThat(result.liked()).isTrue();
    assertThat(result.likeCount()).isEqualTo(1L);
    org.mockito.Mockito.verify(postLikeRepository).save(org.mockito.ArgumentMatchers.any(PostLike.class));
}

@Test
void likeIsIdempotentWhenAlreadyLiked() {
    UUID postId = UUID.randomUUID();
    UUID userId = UUID.randomUUID();
    Post post = Post.builder().id(postId).published(true).build();
    when(postRepository.findBySlugAndPublishedTrue("phong-tro-dep")).thenReturn(Optional.of(post));
    when(userRepository.findById(userId)).thenReturn(Optional.of(User.builder().id(userId).build()));
    when(postLikeRepository.existsByPostIdAndUserId(postId, userId)).thenReturn(true);
    when(postLikeRepository.countByPostId(postId)).thenReturn(1L);

    postService.like("phong-tro-dep", userId);

    org.mockito.Mockito.verify(postLikeRepository, org.mockito.Mockito.never()).save(org.mockito.ArgumentMatchers.any(PostLike.class));
}

@Test
void unlikeDeletesTheRow() {
    UUID postId = UUID.randomUUID();
    UUID userId = UUID.randomUUID();
    Post post = Post.builder().id(postId).published(true).build();
    when(postRepository.findBySlugAndPublishedTrue("phong-tro-dep")).thenReturn(Optional.of(post));
    when(postLikeRepository.countByPostId(postId)).thenReturn(0L);

    LikeStatusResponse result = postService.unlike("phong-tro-dep", userId);

    assertThat(result.liked()).isFalse();
    org.mockito.Mockito.verify(postLikeRepository).deleteByPostIdAndUserId(postId, userId);
}
```

Add `import chez1s.htrbackend.domain.entity.PostLike;` and `import chez1s.htrbackend.dto.response.LikeStatusResponse;` to the top of the test file.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest`
Expected: FAIL to compile — `LikeStatusResponse`/`PostService.like`/`.unlike` don't exist yet

- [ ] **Step 3: Create `LikeStatusResponse`**

```java
package chez1s.htrbackend.dto.response;

public record LikeStatusResponse(boolean liked, long likeCount) {
}
```

- [ ] **Step 4: Add `like`/`unlike` to `PostService`**

```java
// PostService.java — add import chez1s.htrbackend.domain.entity.PostLike; and import chez1s.htrbackend.dto.response.LikeStatusResponse;
@Transactional
public LikeStatusResponse like(String slug, java.util.UUID userId) {
    Post post = postRepository.findBySlugAndPublishedTrue(slug)
            .orElseThrow(() -> new ResourceNotFoundException("Post", slug));
    if (!postLikeRepository.existsByPostIdAndUserId(post.getId(), userId)) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));
        postLikeRepository.save(PostLike.builder().post(post).user(user).build());
    }
    return new LikeStatusResponse(true, postLikeRepository.countByPostId(post.getId()));
}

@Transactional
public LikeStatusResponse unlike(String slug, java.util.UUID userId) {
    Post post = postRepository.findBySlugAndPublishedTrue(slug)
            .orElseThrow(() -> new ResourceNotFoundException("Post", slug));
    postLikeRepository.deleteByPostIdAndUserId(post.getId(), userId);
    return new LikeStatusResponse(false, postLikeRepository.countByPostId(post.getId()));
}
```

- [ ] **Step 5: Run the service test to verify it passes**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest`
Expected: PASS

- [ ] **Step 6: Add the failing tests to `PublicBlogControllerTest`**

```java
// add to PublicBlogControllerTest.java
@Test
void likeDelegatesToService() {
    UUID userId = UUID.randomUUID();
    Authentication auth = new UsernamePasswordAuthenticationToken(userId, null, List.of());
    LikeStatusResponse status = new LikeStatusResponse(true, 1L);
    when(postService.like("phong-tro-dep", userId)).thenReturn(status);

    ResponseEntity<LikeStatusResponse> result = controller.like(auth, "phong-tro-dep");

    assertThat(result.getBody()).isEqualTo(status);
}

@Test
void unlikeDelegatesToService() {
    UUID userId = UUID.randomUUID();
    Authentication auth = new UsernamePasswordAuthenticationToken(userId, null, List.of());
    LikeStatusResponse status = new LikeStatusResponse(false, 0L);
    when(postService.unlike("phong-tro-dep", userId)).thenReturn(status);

    ResponseEntity<LikeStatusResponse> result = controller.unlike(auth, "phong-tro-dep");

    assertThat(result.getBody()).isEqualTo(status);
}
```

Add `import chez1s.htrbackend.dto.response.LikeStatusResponse;` to the top of the test file.

- [ ] **Step 7: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=PublicBlogControllerTest`
Expected: FAIL to compile — `controller.like`/`.unlike` don't exist yet

- [ ] **Step 8: Add the endpoints to `PublicBlogController`**

```java
// PublicBlogController.java — add import chez1s.htrbackend.dto.response.LikeStatusResponse; and org.springframework.web.bind.annotation.DeleteMapping;
@PostMapping("/posts/{slug}/like")
@PreAuthorize("isAuthenticated()")
public ResponseEntity<LikeStatusResponse> like(Authentication auth, @PathVariable String slug) {
    return ResponseEntity.ok(postService.like(slug, (UUID) auth.getPrincipal()));
}

@DeleteMapping("/posts/{slug}/like")
@PreAuthorize("isAuthenticated()")
public ResponseEntity<LikeStatusResponse> unlike(Authentication auth, @PathVariable String slug) {
    return ResponseEntity.ok(postService.unlike(slug, (UUID) auth.getPrincipal()));
}
```

- [ ] **Step 9: Run both tests to verify they pass**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest,PublicBlogControllerTest`
Expected: PASS

- [ ] **Step 10: Commit**

```bash
git add htr-backend/src/main/java/chez1s/htrbackend/dto/response/LikeStatusResponse.java htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java htr-backend/src/main/java/chez1s/htrbackend/controller/PublicBlogController.java htr-backend/src/test/java/chez1s/htrbackend/service/PostServiceTest.java htr-backend/src/test/java/chez1s/htrbackend/controller/PublicBlogControllerTest.java
git commit -m "feat(blog): add like/unlike toggle for authenticated users"
```

---

## Phase 5 — Backend: admin authoring and moderation

### Task 12: `GET /api/admin/blog/posts` (every property, with post status)

**Files:**
- Create: `htr-backend/src/main/java/chez1s/htrbackend/dto/response/AdminPostSummaryResponse.java`
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java`
- Create: `htr-backend/src/main/java/chez1s/htrbackend/controller/AdminBlogController.java`
- Test: extend `PostServiceTest.java`
- Test: `htr-backend/src/test/java/chez1s/htrbackend/controller/AdminBlogControllerTest.java`

**Interfaces:**
- Consumes: `PropertyRepository.findAll()` (existing), `PostRepository.findAll()`.
- Produces: `PostService.listAllForAdmin()` → `List<AdminPostSummaryResponse>`, one row per `Property` (post fields `null`/`false` when a property has no post yet) — `AdminBlogController` is created here and extended by Tasks 13–17 with the rest of the admin surface, all under class-level `@PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN')")`.

**Note:** accessing `post.getProperty().getId()` on a `PostRepository.findAll()` result (a plain, non-`@EntityGraph` finder) does **not** trigger `LazyInitializationException` even outside a transaction — Hibernate's lazy proxy exposes its id without a DB round-trip. The method is still wrapped in `@Transactional(readOnly = true)` per this feature's global rule (belt-and-suspenders, not strictly required for this specific access pattern).

- [ ] **Step 1: Add the failing test to `PostServiceTest`**

```java
// add to PostServiceTest.java
@Test
void listAllForAdminIncludesPropertiesWithNoPostYet() {
    UUID propertyWithPostId = UUID.randomUUID();
    UUID propertyWithoutPostId = UUID.randomUUID();
    Property withPost = Property.builder().id(propertyWithPostId).name("Nhà A").build();
    Property withoutPost = Property.builder().id(propertyWithoutPostId).name("Nhà B").build();
    Post post = Post.builder().id(UUID.randomUUID()).property(withPost).title("Bài viết A")
            .slug("bai-viet-a").published(true).build();
    when(propertyRepository.findAll()).thenReturn(List.of(withPost, withoutPost));
    when(postRepository.findAll()).thenReturn(List.of(post));

    List<AdminPostSummaryResponse> result = postService.listAllForAdmin();

    assertThat(result).hasSize(2);
    AdminPostSummaryResponse rowA = result.stream().filter(r -> r.propertyId().equals(propertyWithPostId)).findFirst().orElseThrow();
    assertThat(rowA.published()).isTrue();
    assertThat(rowA.slug()).isEqualTo("bai-viet-a");
    AdminPostSummaryResponse rowB = result.stream().filter(r -> r.propertyId().equals(propertyWithoutPostId)).findFirst().orElseThrow();
    assertThat(rowB.published()).isFalse();
    assertThat(rowB.postId()).isNull();
}
```

Add `import chez1s.htrbackend.dto.response.AdminPostSummaryResponse;` to the test file.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest#listAllForAdminIncludesPropertiesWithNoPostYet`
Expected: FAIL to compile — `AdminPostSummaryResponse`/`PostService.listAllForAdmin` don't exist yet

- [ ] **Step 3: Create `AdminPostSummaryResponse`**

```java
package chez1s.htrbackend.dto.response;

import java.time.LocalDateTime;
import java.util.UUID;

public record AdminPostSummaryResponse(
        UUID propertyId,
        String propertyName,
        UUID postId,
        String title,
        String slug,
        boolean published,
        LocalDateTime updatedAt
) {
}
```

- [ ] **Step 4: Add `listAllForAdmin` to `PostService`**

```java
// PostService.java — add import chez1s.htrbackend.domain.entity.Property; and import chez1s.htrbackend.dto.response.AdminPostSummaryResponse;
// and import java.util.Map; and java.util.stream.Collectors;
@Transactional(readOnly = true)
public List<AdminPostSummaryResponse> listAllForAdmin() {
    Map<UUID, Post> postsByPropertyId = postRepository.findAll().stream()
            .collect(Collectors.toMap(post -> post.getProperty().getId(), post -> post));
    return propertyRepository.findAll().stream()
            .map(property -> {
                Post post = postsByPropertyId.get(property.getId());
                return new AdminPostSummaryResponse(
                        property.getId(),
                        property.getName(),
                        post != null ? post.getId() : null,
                        post != null ? post.getTitle() : null,
                        post != null ? post.getSlug() : null,
                        post != null && post.isPublished(),
                        post != null ? post.getUpdatedAt() : null
                );
            })
            .toList();
}
```

- [ ] **Step 5: Run the service test to verify it passes**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest`
Expected: PASS

- [ ] **Step 6: Write the failing controller test**

```java
package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.response.AdminPostSummaryResponse;
import chez1s.htrbackend.service.PostService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AdminBlogControllerTest {

    @Mock PostService postService;

    private AdminBlogController controller;

    @BeforeEach
    void setup() {
        controller = new AdminBlogController(postService);
    }

    @Test
    void listAllDelegatesToService() {
        AdminPostSummaryResponse row = new AdminPostSummaryResponse(UUID.randomUUID(), "Nhà A", null, null, null, false, null);
        when(postService.listAllForAdmin()).thenReturn(List.of(row));

        ResponseEntity<List<AdminPostSummaryResponse>> result = controller.listAll();

        assertThat(result.getBody()).containsExactly(row);
    }
}
```

- [ ] **Step 7: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=AdminBlogControllerTest`
Expected: FAIL to compile — `AdminBlogController` doesn't exist yet

- [ ] **Step 8: Create `AdminBlogController` (list only — extended by Tasks 13–17)**

```java
package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.response.AdminPostSummaryResponse;
import chez1s.htrbackend.service.PostService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/admin/blog")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN')")
public class AdminBlogController {

    private final PostService postService;

    @GetMapping("/posts")
    public ResponseEntity<List<AdminPostSummaryResponse>> listAll() {
        return ResponseEntity.ok(postService.listAllForAdmin());
    }
}
```

- [ ] **Step 9: Run both tests to verify they pass**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest,AdminBlogControllerTest`
Expected: PASS

- [ ] **Step 10: Commit**

```bash
git add htr-backend/src/main/java/chez1s/htrbackend/dto/response/AdminPostSummaryResponse.java htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java htr-backend/src/main/java/chez1s/htrbackend/controller/AdminBlogController.java htr-backend/src/test/java/chez1s/htrbackend/service/PostServiceTest.java htr-backend/src/test/java/chez1s/htrbackend/controller/AdminBlogControllerTest.java
git commit -m "feat(blog): add admin post list endpoint"
```

### Task 13: `GET` / `PUT /api/admin/blog/posts/{propertyId}`

**Files:**
- Create: `htr-backend/src/main/java/chez1s/htrbackend/dto/request/UpdatePostRequest.java`
- Create: `htr-backend/src/main/java/chez1s/htrbackend/dto/response/AdminPostDetailResponse.java`
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java`
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/controller/AdminBlogController.java`
- Test: extend `PostServiceTest.java`, `AdminBlogControllerTest.java`

**Interfaces:**
- Consumes: `PropertyService.getById(UUID)`, `RoomRepository.findByPropertyId(UUID)` (used to resolve the default cover image), `PostRepository.existsBySlug`/`.existsBySlugAndIdNot` (Task 3).
- Produces: `PostService.getForAdmin(UUID propertyId)` → `AdminPostDetailResponse` (404s if no post exists yet for that property — matching the spec's "GET/PUT ... creates it on first PUT if it doesn't exist yet", i.e. GET requires the post to already exist); `PostService.upsertPost(UUID propertyId, UpdatePostRequest, UUID authorId)` → `AdminPostDetailResponse`, creating the `Post` row on first call. Both reused unchanged by Tasks 14–16.

- [ ] **Step 1: Add the failing tests to `PostServiceTest`**

```java
// add to PostServiceTest.java
@Test
void getForAdminThrowsWhenNoPostExistsYet() {
    UUID propertyId = UUID.randomUUID();
    when(postRepository.findByPropertyId(propertyId)).thenReturn(Optional.empty());

    assertThatThrownBy(() -> postService.getForAdmin(propertyId))
            .isInstanceOf(ResourceNotFoundException.class);
}

@Test
void upsertPostCreatesOnFirstCallWithGeneratedSlug() {
    UUID propertyId = UUID.randomUUID();
    UUID authorId = UUID.randomUUID();
    Property property = Property.builder().id(propertyId).name("Nhà trọ Xanh").build();
    User author = User.builder().id(authorId).fullName("Admin A").build();
    UpdatePostRequest req = new UpdatePostRequest();
    req.setTitle("Phòng Trọ Đẹp Quận 1");
    req.setContent("<p>Nội dung</p>");
    when(postRepository.findByPropertyId(propertyId)).thenReturn(Optional.empty());
    when(propertyService.getById(propertyId)).thenReturn(property);
    when(userRepository.findById(authorId)).thenReturn(Optional.of(author));
    when(roomRepository.findByPropertyId(propertyId)).thenReturn(List.of());
    when(postRepository.existsBySlug("phong-tro-dep-quan-1")).thenReturn(false);
    when(postRepository.save(org.mockito.ArgumentMatchers.any(Post.class))).thenAnswer(inv -> inv.getArgument(0));

    AdminPostDetailResponse result = postService.upsertPost(propertyId, req, authorId);

    assertThat(result.slug()).isEqualTo("phong-tro-dep-quan-1");
    assertThat(result.title()).isEqualTo("Phòng Trọ Đẹp Quận 1");
    assertThat(result.published()).isFalse();
}

@Test
void upsertPostAppendsSuffixOnSlugCollision() {
    UUID propertyId = UUID.randomUUID();
    UUID authorId = UUID.randomUUID();
    Property property = Property.builder().id(propertyId).name("Nhà trọ Xanh").build();
    UpdatePostRequest req = new UpdatePostRequest();
    req.setTitle("Phòng Đẹp");
    when(postRepository.findByPropertyId(propertyId)).thenReturn(Optional.empty());
    when(propertyService.getById(propertyId)).thenReturn(property);
    when(userRepository.findById(authorId)).thenReturn(Optional.of(User.builder().id(authorId).build()));
    when(roomRepository.findByPropertyId(propertyId)).thenReturn(List.of());
    when(postRepository.existsBySlug("phong-dep")).thenReturn(true);
    when(postRepository.existsBySlug("phong-dep-2")).thenReturn(false);
    when(postRepository.save(org.mockito.ArgumentMatchers.any(Post.class))).thenAnswer(inv -> inv.getArgument(0));

    AdminPostDetailResponse result = postService.upsertPost(propertyId, req, authorId);

    assertThat(result.slug()).isEqualTo("phong-dep-2");
}
```

Add imports to the top of `PostServiceTest.java`: `chez1s.htrbackend.dto.request.UpdatePostRequest`, `chez1s.htrbackend.dto.response.AdminPostDetailResponse`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest`
Expected: FAIL to compile — `UpdatePostRequest`/`AdminPostDetailResponse`/`PostService.getForAdmin`/`.upsertPost` don't exist yet

- [ ] **Step 3: Create `UpdatePostRequest`**

```java
package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class UpdatePostRequest {

    @NotBlank
    private String title;

    /** Nullable — auto-generated (slugified) from the title when blank. Editable afterward. */
    private String slug;

    private String content;

    private String coverImageUrl;
}
```

- [ ] **Step 4: Create `AdminPostDetailResponse`**

```java
package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.Post;

import java.time.LocalDateTime;
import java.util.UUID;

public record AdminPostDetailResponse(
        UUID id,
        UUID propertyId,
        String propertyName,
        String title,
        String slug,
        String content,
        String coverImageUrl,
        boolean published,
        LocalDateTime publishedAt,
        UUID authorId,
        String authorName,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
    public static AdminPostDetailResponse from(Post post) {
        return new AdminPostDetailResponse(
                post.getId(),
                post.getProperty().getId(),
                post.getProperty().getName(),
                post.getTitle(),
                post.getSlug(),
                post.getContent(),
                post.getCoverImageUrl(),
                post.isPublished(),
                post.getPublishedAt(),
                post.getAuthor() != null ? post.getAuthor().getId() : null,
                post.getAuthor() != null ? post.getAuthor().getFullName() : null,
                post.getCreatedAt(),
                post.getUpdatedAt()
        );
    }
}
```

- [ ] **Step 5: Add `getForAdmin` and `upsertPost` (with slugify helpers) to `PostService`**

```java
// PostService.java — add imports:
// chez1s.htrbackend.domain.entity.Room, chez1s.htrbackend.dto.request.UpdatePostRequest,
// chez1s.htrbackend.dto.response.AdminPostDetailResponse, java.text.Normalizer, java.util.Locale
@Transactional(readOnly = true)
public AdminPostDetailResponse getForAdmin(java.util.UUID propertyId) {
    Post post = postRepository.findByPropertyId(propertyId)
            .orElseThrow(() -> new ResourceNotFoundException("Post for property", propertyId));
    return AdminPostDetailResponse.from(post);
}

@Transactional
public AdminPostDetailResponse upsertPost(java.util.UUID propertyId, UpdatePostRequest req, java.util.UUID authorId) {
    Property property = propertyService.getById(propertyId);
    Post post = postRepository.findByPropertyId(propertyId).orElseGet(() -> {
        Post created = new Post();
        created.setProperty(property);
        return created;
    });
    User author = userRepository.findById(authorId)
            .orElseThrow(() -> new ResourceNotFoundException("User", authorId));

    post.setTitle(req.getTitle());
    post.setContent(req.getContent());
    post.setCoverImageUrl(req.getCoverImageUrl() != null ? req.getCoverImageUrl() : resolveDefaultCoverImage(propertyId));
    post.setAuthor(author);

    String desiredSlug = (req.getSlug() != null && !req.getSlug().isBlank()) ? slugify(req.getSlug()) : slugify(req.getTitle());
    post.setSlug(uniqueSlug(desiredSlug, post.getId()));

    return AdminPostDetailResponse.from(postRepository.save(post));
}

private String resolveDefaultCoverImage(java.util.UUID propertyId) {
    return roomRepository.findByPropertyId(propertyId).stream()
            .flatMap(room -> room.getImages().stream())
            .findFirst()
            .orElse(null);
}

private String uniqueSlug(String base, java.util.UUID excludingPostId) {
    String candidate = base;
    int suffix = 2;
    while (excludingPostId == null
            ? postRepository.existsBySlug(candidate)
            : postRepository.existsBySlugAndIdNot(candidate, excludingPostId)) {
        candidate = base + "-" + suffix;
        suffix++;
    }
    return candidate;
}

private String slugify(String input) {
    String withoutDiacritics = Normalizer.normalize(input, Normalizer.Form.NFD)
            .replaceAll("\\p{InCombiningDiacriticalMarks}+", "")
            .replace('đ', 'd').replace('Đ', 'D');
    return withoutDiacritics.toLowerCase(Locale.ROOT)
            .replaceAll("[^a-z0-9\\s-]", "")
            .trim()
            .replaceAll("\\s+", "-")
            .replaceAll("-+", "-");
}
```

**Note on `uniqueSlug(base, excludingPostId)`:** on the create path `post.getId()` is `null` (the entity hasn't been persisted yet, so `@GeneratedValue` hasn't assigned one), which is why the check branches on `existsBySlug` vs `existsBySlugAndIdNot` rather than always using the latter — `existsBySlugAndIdNot(candidate, null)` would throw a Postgres `NOT (id <> NULL)` always-false-comparison bug if called with a null id.

- [ ] **Step 6: Run the service tests to verify they pass**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest`
Expected: PASS

- [ ] **Step 7: Add the failing tests to `AdminBlogControllerTest`**

```java
// add to AdminBlogControllerTest.java
@Test
void getByPropertyIdDelegatesToService() {
    UUID propertyId = UUID.randomUUID();
    AdminPostDetailResponse detail = new AdminPostDetailResponse(UUID.randomUUID(), propertyId, "Nhà A",
            "Bài viết A", "bai-viet-a", "<p>...</p>", null, false, null, null, null, null, null);
    when(postService.getForAdmin(propertyId)).thenReturn(detail);

    ResponseEntity<AdminPostDetailResponse> result = controller.getByPropertyId(propertyId);

    assertThat(result.getBody()).isEqualTo(detail);
}

@Test
void updateDelegatesToServiceWithAuthorFromAuthentication() {
    UUID propertyId = UUID.randomUUID();
    UUID authorId = UUID.randomUUID();
    Authentication auth = new UsernamePasswordAuthenticationToken(authorId, null, List.of());
    UpdatePostRequest req = new UpdatePostRequest();
    req.setTitle("Bài viết A");
    AdminPostDetailResponse detail = new AdminPostDetailResponse(UUID.randomUUID(), propertyId, "Nhà A",
            "Bài viết A", "bai-viet-a", null, null, false, null, authorId, "Admin A", null, null);
    when(postService.upsertPost(propertyId, req, authorId)).thenReturn(detail);

    ResponseEntity<AdminPostDetailResponse> result = controller.update(auth, propertyId, req);

    assertThat(result.getBody()).isEqualTo(detail);
}
```

Add imports to `AdminBlogControllerTest.java`: `chez1s.htrbackend.dto.request.UpdatePostRequest`, `chez1s.htrbackend.dto.response.AdminPostDetailResponse`, `org.springframework.security.authentication.UsernamePasswordAuthenticationToken`, `org.springframework.security.core.Authentication`, `java.util.List`.

- [ ] **Step 8: Run tests to verify they fail**

Run: `cd htr-backend && ./mvnw test -Dtest=AdminBlogControllerTest`
Expected: FAIL to compile — `controller.getByPropertyId`/`.update` don't exist yet

- [ ] **Step 9: Add the endpoints to `AdminBlogController`**

```java
// AdminBlogController.java — add imports: jakarta.validation.Valid,
// chez1s.htrbackend.dto.request.UpdatePostRequest, chez1s.htrbackend.dto.response.AdminPostDetailResponse,
// org.springframework.security.core.Authentication, org.springframework.web.bind.annotation.PathVariable,
// org.springframework.web.bind.annotation.PutMapping, org.springframework.web.bind.annotation.RequestBody, java.util.UUID
@GetMapping("/posts/{propertyId}")
public ResponseEntity<AdminPostDetailResponse> getByPropertyId(@PathVariable UUID propertyId) {
    return ResponseEntity.ok(postService.getForAdmin(propertyId));
}

@PutMapping("/posts/{propertyId}")
public ResponseEntity<AdminPostDetailResponse> update(Authentication auth, @PathVariable UUID propertyId,
                                                       @Valid @RequestBody UpdatePostRequest req) {
    UUID authorId = (UUID) auth.getPrincipal();
    return ResponseEntity.ok(postService.upsertPost(propertyId, req, authorId));
}
```

- [ ] **Step 10: Run both tests to verify they pass**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest,AdminBlogControllerTest`
Expected: PASS

- [ ] **Step 11: Commit**

```bash
git add htr-backend/src/main/java/chez1s/htrbackend/dto/request/UpdatePostRequest.java htr-backend/src/main/java/chez1s/htrbackend/dto/response/AdminPostDetailResponse.java htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java htr-backend/src/main/java/chez1s/htrbackend/controller/AdminBlogController.java htr-backend/src/test/java/chez1s/htrbackend/service/PostServiceTest.java htr-backend/src/test/java/chez1s/htrbackend/controller/AdminBlogControllerTest.java
git commit -m "feat(blog): add admin post read/upsert endpoints"
```

### Task 14: `POST /api/admin/blog/posts/{propertyId}/draft` (auto-draft generator)

**Files:**
- Create: `htr-backend/src/main/java/chez1s/htrbackend/dto/response/GeneratedDraftResponse.java`
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java`
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/controller/AdminBlogController.java`
- Test: extend `PostServiceTest.java`, `AdminBlogControllerTest.java`

**Context:** per spec §4.2, this is "a one-shot template fill, not a live binding" — it returns generated `title`/`content`/`coverImageUrl` for the admin's editor to load, but does **not** persist a `Post` row itself; the admin's subsequent `PUT` (Task 13) is what actually creates/saves it. This keeps a single create path (`upsertPost`) instead of two.

**Interfaces:**
- Consumes: `RoomRepository.findByPropertyId(UUID)`, `Room.getDirection()`/`.getDescription()`/`.getStatus()`/`.getImages()`.
- Produces: `PostService.generateDraft(UUID propertyId)` → `GeneratedDraftResponse(String title, String content, String coverImageUrl)`.

- [ ] **Step 1: Add the failing test to `PostServiceTest`**

```java
// add to PostServiceTest.java
@Test
void generateDraftBuildsHtmlFromPropertyAndRooms() {
    UUID propertyId = UUID.randomUUID();
    Property property = Property.builder().id(propertyId).name("Nhà trọ Xanh").address("12 Lê Lợi").build();
    Room room1 = Room.builder().roomNumber("A1").status(chez1s.htrbackend.domain.enums.RoomStatus.EMPTY)
            .direction(chez1s.htrbackend.domain.enums.RoomDirection.NORTH)
            .images(new java.util.ArrayList<>(List.of("http://img/a1.jpg"))).build();
    Room room2 = Room.builder().roomNumber("A2").status(chez1s.htrbackend.domain.enums.RoomStatus.RENTED)
            .images(new java.util.ArrayList<>()).build();
    when(propertyService.getById(propertyId)).thenReturn(property);
    when(roomRepository.findByPropertyId(propertyId)).thenReturn(List.of(room1, room2));

    GeneratedDraftResponse result = postService.generateDraft(propertyId);

    assertThat(result.title()).contains("Nhà trọ Xanh");
    assertThat(result.content()).contains("A1").contains("Bắc").contains("12 Lê Lợi").contains("1/2 phòng còn trống");
    assertThat(result.coverImageUrl()).isEqualTo("http://img/a1.jpg");
}
```

Add `import chez1s.htrbackend.domain.entity.Room;`, `import chez1s.htrbackend.dto.response.GeneratedDraftResponse;` to the top of the test file.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest#generateDraftBuildsHtmlFromPropertyAndRooms`
Expected: FAIL to compile — `GeneratedDraftResponse`/`PostService.generateDraft` don't exist yet

- [ ] **Step 3: Create `GeneratedDraftResponse`**

```java
package chez1s.htrbackend.dto.response;

public record GeneratedDraftResponse(String title, String content, String coverImageUrl) {
}
```

- [ ] **Step 4: Add `generateDraft` (and its HTML-building/direction-label helpers) to `PostService`**

```java
// PostService.java — add import chez1s.htrbackend.domain.enums.RoomStatus; (already imported) and
// import chez1s.htrbackend.dto.response.GeneratedDraftResponse;
@Transactional(readOnly = true)
public GeneratedDraftResponse generateDraft(java.util.UUID propertyId) {
    Property property = propertyService.getById(propertyId);
    List<Room> rooms = roomRepository.findByPropertyId(propertyId);
    long emptyCount = rooms.stream().filter(r -> r.getStatus() == RoomStatus.EMPTY).count();

    StringBuilder html = new StringBuilder();
    html.append("<h2>").append(escapeHtml(property.getName())).append("</h2>");
    html.append("<p>").append(escapeHtml(property.getAddress())).append("</p>");
    if (property.getDescription() != null && !property.getDescription().isBlank()) {
        html.append("<p>").append(escapeHtml(property.getDescription())).append("</p>");
    }
    html.append("<p><strong>").append(emptyCount).append("/").append(rooms.size()).append(" phòng còn trống</strong></p>");
    html.append("<h3>Danh sách phòng</h3><ul>");
    for (Room room : rooms) {
        html.append("<li>Phòng ").append(escapeHtml(room.getRoomNumber()));
        if (room.getDirection() != null) {
            html.append(" — hướng ").append(directionLabel(room.getDirection()));
        }
        if (room.getDescription() != null && !room.getDescription().isBlank()) {
            html.append(": ").append(escapeHtml(room.getDescription()));
        }
        html.append("</li>");
    }
    html.append("</ul>");

    String coverImageUrl = rooms.stream()
            .flatMap(room -> room.getImages().stream())
            .findFirst()
            .orElse(null);

    return new GeneratedDraftResponse(property.getName() + " - Cho thuê phòng trọ", html.toString(), coverImageUrl);
}

private String escapeHtml(String input) {
    return input == null ? "" : input
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;");
}

private String directionLabel(chez1s.htrbackend.domain.enums.RoomDirection direction) {
    return switch (direction) {
        case NORTH -> "Bắc";
        case SOUTH -> "Nam";
        case EAST -> "Đông";
        case WEST -> "Tây";
        case NORTHEAST -> "Đông Bắc";
        case NORTHWEST -> "Tây Bắc";
        case SOUTHEAST -> "Đông Nam";
        case SOUTHWEST -> "Tây Nam";
    };
}
```

This mirrors the frontend's `directionLabel` map in `lib/utils.ts` exactly (same 8 Vietnamese labels) so the generated draft reads consistently with the rest of the app.

- [ ] **Step 5: Run the service test to verify it passes**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest`
Expected: PASS

- [ ] **Step 6: Add the failing test to `AdminBlogControllerTest`**

```java
// add to AdminBlogControllerTest.java
@Test
void generateDraftDelegatesToService() {
    UUID propertyId = UUID.randomUUID();
    GeneratedDraftResponse draft = new GeneratedDraftResponse("Nhà trọ Xanh - Cho thuê phòng trọ", "<h2>...</h2>", null);
    when(postService.generateDraft(propertyId)).thenReturn(draft);

    ResponseEntity<GeneratedDraftResponse> result = controller.generateDraft(propertyId);

    assertThat(result.getBody()).isEqualTo(draft);
}
```

Add `import chez1s.htrbackend.dto.response.GeneratedDraftResponse;` to the test file.

- [ ] **Step 7: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=AdminBlogControllerTest#generateDraftDelegatesToService`
Expected: FAIL to compile — `controller.generateDraft` doesn't exist yet

- [ ] **Step 8: Add the endpoint to `AdminBlogController`**

```java
// AdminBlogController.java — add import chez1s.htrbackend.dto.response.GeneratedDraftResponse; and org.springframework.web.bind.annotation.PostMapping;
@PostMapping("/posts/{propertyId}/draft")
public ResponseEntity<GeneratedDraftResponse> generateDraft(@PathVariable UUID propertyId) {
    return ResponseEntity.ok(postService.generateDraft(propertyId));
}
```

- [ ] **Step 9: Run both tests to verify they pass**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest,AdminBlogControllerTest`
Expected: PASS

- [ ] **Step 10: Commit**

```bash
git add htr-backend/src/main/java/chez1s/htrbackend/dto/response/GeneratedDraftResponse.java htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java htr-backend/src/main/java/chez1s/htrbackend/controller/AdminBlogController.java htr-backend/src/test/java/chez1s/htrbackend/service/PostServiceTest.java htr-backend/src/test/java/chez1s/htrbackend/controller/AdminBlogControllerTest.java
git commit -m "feat(blog): add auto-draft generator endpoint"
```

### Task 15: `POST /api/admin/blog/posts/{propertyId}/cover-image`

**Files:**
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java`
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/controller/AdminBlogController.java`
- Test: extend `PostServiceTest.java`, `AdminBlogControllerTest.java`

**Interfaces:**
- Consumes: `StorageService.upload(String folder, MultipartFile file)` (existing, same pattern as `RoomController`'s `"rooms/" + id` prefix).
- Produces: `PostService.uploadCoverImage(UUID propertyId, MultipartFile file)` → `AdminPostDetailResponse` with the new `coverImageUrl` set (throws `ResourceNotFoundException` if no post exists yet — the admin must save the post via `PUT` first, matching Task 13's create-on-PUT rule).

- [ ] **Step 1: Add the failing test to `PostServiceTest`**

```java
// add to PostServiceTest.java
@Test
void uploadCoverImageStoresReturnedUrlOnPost() {
    UUID propertyId = UUID.randomUUID();
    Post post = Post.builder().id(UUID.randomUUID()).property(Property.builder().id(propertyId).name("Nhà A").build()).build();
    org.springframework.web.multipart.MultipartFile file = new org.springframework.mock.web.MockMultipartFile(
            "file", "cover.jpg", "image/jpeg", new byte[]{1, 2, 3});
    when(postRepository.findByPropertyId(propertyId)).thenReturn(Optional.of(post));
    when(storageService.upload("blog/" + propertyId, file)).thenReturn("http://storage/blog/cover.jpg");
    when(postRepository.save(post)).thenReturn(post);

    AdminPostDetailResponse result = postService.uploadCoverImage(propertyId, file);

    assertThat(result.coverImageUrl()).isEqualTo("http://storage/blog/cover.jpg");
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest#uploadCoverImageStoresReturnedUrlOnPost`
Expected: FAIL to compile — `PostService.uploadCoverImage` doesn't exist yet

- [ ] **Step 3: Add `uploadCoverImage` to `PostService`**

```java
// PostService.java — add import org.springframework.web.multipart.MultipartFile;
@Transactional
public AdminPostDetailResponse uploadCoverImage(java.util.UUID propertyId, MultipartFile file) {
    Post post = postRepository.findByPropertyId(propertyId)
            .orElseThrow(() -> new ResourceNotFoundException("Post for property", propertyId));
    post.setCoverImageUrl(storageService.upload("blog/" + propertyId, file));
    return AdminPostDetailResponse.from(postRepository.save(post));
}
```

- [ ] **Step 4: Run the service test to verify it passes**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest`
Expected: PASS

- [ ] **Step 5: Add the failing test to `AdminBlogControllerTest`**

```java
// add to AdminBlogControllerTest.java
@Test
void uploadCoverImageDelegatesToService() {
    UUID propertyId = UUID.randomUUID();
    org.springframework.web.multipart.MultipartFile file = new org.springframework.mock.web.MockMultipartFile(
            "file", "cover.jpg", "image/jpeg", new byte[]{1, 2, 3});
    AdminPostDetailResponse detail = new AdminPostDetailResponse(UUID.randomUUID(), propertyId, "Nhà A",
            "Bài viết A", "bai-viet-a", null, "http://storage/blog/cover.jpg", false, null, null, null, null, null);
    when(postService.uploadCoverImage(propertyId, file)).thenReturn(detail);

    ResponseEntity<AdminPostDetailResponse> result = controller.uploadCoverImage(propertyId, file);

    assertThat(result.getBody()).isEqualTo(detail);
}
```

- [ ] **Step 6: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=AdminBlogControllerTest#uploadCoverImageDelegatesToService`
Expected: FAIL to compile — `controller.uploadCoverImage` doesn't exist yet

- [ ] **Step 7: Add the endpoint to `AdminBlogController`**

```java
// AdminBlogController.java — add imports: org.springframework.web.bind.annotation.RequestParam, org.springframework.web.multipart.MultipartFile
@PostMapping("/posts/{propertyId}/cover-image")
public ResponseEntity<AdminPostDetailResponse> uploadCoverImage(@PathVariable UUID propertyId,
                                                                 @RequestParam("file") MultipartFile file) {
    return ResponseEntity.ok(postService.uploadCoverImage(propertyId, file));
}
```

- [ ] **Step 8: Run both tests to verify they pass**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest,AdminBlogControllerTest`
Expected: PASS

- [ ] **Step 9: Commit**

```bash
git add htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java htr-backend/src/main/java/chez1s/htrbackend/controller/AdminBlogController.java htr-backend/src/test/java/chez1s/htrbackend/service/PostServiceTest.java htr-backend/src/test/java/chez1s/htrbackend/controller/AdminBlogControllerTest.java
git commit -m "feat(blog): add admin cover image upload endpoint"
```

### Task 16: `POST /api/admin/blog/posts/{propertyId}/publish` / `.../unpublish`

**Files:**
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java`
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/controller/AdminBlogController.java`
- Test: extend `PostServiceTest.java`, `AdminBlogControllerTest.java`

**Interfaces:**
- Produces: `PostService.publish(UUID propertyId)` (sets `published=true` and stamps `publishedAt` only the first time — idempotent on `publishedAt`), `PostService.unpublish(UUID propertyId)` (sets `published=false`, leaves `publishedAt` untouched so "first published" history isn't lost on a republish).

- [ ] **Step 1: Add the failing tests to `PostServiceTest`**

```java
// add to PostServiceTest.java
@Test
void publishSetsPublishedAtOnlyOnFirstPublish() {
    UUID propertyId = UUID.randomUUID();
    Post post = Post.builder().id(UUID.randomUUID()).property(Property.builder().id(propertyId).name("Nhà A").build())
            .published(false).build();
    when(postRepository.findByPropertyId(propertyId)).thenReturn(Optional.of(post));
    when(postRepository.save(post)).thenReturn(post);

    AdminPostDetailResponse result = postService.publish(propertyId);

    assertThat(result.published()).isTrue();
    assertThat(result.publishedAt()).isNotNull();
}

@Test
void unpublishClearsPublishedFlagButKeepsPublishedAt() {
    UUID propertyId = UUID.randomUUID();
    java.time.LocalDateTime firstPublishedAt = java.time.LocalDateTime.now().minusDays(3);
    Post post = Post.builder().id(UUID.randomUUID()).property(Property.builder().id(propertyId).name("Nhà A").build())
            .published(true).publishedAt(firstPublishedAt).build();
    when(postRepository.findByPropertyId(propertyId)).thenReturn(Optional.of(post));
    when(postRepository.save(post)).thenReturn(post);

    AdminPostDetailResponse result = postService.unpublish(propertyId);

    assertThat(result.published()).isFalse();
    assertThat(result.publishedAt()).isEqualTo(firstPublishedAt);
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest`
Expected: FAIL to compile — `PostService.publish`/`.unpublish` don't exist yet

- [ ] **Step 3: Add `publish`/`unpublish` to `PostService`**

```java
// PostService.java
@Transactional
public AdminPostDetailResponse publish(java.util.UUID propertyId) {
    Post post = postRepository.findByPropertyId(propertyId)
            .orElseThrow(() -> new ResourceNotFoundException("Post for property", propertyId));
    if (!post.isPublished()) {
        post.setPublished(true);
        post.setPublishedAt(java.time.LocalDateTime.now());
    }
    return AdminPostDetailResponse.from(postRepository.save(post));
}

@Transactional
public AdminPostDetailResponse unpublish(java.util.UUID propertyId) {
    Post post = postRepository.findByPropertyId(propertyId)
            .orElseThrow(() -> new ResourceNotFoundException("Post for property", propertyId));
    post.setPublished(false);
    return AdminPostDetailResponse.from(postRepository.save(post));
}
```

- [ ] **Step 4: Run the service tests to verify they pass**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest`
Expected: PASS

- [ ] **Step 5: Add the failing tests to `AdminBlogControllerTest`**

```java
// add to AdminBlogControllerTest.java
@Test
void publishDelegatesToService() {
    UUID propertyId = UUID.randomUUID();
    AdminPostDetailResponse detail = new AdminPostDetailResponse(UUID.randomUUID(), propertyId, "Nhà A",
            "Bài viết A", "bai-viet-a", null, null, true, java.time.LocalDateTime.now(), null, null, null, null);
    when(postService.publish(propertyId)).thenReturn(detail);

    ResponseEntity<AdminPostDetailResponse> result = controller.publish(propertyId);

    assertThat(result.getBody()).isEqualTo(detail);
}

@Test
void unpublishDelegatesToService() {
    UUID propertyId = UUID.randomUUID();
    AdminPostDetailResponse detail = new AdminPostDetailResponse(UUID.randomUUID(), propertyId, "Nhà A",
            "Bài viết A", "bai-viet-a", null, null, false, null, null, null, null, null);
    when(postService.unpublish(propertyId)).thenReturn(detail);

    ResponseEntity<AdminPostDetailResponse> result = controller.unpublish(propertyId);

    assertThat(result.getBody()).isEqualTo(detail);
}
```

- [ ] **Step 6: Run tests to verify they fail**

Run: `cd htr-backend && ./mvnw test -Dtest=AdminBlogControllerTest`
Expected: FAIL to compile — `controller.publish`/`.unpublish` don't exist yet

- [ ] **Step 7: Add the endpoints to `AdminBlogController`**

```java
// AdminBlogController.java
@PostMapping("/posts/{propertyId}/publish")
public ResponseEntity<AdminPostDetailResponse> publish(@PathVariable UUID propertyId) {
    return ResponseEntity.ok(postService.publish(propertyId));
}

@PostMapping("/posts/{propertyId}/unpublish")
public ResponseEntity<AdminPostDetailResponse> unpublish(@PathVariable UUID propertyId) {
    return ResponseEntity.ok(postService.unpublish(propertyId));
}
```

- [ ] **Step 8: Run both tests to verify they pass**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest,AdminBlogControllerTest`
Expected: PASS

- [ ] **Step 9: Commit**

```bash
git add htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java htr-backend/src/main/java/chez1s/htrbackend/controller/AdminBlogController.java htr-backend/src/test/java/chez1s/htrbackend/service/PostServiceTest.java htr-backend/src/test/java/chez1s/htrbackend/controller/AdminBlogControllerTest.java
git commit -m "feat(blog): add publish/unpublish endpoints"
```

### Task 17: `GET` / `DELETE /api/admin/blog/comments` (moderation)

**Context:** the spec's endpoint list (§4.2) only names `DELETE /api/admin/blog/comments/{id}`, but its own frontend section (§5.3) describes `/admin/blog/comments` as "a flat moderation list with delete" — that list needs a data source the spec omitted. This task adds the missing `GET /api/admin/blog/comments` alongside the documented `DELETE`.

**Files:**
- Create: `htr-backend/src/main/java/chez1s/htrbackend/dto/response/AdminPostCommentResponse.java`
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java`
- Modify: `htr-backend/src/main/java/chez1s/htrbackend/controller/AdminBlogController.java`
- Test: extend `PostServiceTest.java`, `AdminBlogControllerTest.java`

**Interfaces:**
- Consumes: `PostCommentRepository.findAllByOrderByCreatedAtDesc()` (Task 4), `.existsById(UUID)`, `.deleteById(UUID)`.
- Produces: `PostService.listAllCommentsForAdmin()` → `List<AdminPostCommentResponse>`, `PostService.deleteComment(UUID commentId)` (throws `ResourceNotFoundException` if missing).

- [ ] **Step 1: Add the failing tests to `PostServiceTest`**

```java
// add to PostServiceTest.java
@Test
void listAllCommentsForAdminIncludesPostContext() {
    Post post = Post.builder().id(UUID.randomUUID()).title("Bài viết A").slug("bai-viet-a").build();
    User commenter = User.builder().id(UUID.randomUUID()).fullName("Khách A").build();
    PostComment comment = PostComment.builder().id(UUID.randomUUID()).post(post).user(commenter).content("Đẹp quá").build();
    when(postCommentRepository.findAllByOrderByCreatedAtDesc()).thenReturn(List.of(comment));

    List<AdminPostCommentResponse> result = postService.listAllCommentsForAdmin();

    assertThat(result).hasSize(1);
    assertThat(result.get(0).postTitle()).isEqualTo("Bài viết A");
    assertThat(result.get(0).postSlug()).isEqualTo("bai-viet-a");
}

@Test
void deleteCommentThrowsWhenMissing() {
    UUID commentId = UUID.randomUUID();
    when(postCommentRepository.existsById(commentId)).thenReturn(false);

    assertThatThrownBy(() -> postService.deleteComment(commentId))
            .isInstanceOf(ResourceNotFoundException.class);
}

@Test
void deleteCommentRemovesIt() {
    UUID commentId = UUID.randomUUID();
    when(postCommentRepository.existsById(commentId)).thenReturn(true);

    postService.deleteComment(commentId);

    org.mockito.Mockito.verify(postCommentRepository).deleteById(commentId);
}
```

Add `import chez1s.htrbackend.dto.response.AdminPostCommentResponse;` to the top of the test file.

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest`
Expected: FAIL to compile — `AdminPostCommentResponse`/`PostService.listAllCommentsForAdmin`/`.deleteComment` don't exist yet

- [ ] **Step 3: Create `AdminPostCommentResponse`**

```java
package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.PostComment;

import java.time.LocalDateTime;
import java.util.UUID;

public record AdminPostCommentResponse(
        UUID id,
        String content,
        UUID userId,
        String userName,
        UUID postId,
        String postTitle,
        String postSlug,
        LocalDateTime createdAt
) {
    public static AdminPostCommentResponse from(PostComment comment) {
        return new AdminPostCommentResponse(
                comment.getId(),
                comment.getContent(),
                comment.getUser().getId(),
                comment.getUser().getFullName(),
                comment.getPost().getId(),
                comment.getPost().getTitle(),
                comment.getPost().getSlug(),
                comment.getCreatedAt()
        );
    }
}
```

- [ ] **Step 4: Add `listAllCommentsForAdmin`/`deleteComment` to `PostService`**

```java
// PostService.java — add import chez1s.htrbackend.dto.response.AdminPostCommentResponse;
@Transactional(readOnly = true)
public List<AdminPostCommentResponse> listAllCommentsForAdmin() {
    return postCommentRepository.findAllByOrderByCreatedAtDesc().stream()
            .map(AdminPostCommentResponse::from)
            .toList();
}

@Transactional
public void deleteComment(java.util.UUID commentId) {
    if (!postCommentRepository.existsById(commentId)) {
        throw new ResourceNotFoundException("PostComment", commentId);
    }
    postCommentRepository.deleteById(commentId);
}
```

- [ ] **Step 5: Run the service tests to verify they pass**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest`
Expected: PASS

- [ ] **Step 6: Add the failing tests to `AdminBlogControllerTest`**

```java
// add to AdminBlogControllerTest.java
@Test
void listAllCommentsDelegatesToService() {
    AdminPostCommentResponse comment = new AdminPostCommentResponse(UUID.randomUUID(), "Đẹp quá",
            UUID.randomUUID(), "Khách A", UUID.randomUUID(), "Bài viết A", "bai-viet-a", null);
    when(postService.listAllCommentsForAdmin()).thenReturn(List.of(comment));

    ResponseEntity<List<AdminPostCommentResponse>> result = controller.listAllComments();

    assertThat(result.getBody()).containsExactly(comment);
}

@Test
void deleteCommentReturnsNoContent() {
    UUID commentId = UUID.randomUUID();

    ResponseEntity<Void> result = controller.deleteComment(commentId);

    assertThat(result.getStatusCode().value()).isEqualTo(204);
    org.mockito.Mockito.verify(postService).deleteComment(commentId);
}
```

Add `import chez1s.htrbackend.dto.response.AdminPostCommentResponse;` to the test file.

- [ ] **Step 7: Run tests to verify they fail**

Run: `cd htr-backend && ./mvnw test -Dtest=AdminBlogControllerTest`
Expected: FAIL to compile — `controller.listAllComments`/`.deleteComment` don't exist yet

- [ ] **Step 8: Add the endpoints to `AdminBlogController`**

```java
// AdminBlogController.java — add imports: chez1s.htrbackend.dto.response.AdminPostCommentResponse, org.springframework.web.bind.annotation.DeleteMapping
@GetMapping("/comments")
public ResponseEntity<List<AdminPostCommentResponse>> listAllComments() {
    return ResponseEntity.ok(postService.listAllCommentsForAdmin());
}

@DeleteMapping("/comments/{id}")
public ResponseEntity<Void> deleteComment(@PathVariable UUID id) {
    postService.deleteComment(id);
    return ResponseEntity.noContent().build();
}
```

- [ ] **Step 9: Run both tests to verify they pass**

Run: `cd htr-backend && ./mvnw test -Dtest=PostServiceTest,AdminBlogControllerTest`
Expected: PASS

- [ ] **Step 10: Run the full backend test suite**

Run: `cd htr-backend && ./mvnw test`
Expected: PASS — this is the last backend task before SEO; a full green run here confirms all of `PostService`/`PublicBlogController`/`AdminBlogController`/`PublicPropertyController`/`AuthController` compose correctly together.

- [ ] **Step 11: Commit**

```bash
git add htr-backend/src/main/java/chez1s/htrbackend/dto/response/AdminPostCommentResponse.java htr-backend/src/main/java/chez1s/htrbackend/service/PostService.java htr-backend/src/main/java/chez1s/htrbackend/controller/AdminBlogController.java htr-backend/src/test/java/chez1s/htrbackend/service/PostServiceTest.java htr-backend/src/test/java/chez1s/htrbackend/controller/AdminBlogControllerTest.java
git commit -m "feat(blog): add comment moderation list and delete endpoints"
```

---

## Phase 6 — Backend: SEO

### Task 18: `GET /sitemap.xml`

**Files:**
- Create: `htr-backend/src/main/java/chez1s/htrbackend/controller/SitemapController.java`
- Modify: `htr-backend/src/main/resources/application.properties`
- Test: `htr-backend/src/test/java/chez1s/htrbackend/controller/SitemapControllerTest.java`

**Interfaces:**
- Consumes: `PostRepository.findByPublishedTrueOrderByPublishedAtDesc()` (Task 3).
- Produces: a plain XML string response at `GET /sitemap.xml` — already `permitAll()` since Task 7 added `.requestMatchers("/sitemap.xml").permitAll()`.

- [ ] **Step 1: Write the failing test**

```java
package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Post;
import chez1s.htrbackend.domain.repository.PostRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SitemapControllerTest {

    @Mock PostRepository postRepository;

    private SitemapController controller;

    @BeforeEach
    void setup() {
        controller = new SitemapController(postRepository);
        ReflectionTestUtils.setField(controller, "publicBaseUrl", "https://example.com");
    }

    @Test
    void sitemapListsOnlyPublishedPostUrls() {
        Post post = Post.builder().slug("phong-tro-dep").build();
        when(postRepository.findByPublishedTrueOrderByPublishedAtDesc()).thenReturn(List.of(post));

        String xml = controller.sitemap();

        assertThat(xml).contains("<loc>https://example.com/blog/phong-tro-dep</loc>");
        assertThat(xml).startsWith("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-backend && ./mvnw test -Dtest=SitemapControllerTest`
Expected: FAIL to compile — `SitemapController` doesn't exist yet

- [ ] **Step 3: Create `SitemapController`**

```java
package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Post;
import chez1s.htrbackend.domain.repository.PostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
public class SitemapController {

    private final PostRepository postRepository;

    @Value("${app.public-base-url:http://localhost:5173}")
    private String publicBaseUrl;

    @GetMapping(value = "/sitemap.xml", produces = MediaType.APPLICATION_XML_VALUE)
    @Transactional(readOnly = true)
    public String sitemap() {
        StringBuilder xml = new StringBuilder("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
        xml.append("<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">");
        for (Post post : postRepository.findByPublishedTrueOrderByPublishedAtDesc()) {
            xml.append("<url><loc>").append(publicBaseUrl).append("/blog/").append(post.getSlug()).append("</loc></url>");
        }
        xml.append("</urlset>");
        return xml.toString();
    }
}
```

- [ ] **Step 4: Add `app.public-base-url` to `application.properties`**

```properties
# Blog SEO
app.public-base-url=${PUBLIC_BASE_URL:http://localhost:5173}
```

Add this near the other `${VAR:default}`-style overridable settings, e.g. directly below the JWT block. `PUBLIC_BASE_URL` should be set in production the same way `CORS_ALLOWED_ORIGINS` is (per `CLAUDE.md`'s local-dev-gotchas — production overrides it to the real Vercel URL via env var, local dev keeps the `localhost:5173` default).

- [ ] **Step 5: Run test to verify it passes**

Run: `cd htr-backend && ./mvnw test -Dtest=SitemapControllerTest`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add htr-backend/src/main/java/chez1s/htrbackend/controller/SitemapController.java htr-backend/src/main/resources/application.properties htr-backend/src/test/java/chez1s/htrbackend/controller/SitemapControllerTest.java
git commit -m "feat(blog): add sitemap.xml endpoint"
```

---

## Phase 7 — Frontend: role plumbing and shared shell

### Task 19: Add `GUEST` role type + fix the two role→redirect call sites

**Context:** research found `App.tsx`'s `homePath` (array-`.includes()`, checks `PLATFORM_ADMIN`/`LANDLORD_ADMIN` explicitly) and `LoginPage.tsx`'s post-login `navigate(...)` (lowercase-string ternary, doesn't check `PLATFORM_ADMIN`/`LANDLORD_ADMIN` at all) are two **independently-written, already-slightly-divergent** implementations of the same role→path mapping. Both would silently send `GUEST` to `/tech`. Rather than patch each with its own `GUEST` branch (preserving the divergence risk), this task extracts one shared `homePathForRole` function both call.

**Files:**
- Create: `htr-frontend/src/lib/homePath.ts`
- Modify: `htr-frontend/src/types/index.ts:14`
- Modify: `htr-frontend/src/App.tsx`
- Modify: `htr-frontend/src/features/auth/pages/LoginPage.tsx`
- Test: `htr-frontend/src/lib/homePath.test.ts`

**Interfaces:**
- Consumes: `User['role']` (`types/index.ts`).
- Produces: `homePathForRole(role: User['role']): string` — consumed by `App.tsx` and `LoginPage.tsx`.

- [ ] **Step 1: Write the failing test**

```ts
// src/lib/homePath.test.ts
import { describe, it, expect } from 'vitest'
import { homePathForRole } from './homePath'

describe('homePathForRole', () => {
  it('sends admin roles to /admin', () => {
    expect(homePathForRole('ADMIN')).toBe('/admin')
    expect(homePathForRole('PLATFORM_ADMIN')).toBe('/admin')
    expect(homePathForRole('LANDLORD_ADMIN')).toBe('/admin')
  })

  it('sends TENANT to /tenant', () => {
    expect(homePathForRole('TENANT')).toBe('/tenant')
  })

  it('sends GUEST to /blog', () => {
    expect(homePathForRole('GUEST')).toBe('/blog')
  })

  it('falls back to /tech for TECHNICIAN', () => {
    expect(homePathForRole('TECHNICIAN')).toBe('/tech')
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-frontend && npx vitest run src/lib/homePath.test.ts`
Expected: FAIL — `Cannot find module './homePath'`

- [ ] **Step 3: Add `'GUEST'` to the `User.role` union**

```ts
// src/types/index.ts:14 — before
role: 'ADMIN' | 'PLATFORM_ADMIN' | 'LANDLORD_ADMIN' | 'TENANT' | 'TECHNICIAN'
// after
role: 'ADMIN' | 'PLATFORM_ADMIN' | 'LANDLORD_ADMIN' | 'TENANT' | 'TECHNICIAN' | 'GUEST'
```

- [ ] **Step 4: Create `homePathForRole`**

```ts
// src/lib/homePath.ts
import type { User } from '@/types'

export function homePathForRole(role: User['role']): string {
  switch (role) {
    case 'ADMIN':
    case 'PLATFORM_ADMIN':
    case 'LANDLORD_ADMIN':
      return '/admin'
    case 'TENANT':
      return '/tenant'
    case 'GUEST':
      return '/blog'
    default:
      return '/tech'
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd htr-frontend && npx vitest run src/lib/homePath.test.ts`
Expected: PASS

- [ ] **Step 6: Use it in `App.tsx`**

```tsx
// App.tsx — add import { homePathForRole } from '@/lib/homePath'
// replace the existing homePath ternary with:
const homePath = homePathForRole(user.role)
```

Also add the new public blog routes to **both** branches (blog content is public, viewable whether or not the user is logged in — e.g. an admin previewing a post via the "Xem trước" link from Task 27's editor):

```tsx
// App.tsx — unauthenticated branch, add before the "*" catch-all
<Route path="/blog" element={<BlogListPage />} />
<Route path="/blog/register" element={<RegisterGuestPage />} />
<Route path="/blog/:slug" element={<BlogPostPage />} />
```

```tsx
// App.tsx — authenticated branch, add alongside /change-password and /profile
<Route path="/blog" element={<BlogListPage />} />
<Route path="/blog/:slug" element={<BlogPostPage />} />
```

Add the three imports at the top of `App.tsx`:

```tsx
import BlogListPage from '@/pages/blog/BlogListPage'
import BlogPostPage from '@/pages/blog/BlogPostPage'
import RegisterGuestPage from '@/features/auth/pages/RegisterGuestPage'
```

(`BlogListPage`, `BlogPostPage`, and `RegisterGuestPage` don't exist yet — they're created in Tasks 22–24. This step will not compile until those land; if executing tasks out of order, stub them as empty components first and replace in Tasks 22–24, or execute Tasks 22–24 before this step of Task 19.)

- [ ] **Step 7: Use it in `LoginPage.tsx`**

```tsx
// LoginPage.tsx — add import { homePathForRole } from '@/lib/homePath'
// replace:
//   const role = user.role.toLowerCase()
//   navigate(role === 'admin' ? '/admin' : role === 'tenant' ? '/tenant' : '/tech')
// with:
navigate(homePathForRole(user.role))
```

- [ ] **Step 8: Run the full frontend unit test suite**

Run: `cd htr-frontend && npm run test:unit`
Expected: PASS

- [ ] **Step 9: Commit**

```bash
git add htr-frontend/src/lib/homePath.ts htr-frontend/src/lib/homePath.test.ts htr-frontend/src/types/index.ts htr-frontend/src/App.tsx htr-frontend/src/features/auth/pages/LoginPage.tsx
git commit -m "feat(blog): add GUEST role and unify role-to-homepath redirect logic"
```

### Task 20: Extract `PublicShell` (nav + footer) from `LandingPage.tsx`

**Context:** no shared public-page shell exists today — `LandingPage.tsx` builds its `NavPill`/`Footer` inline. Since the blog is the second public-facing surface, this task extracts them into a reusable `PublicShell` so `BlogListPage`/`BlogPostPage` (Tasks 22–23) don't copy-paste the chrome. The extraction is a verbatim move — `NavPill`/`Footer` markup, inline styles, and hover handlers are unchanged, only relocated.

**Files:**
- Create: `htr-frontend/src/components/PublicShell.tsx`
- Modify: `htr-frontend/src/pages/LandingPage.tsx`
- Test: `htr-frontend/src/components/PublicShell.test.tsx`

**Interfaces:**
- Produces: `export default function PublicShell({ children }: { children: ReactNode })` — consumed by `LandingPage.tsx` (this task), `BlogListPage.tsx` (Task 22), `BlogPostPage.tsx` (Task 23), `RegisterGuestPage.tsx` (Task 24).

- [ ] **Step 1: Write the failing test**

```tsx
// src/components/PublicShell.test.tsx
import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import PublicShell from './PublicShell'

describe('PublicShell', () => {
  it('renders the nav login link, footer copyright, and children', () => {
    render(
      <MemoryRouter>
        <PublicShell>
          <p>Nội dung trang</p>
        </PublicShell>
      </MemoryRouter>
    )

    expect(screen.getByRole('link', { name: /đăng nhập/i })).toHaveAttribute('href', '/login')
    expect(screen.getByText(/Nội dung trang/)).toBeInTheDocument()
    expect(screen.getByText(new RegExp(`© ${new Date().getFullYear()} HowsTheRent`))).toBeInTheDocument()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-frontend && npx vitest run src/components/PublicShell.test.tsx`
Expected: FAIL — `Cannot find module './PublicShell'`

- [ ] **Step 3: Create `PublicShell.tsx`, moving `NavPill`/`Footer` verbatim from `LandingPage.tsx`**

```tsx
// src/components/PublicShell.tsx
import { Link } from 'react-router-dom'
import { ChevronRight } from 'lucide-react'
import type { ReactNode } from 'react'
import logoHtr from '@/assets/logo-htr.png'

function NavPill() {
  return (
    <nav
      aria-label="Primary"
      style={{
        position: 'fixed',
        inset: 'var(--space-md) auto auto 50%',
        transform: 'translateX(-50%)',
        zIndex: 50,
        display: 'inline-flex',
        alignItems: 'center',
        gap: 'var(--space-xs)',
        padding: '0.5rem 0.875rem',
        background: 'color-mix(in oklch, var(--color-surface) 82%, transparent)',
        backdropFilter: 'blur(16px) saturate(130%)',
        WebkitBackdropFilter: 'blur(16px) saturate(130%)',
        border: 'var(--rule-hair) solid var(--color-border)',
        borderRadius: 'var(--radius-full)',
        boxShadow: '0 8px 24px -12px oklch(0% 0 0 / 0.16)',
        whiteSpace: 'nowrap',
      }}
    >
      {/* Wordmark */}
      <Link
        to="/"
        className="flex items-center gap-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-3"
        style={{ outlineColor: 'var(--color-accent)', borderRadius: 'var(--radius-xs)' }}
        aria-label="HowsTheRent — trang chủ"
      >
        <img
          src={logoHtr}
          alt=""
          aria-hidden="true"
          className="h-6 w-6 rounded-lg object-cover"
          style={{ boxShadow: '0 1px 2px oklch(0% 0 0 / 0.10)' }}
        />
        <span
          className="text-sm font-semibold"
          style={{ fontFamily: 'var(--font-body)', color: 'var(--color-fg)' }}
        >
          How&apos;s The Rent
        </span>
      </Link>

      {/* Separator */}
      <span
        aria-hidden="true"
        className="hidden sm:block"
        style={{
          width: 'var(--rule-hair)',
          height: '1rem',
          background: 'var(--color-border)',
          flexShrink: 0,
          margin: '0 var(--space-3xs)',
        }}
      />

      {/* CTA */}
      <Link
        to="/login"
        className="inline-flex items-center gap-1.5 text-sm font-semibold transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-3"
        style={{
          padding: '0.375rem 0.875rem',
          background: 'var(--color-accent)',
          color: 'var(--color-accent-fg)',
          borderRadius: 'var(--radius-full)',
          outlineColor: 'var(--color-accent)',
          transition: `background-color var(--dur-short) var(--ease-out), transform var(--dur-instant) var(--ease-out)`,
        }}
        onMouseEnter={e => { (e.currentTarget as HTMLElement).style.backgroundColor = 'var(--color-accent-hover)'; (e.currentTarget as HTMLElement).style.transform = 'translateY(-1px)'; }}
        onMouseLeave={e => { (e.currentTarget as HTMLElement).style.backgroundColor = 'var(--color-accent)'; (e.currentTarget as HTMLElement).style.transform = 'translateY(0)'; }}
        onMouseDown={e => { (e.currentTarget as HTMLElement).style.transform = 'translateY(1px)'; }}
        onMouseUp={e => { (e.currentTarget as HTMLElement).style.transform = 'translateY(-1px)'; }}
      >
        Đăng nhập
        <ChevronRight className="h-3.5 w-3.5" aria-hidden="true" />
      </Link>
    </nav>
  )
}

function Footer() {
  return (
    <footer>
      <div
        className="mx-auto max-w-6xl"
        style={{
          padding: 'var(--space-3xl) var(--space-xl) var(--space-2xl)',
          display: 'grid',
          gap: 'var(--space-lg)',
        }}
      >
        <p
          style={{
            fontFamily: 'var(--font-display)',
            fontSize: 'clamp(1.75rem, 4vw, 3rem)',
            fontWeight: 400,
            lineHeight: 1.05,
            letterSpacing: '-0.02em',
            color: 'var(--color-fg)',
            maxWidth: '38ch',
            fontStyle: 'normal',
          }}
        >
          Vận hành rõ ràng, bàn giao không cần giải thích lại.
        </p>

        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            paddingTop: 'var(--space-sm)',
            borderTop: 'var(--rule-hair) solid var(--color-border)',
            flexWrap: 'wrap',
            gap: 'var(--space-sm)',
          }}
        >
          <div className="flex items-center gap-2.5">
            <img
              src={logoHtr}
              alt=""
              aria-hidden="true"
              className="h-6 w-6 rounded-lg object-cover"
            />
            <span
              className="text-sm font-semibold"
              style={{ color: 'var(--color-fg)', fontFamily: 'var(--font-body)' }}
            >
              How&apos;s The Rent
            </span>
          </div>
          <p className="text-xs" style={{ color: 'var(--color-fg-subtle)' }}>
            © {new Date().getFullYear()} HowsTheRent · Dành cho vận hành nhà trọ hằng ngày.
          </p>
        </div>
      </div>
    </footer>
  )
}

export default function PublicShell({ children }: { children: ReactNode }) {
  return (
    <div
      style={{
        minHeight: '100vh',
        background: 'var(--color-bg)',
        color: 'var(--color-fg)',
        fontFamily: 'var(--font-body)',
      }}
    >
      <NavPill />
      <main>{children}</main>
      <Footer />
    </div>
  )
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd htr-frontend && npx vitest run src/components/PublicShell.test.tsx`
Expected: PASS

- [ ] **Step 5: Update `LandingPage.tsx` to use `PublicShell`**

Delete the `NavPill()` and `Footer()` function definitions from `LandingPage.tsx` (now living in `PublicShell.tsx`), and replace the default export's body:

```tsx
// LandingPage.tsx — before
export default function LandingPage() {
  return (
    <>
      <style>{responsiveCSS}</style>
      <div style={{ minHeight: '100vh', background: 'var(--color-bg)', color: 'var(--color-fg)', fontFamily: 'var(--font-body)' }}>
        <NavPill />
        <main>
          <Hero />
          <StatStrip />
          <section id="how-it-works" aria-label="Cách hệ thống vận hành">
            {splitPairs.map(pair => (
              <SplitPair key={pair.id} pair={pair} />
            ))}
          </section>
          <ModulesStrip />
          <RolesSection />
          <CtaStrip />
        </main>
        <Footer />
      </div>
    </>
  )
}
```

```tsx
// LandingPage.tsx — after
import PublicShell from '@/components/PublicShell'
// ... (other existing imports, minus ChevronRight/logoHtr if no longer used elsewhere in this file — check with the lint step below)

export default function LandingPage() {
  return (
    <>
      <style>{responsiveCSS}</style>
      <PublicShell>
        <Hero />
        <StatStrip />
        <section id="how-it-works" aria-label="Cách hệ thống vận hành">
          {splitPairs.map(pair => (
            <SplitPair key={pair.id} pair={pair} />
          ))}
        </section>
        <ModulesStrip />
        <RolesSection />
        <CtaStrip />
      </PublicShell>
    </>
  )
}
```

- [ ] **Step 6: Lint and build to catch any now-unused imports left behind by the `NavPill`/`Footer` removal**

Run: `cd htr-frontend && npm run lint && npm run build`
Expected: PASS. If `logoHtr` or `ChevronRight` are flagged unused in `LandingPage.tsx` (i.e. `CtaStrip`/`Hero`/etc. don't reference them independently), remove those two import lines from `LandingPage.tsx`.

- [ ] **Step 7: Run the full frontend unit test suite**

Run: `cd htr-frontend && npm run test:unit`
Expected: PASS — confirms `LandingPage` still renders correctly through `PublicShell`.

- [ ] **Step 8: Commit**

```bash
git add htr-frontend/src/components/PublicShell.tsx htr-frontend/src/components/PublicShell.test.tsx htr-frontend/src/pages/LandingPage.tsx
git commit -m "refactor(blog): extract PublicShell nav/footer from LandingPage for reuse by blog pages"
```

---

## Phase 8 — Frontend: API client layer

### Task 21: `blogApi.ts` (public) + `adminBlogApi.ts`

**Files:**
- Create: `htr-frontend/src/api/blogApi.ts`
- Create: `htr-frontend/src/api/adminBlogApi.ts`
- Modify: `htr-frontend/src/api/index.ts`
- Test: `htr-frontend/src/api/blogApi.test.ts`

**Interfaces:**
- Consumes: `api` (default export, `htr-frontend/src/lib/api.ts` — `axios.create({ baseURL, withCredentials: true })`).
- Produces: `blogApi.{list, getBySlug, listComments, addComment, like, unlike, getVacancy, registerGuest}`, `adminBlogApi.{listAll, get, update, generateDraft, uploadCoverImage, publish, unpublish, listComments, deleteComment}` — consumed by Tasks 22–27's pages/mutations. TS types (`BlogPostSummary`, `BlogPostDetail`, `Vacancy`, `PostComment`, `LikeStatus`, `AdminPostSummary`, `AdminPostDetail`, `GeneratedDraft`, `AdminPostComment`) mirror the backend response records field-for-field (Tasks 8–17).

- [ ] **Step 1: Write the failing test**

Following this repo's convention of not unit-testing thin `api.get(...).then(r => r.data)` wrappers directly (no existing `*Api.test.ts` file was found for any of the other per-feature API files) would leave this task without a real test cycle, so instead this test locks in the URL/payload shape each function sends — a regression net for exactly the kind of typo that breaks an integration silently:

```ts
// src/api/blogApi.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import api from '@/lib/api'
import { blogApi } from './blogApi'

vi.mock('@/lib/api', () => ({
  default: { get: vi.fn(), post: vi.fn(), delete: vi.fn() },
}))

describe('blogApi', () => {
  beforeEach(() => {
    vi.mocked(api.get).mockReset()
    vi.mocked(api.post).mockReset()
    vi.mocked(api.delete).mockReset()
  })

  it('list() calls GET /public/blog/posts', async () => {
    vi.mocked(api.get).mockResolvedValue({ data: [] })
    await blogApi.list()
    expect(api.get).toHaveBeenCalledWith('/public/blog/posts')
  })

  it('getBySlug() calls GET /public/blog/posts/:slug', async () => {
    vi.mocked(api.get).mockResolvedValue({ data: {} })
    await blogApi.getBySlug('phong-tro-dep')
    expect(api.get).toHaveBeenCalledWith('/public/blog/posts/phong-tro-dep')
  })

  it('addComment() posts content to the comments endpoint', async () => {
    vi.mocked(api.post).mockResolvedValue({ data: {} })
    await blogApi.addComment('phong-tro-dep', 'Rất đẹp')
    expect(api.post).toHaveBeenCalledWith('/public/blog/posts/phong-tro-dep/comments', { content: 'Rất đẹp' })
  })

  it('like() posts to the like endpoint', async () => {
    vi.mocked(api.post).mockResolvedValue({ data: {} })
    await blogApi.like('phong-tro-dep')
    expect(api.post).toHaveBeenCalledWith('/public/blog/posts/phong-tro-dep/like')
  })

  it('unlike() deletes the like endpoint', async () => {
    vi.mocked(api.delete).mockResolvedValue({ data: {} })
    await blogApi.unlike('phong-tro-dep')
    expect(api.delete).toHaveBeenCalledWith('/public/blog/posts/phong-tro-dep/like')
  })

  it('getVacancy() calls GET /public/properties/:id/vacancy', async () => {
    vi.mocked(api.get).mockResolvedValue({ data: {} })
    await blogApi.getVacancy('prop-1')
    expect(api.get).toHaveBeenCalledWith('/public/properties/prop-1/vacancy')
  })

  it('registerGuest() posts registration fields', async () => {
    vi.mocked(api.post).mockResolvedValue({ data: {} })
    await blogApi.registerGuest({ fullName: 'Khách A', email: 'a@example.com', password: 'Password1!' })
    expect(api.post).toHaveBeenCalledWith('/auth/register-guest', { fullName: 'Khách A', email: 'a@example.com', password: 'Password1!' })
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-frontend && npx vitest run src/api/blogApi.test.ts`
Expected: FAIL — `Cannot find module './blogApi'`

- [ ] **Step 3: Create `blogApi.ts`**

```ts
// src/api/blogApi.ts
import api from '@/lib/api'
import type { User } from '@/types'

export interface BlogPostSummary {
  id: string
  slug: string
  title: string
  coverImageUrl: string | null
  propertyId: string
  propertyName: string
  propertyAddress: string
  emptyRoomCount: number
  totalRoomCount: number
  publishedAt: string | null
}

export interface BlogPostDetail {
  id: string
  slug: string
  title: string
  content: string
  coverImageUrl: string | null
  propertyId: string
  propertyName: string
  propertyAddress: string
  publishedAt: string | null
  likeCount: number
}

export interface Vacancy {
  emptyCount: number
  rentedCount: number
  totalCount: number
}

export interface PostComment {
  id: string
  content: string
  userId: string
  userName: string
  createdAt: string
}

export interface LikeStatus {
  liked: boolean
  likeCount: number
}

export interface RegisterGuestPayload {
  fullName: string
  email: string
  password: string
  phone?: string
}

export interface AuthResult {
  accessToken: string
  refreshToken: string
  user: User
}

export const blogApi = {
  list: () => api.get<BlogPostSummary[]>('/public/blog/posts').then(r => r.data),
  getBySlug: (slug: string) => api.get<BlogPostDetail>(`/public/blog/posts/${slug}`).then(r => r.data),
  listComments: (slug: string) => api.get<PostComment[]>(`/public/blog/posts/${slug}/comments`).then(r => r.data),
  addComment: (slug: string, content: string) =>
    api.post<PostComment>(`/public/blog/posts/${slug}/comments`, { content }).then(r => r.data),
  like: (slug: string) => api.post<LikeStatus>(`/public/blog/posts/${slug}/like`).then(r => r.data),
  unlike: (slug: string) => api.delete<LikeStatus>(`/public/blog/posts/${slug}/like`).then(r => r.data),
  getVacancy: (propertyId: string) => api.get<Vacancy>(`/public/properties/${propertyId}/vacancy`).then(r => r.data),
  registerGuest: (payload: RegisterGuestPayload) =>
    api.post<AuthResult>('/auth/register-guest', payload).then(r => r.data),
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd htr-frontend && npx vitest run src/api/blogApi.test.ts`
Expected: PASS

- [ ] **Step 5: Create `adminBlogApi.ts` (no dedicated test — thin wrapper, mirrors `blogApi.ts`'s already-tested call shape)**

```ts
// src/api/adminBlogApi.ts
import api from '@/lib/api'

export interface AdminPostSummary {
  propertyId: string
  propertyName: string
  postId: string | null
  title: string | null
  slug: string | null
  published: boolean
  updatedAt: string | null
}

export interface AdminPostDetail {
  id: string
  propertyId: string
  propertyName: string
  title: string
  slug: string
  content: string | null
  coverImageUrl: string | null
  published: boolean
  publishedAt: string | null
  authorId: string | null
  authorName: string | null
  createdAt: string
  updatedAt: string
}

export interface GeneratedDraft {
  title: string
  content: string
  coverImageUrl: string | null
}

export interface AdminPostComment {
  id: string
  content: string
  userId: string
  userName: string
  postId: string
  postTitle: string
  postSlug: string
  createdAt: string
}

export interface UpdatePostPayload {
  title: string
  slug?: string
  content?: string
  coverImageUrl?: string
}

export const adminBlogApi = {
  listAll: () => api.get<AdminPostSummary[]>('/admin/blog/posts').then(r => r.data),
  get: (propertyId: string) => api.get<AdminPostDetail>(`/admin/blog/posts/${propertyId}`).then(r => r.data),
  update: (propertyId: string, payload: UpdatePostPayload) =>
    api.put<AdminPostDetail>(`/admin/blog/posts/${propertyId}`, payload).then(r => r.data),
  generateDraft: (propertyId: string) =>
    api.post<GeneratedDraft>(`/admin/blog/posts/${propertyId}/draft`).then(r => r.data),
  uploadCoverImage: (propertyId: string, file: File) => {
    const formData = new FormData()
    formData.append('file', file)
    return api.post<AdminPostDetail>(`/admin/blog/posts/${propertyId}/cover-image`, formData).then(r => r.data)
  },
  publish: (propertyId: string) => api.post<AdminPostDetail>(`/admin/blog/posts/${propertyId}/publish`).then(r => r.data),
  unpublish: (propertyId: string) => api.post<AdminPostDetail>(`/admin/blog/posts/${propertyId}/unpublish`).then(r => r.data),
  listComments: () => api.get<AdminPostComment[]>('/admin/blog/comments').then(r => r.data),
  deleteComment: (id: string) => api.delete(`/admin/blog/comments/${id}`).then(r => r.data),
}
```

- [ ] **Step 6: Barrel-export both from `api/index.ts`**

```ts
// src/api/index.ts — add two lines
export * from './blogApi'
export * from './adminBlogApi'
```

- [ ] **Step 7: Run the full frontend unit test suite**

Run: `cd htr-frontend && npm run test:unit`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add htr-frontend/src/api/blogApi.ts htr-frontend/src/api/adminBlogApi.ts htr-frontend/src/api/blogApi.test.ts htr-frontend/src/api/index.ts
git commit -m "feat(blog): add public and admin blog API client functions"
```

---

## Phase 9 — Frontend: public pages

### Task 22: `/blog` listing page

**Files:**
- Create: `htr-frontend/src/pages/blog/BlogListPage.tsx`
- Test: `htr-frontend/src/pages/blog/BlogListPage.test.tsx`

**Interfaces:**
- Consumes: `blogApi.list()` (Task 21), `PublicShell` (Task 20).
- Produces: `export default function BlogListPage()` — routed at `/blog` in `App.tsx` (Task 19).

- [ ] **Step 1: Write the failing test**

```tsx
// src/pages/blog/BlogListPage.test.tsx
import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { blogApi } from '@/api'
import BlogListPage from './BlogListPage'

vi.mock('@/api', () => ({
  blogApi: { list: vi.fn() },
}))

function renderPage() {
  const client = new QueryClient()
  return render(
    <QueryClientProvider client={client}>
      <MemoryRouter>
        <BlogListPage />
      </MemoryRouter>
    </QueryClientProvider>
  )
}

describe('BlogListPage', () => {
  it('renders each published post with its vacancy badge', async () => {
    vi.mocked(blogApi.list).mockResolvedValue([
      {
        id: '1', slug: 'phong-tro-dep', title: 'Phòng trọ đẹp Quận 1', coverImageUrl: null,
        propertyId: 'p1', propertyName: 'Nhà trọ Xanh', propertyAddress: '12 Lê Lợi',
        emptyRoomCount: 2, totalRoomCount: 5, publishedAt: '2026-08-01T00:00:00',
      },
    ])

    renderPage()

    expect(await screen.findByText('Phòng trọ đẹp Quận 1')).toBeInTheDocument()
    expect(screen.getByText(/2 phòng trống/i)).toBeInTheDocument()
  })

  it('shows "Hết phòng" when there is no vacancy', async () => {
    vi.mocked(blogApi.list).mockResolvedValue([
      {
        id: '1', slug: 'phong-tro-day', title: 'Phòng trọ đầy', coverImageUrl: null,
        propertyId: 'p1', propertyName: 'Nhà trọ Đỏ', propertyAddress: '5 Trần Phú',
        emptyRoomCount: 0, totalRoomCount: 5, publishedAt: null,
      },
    ])

    renderPage()

    expect(await screen.findByText(/hết phòng/i)).toBeInTheDocument()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-frontend && npx vitest run src/pages/blog/BlogListPage.test.tsx`
Expected: FAIL — `Cannot find module './BlogListPage'`

- [ ] **Step 3: Create `BlogListPage.tsx`**

```tsx
// src/pages/blog/BlogListPage.tsx
import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { blogApi } from '@/api'
import PublicShell from '@/components/PublicShell'
import { cn } from '@/lib/utils'

export default function BlogListPage() {
  const { data: posts, isLoading } = useQuery({
    queryKey: ['blog-posts'],
    queryFn: blogApi.list,
  })

  return (
    <PublicShell>
      <section className="mx-auto max-w-5xl px-6 py-24">
        <h1 className="text-3xl font-semibold tracking-[-0.03em] text-fg">Nhà trọ đang cho thuê</h1>
        <p className="mt-2 text-sm text-fg-muted">Xem thông tin từng nhà trọ và số phòng còn trống theo thời gian thực.</p>

        {isLoading && <p className="mt-10 text-sm text-fg-muted">Đang tải…</p>}

        <div className="mt-10 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {posts?.map(post => (
            <Link
              key={post.id}
              to={`/blog/${post.slug}`}
              className="block overflow-hidden rounded-2xl border border-border bg-surface transition-shadow hover:shadow-md"
            >
              {post.coverImageUrl && (
                <img src={post.coverImageUrl} alt="" className="h-40 w-full object-cover" />
              )}
              <div className="p-5">
                <h2 className="text-base font-semibold text-fg">{post.title}</h2>
                <p className="mt-1 text-sm text-fg-muted">{post.propertyName} · {post.propertyAddress}</p>
                <span
                  className={cn(
                    'mt-3 inline-flex items-center rounded-full px-2.5 py-1 text-xs font-medium',
                    post.emptyRoomCount > 0 ? 'bg-accent-surface text-accent' : 'bg-surface text-fg-subtle'
                  )}
                >
                  {post.emptyRoomCount > 0 ? `${post.emptyRoomCount} phòng trống` : 'Hết phòng'}
                </span>
              </div>
            </Link>
          ))}
        </div>
      </section>
    </PublicShell>
  )
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd htr-frontend && npx vitest run src/pages/blog/BlogListPage.test.tsx`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add htr-frontend/src/pages/blog/BlogListPage.tsx htr-frontend/src/pages/blog/BlogListPage.test.tsx
git commit -m "feat(blog): add public blog listing page"
```

### Task 23: `/blog/:slug` post detail page

**Files:**
- Create: `htr-frontend/src/pages/blog/BlogPostPage.tsx`
- Test: `htr-frontend/src/pages/blog/BlogPostPage.test.tsx`

**Interfaces:**
- Consumes: `blogApi.{getBySlug, getVacancy, listComments, addComment, like, unlike}` (Task 21), `PublicShell` (Task 20), `useAuthStore` (`@/stores/authStore` — existing, used to decide the login-gated comment form/like button), `useGuardedMutation` (`@/hooks/useGuardedMutation` — existing), `useDocumentMeta` (Task 28 — imported here but that hook doesn't exist until Task 28 lands; if executing tasks in order, do Task 28 before this step, or stub a no-op `useDocumentMeta` first).
- Produces: `export default function BlogPostPage()` — routed at `/blog/:slug`.

- [ ] **Step 1: Write the failing test**

```tsx
// src/pages/blog/BlogPostPage.test.tsx
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { blogApi } from '@/api'
import { useAuthStore } from '@/stores/authStore'
import BlogPostPage from './BlogPostPage'

vi.mock('@/api', () => ({
  blogApi: {
    getBySlug: vi.fn(),
    getVacancy: vi.fn(),
    listComments: vi.fn(),
    addComment: vi.fn(),
    like: vi.fn(),
    unlike: vi.fn(),
  },
}))

function renderAtSlug(slug: string) {
  const client = new QueryClient()
  return render(
    <QueryClientProvider client={client}>
      <MemoryRouter initialEntries={[`/blog/${slug}`]}>
        <Routes>
          <Route path="/blog/:slug" element={<BlogPostPage />} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>
  )
}

describe('BlogPostPage', () => {
  beforeEach(() => {
    useAuthStore.setState({ user: null })
    vi.mocked(blogApi.getBySlug).mockResolvedValue({
      id: '1', slug: 'phong-tro-dep', title: 'Phòng trọ đẹp', content: '<p>Nội dung</p>', coverImageUrl: null,
      propertyId: 'p1', propertyName: 'Nhà trọ Xanh', propertyAddress: '12 Lê Lợi', publishedAt: null, likeCount: 3,
    })
    vi.mocked(blogApi.getVacancy).mockResolvedValue({ emptyCount: 2, rentedCount: 3, totalCount: 5 })
    vi.mocked(blogApi.listComments).mockResolvedValue([])
  })

  it('renders post content and the live vacancy widget', async () => {
    renderAtSlug('phong-tro-dep')

    expect(await screen.findByText('Phòng trọ đẹp')).toBeInTheDocument()
    await waitFor(() => expect(screen.getByText(/2\/5 phòng còn trống/i)).toBeInTheDocument())
  })

  it('shows a login prompt instead of the comment form when logged out', async () => {
    renderAtSlug('phong-tro-dep')

    expect(await screen.findByText(/đăng nhập để bình luận/i)).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /gửi bình luận/i })).not.toBeInTheDocument()
  })

  it('shows the comment form when logged in', async () => {
    useAuthStore.setState({ user: { id: 'u1', fullName: 'Khách A', email: 'a@example.com', role: 'GUEST', active: true } })

    renderAtSlug('phong-tro-dep')

    expect(await screen.findByRole('button', { name: /gửi bình luận/i })).toBeInTheDocument()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-frontend && npx vitest run src/pages/blog/BlogPostPage.test.tsx`
Expected: FAIL — `Cannot find module './BlogPostPage'`

- [ ] **Step 3: Create a no-op `useDocumentMeta` stub (replaced by Task 28's real implementation)**

```ts
// src/hooks/useDocumentMeta.ts
export function useDocumentMeta(_title: string, _description: string) {
  // implemented in full by Task 28
}
```

(Skip this step if Task 28 has already landed.)

- [ ] **Step 4: Create `BlogPostPage.tsx`**

```tsx
// src/pages/blog/BlogPostPage.tsx
import { useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { blogApi } from '@/api'
import { useAuthStore } from '@/stores/authStore'
import { useGuardedMutation } from '@/hooks/useGuardedMutation'
import { useDocumentMeta } from '@/hooks/useDocumentMeta'
import { showToast } from '@/lib/toast'
import { getErrorMessage } from '@/lib/apiError'
import PublicShell from '@/components/PublicShell'
import { Button } from '@/components/ui/button'

export default function BlogPostPage() {
  const { slug = '' } = useParams<{ slug: string }>()
  const { user } = useAuthStore()
  const qc = useQueryClient()
  const [commentText, setCommentText] = useState('')

  const { data: post } = useQuery({
    queryKey: ['blog-post', slug],
    queryFn: () => blogApi.getBySlug(slug),
    enabled: !!slug,
  })

  const { data: vacancy } = useQuery({
    queryKey: ['blog-post-vacancy', post?.propertyId],
    queryFn: () => blogApi.getVacancy(post!.propertyId),
    enabled: !!post?.propertyId,
  })

  const { data: comments } = useQuery({
    queryKey: ['blog-post-comments', slug],
    queryFn: () => blogApi.listComments(slug),
    enabled: !!slug,
  })

  useDocumentMeta(
    post ? `${post.title} · HowsTheRent` : 'HowsTheRent',
    post ? `${post.propertyName} — ${post.propertyAddress}` : ''
  )

  const addComment = useGuardedMutation({
    mutationFn: (content: string) => blogApi.addComment(slug, content),
    onSuccess: () => {
      setCommentText('')
      qc.invalidateQueries({ queryKey: ['blog-post-comments', slug] })
    },
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Gửi bình luận thất bại'), type: 'error' }),
  })

  const toggleLike = useGuardedMutation({
    mutationFn: () => (post && 'liked' in (qc.getQueryData(['blog-post-liked', slug]) ?? {})
      ? blogApi.unlike(slug)
      : blogApi.like(slug)),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['blog-post', slug] }),
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Không thể cập nhật lượt thích'), type: 'error' }),
  })

  if (!post) {
    return (
      <PublicShell>
        <p className="mx-auto max-w-3xl px-6 py-24 text-sm text-fg-muted">Đang tải…</p>
      </PublicShell>
    )
  }

  return (
    <PublicShell>
      <article className="mx-auto max-w-3xl px-6 py-24">
        {post.coverImageUrl && (
          <img src={post.coverImageUrl} alt="" className="mb-8 h-64 w-full rounded-2xl object-cover" />
        )}
        <h1 className="text-3xl font-semibold tracking-[-0.03em] text-fg">{post.title}</h1>
        <p className="mt-2 text-sm text-fg-muted">{post.propertyName} · {post.propertyAddress}</p>

        {vacancy && (
          <div className="mt-6 inline-flex items-center rounded-full bg-accent-surface px-3 py-1.5 text-sm font-medium text-accent">
            {vacancy.emptyCount}/{vacancy.totalCount} phòng còn trống
          </div>
        )}

        {/* eslint-disable-next-line react/no-danger -- admin-authored rich-text HTML, not user-submitted */}
        <div className="prose mt-8 max-w-none" dangerouslySetInnerHTML={{ __html: post.content }} />

        <div className="mt-10 flex items-center gap-3 border-t border-border pt-6">
          <Button type="button" variant="secondary" onClick={() => toggleLike.mutate(undefined)} loading={toggleLike.isPending}>
            ♥ {post.likeCount} lượt thích
          </Button>
        </div>

        <section className="mt-12 border-t border-border pt-8">
          <h2 className="text-lg font-semibold text-fg">Bình luận</h2>

          <ul className="mt-4 space-y-4">
            {comments?.map(comment => (
              <li key={comment.id} className="rounded-xl border border-border bg-surface p-4">
                <p className="text-sm font-medium text-fg">{comment.userName}</p>
                <p className="mt-1 text-sm text-fg-muted">{comment.content}</p>
              </li>
            ))}
          </ul>

          {user ? (
            <form
              className="mt-6 flex flex-col gap-3"
              onSubmit={e => {
                e.preventDefault()
                if (commentText.trim()) addComment.mutate(commentText.trim())
              }}
            >
              <textarea
                className="min-h-[96px] rounded-xl border border-border bg-bg p-3 text-sm text-fg"
                value={commentText}
                onChange={e => setCommentText(e.target.value)}
                placeholder="Viết bình luận…"
              />
              <Button type="submit" loading={addComment.isPending} className="self-start">
                Gửi bình luận
              </Button>
            </form>
          ) : (
            <p className="mt-6 text-sm text-fg-muted">
              <Link to="/login" className="font-medium text-accent hover:text-accent-hover">Đăng nhập</Link> để bình luận.
            </p>
          )}
        </section>
      </article>
    </PublicShell>
  )
}
```

**Note on the like-toggle mutation:** since `BlogPostDetailResponse` doesn't carry a per-viewer `liked` boolean (the spec's `PostLike` uniqueness check happens server-side per request, not client-cached), this simplified toggle always calls `like` first; a small follow-up (not blocking this plan) would have the backend return `liked` alongside `likeCount` on `GET .../posts/{slug}` so the button can render "Bỏ thích" vs "♥ Thích" accurately for a logged-in viewer who already liked it. For v1 this is an acceptable simplification — the spec doesn't require the like button to reflect prior-liked state, only that liking is idempotent (Task 11 already guarantees the toggle can't double-count).

- [ ] **Step 5: Run test to verify it passes**

Run: `cd htr-frontend && npx vitest run src/pages/blog/BlogPostPage.test.tsx`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add htr-frontend/src/pages/blog/BlogPostPage.tsx htr-frontend/src/pages/blog/BlogPostPage.test.tsx htr-frontend/src/hooks/useDocumentMeta.ts
git commit -m "feat(blog): add public blog post detail page with vacancy, comments, and like"
```

### Task 24: `/blog/register` guest signup page

**Context:** no signup/register page exists anywhere in this frontend today (confirmed by research — zero matches for `signup`/`register` across `src/`). This is modeled directly on `LoginPage.tsx`'s structure (local `useState` fields, single `handleSubmit`, `axios.isAxiosError`-based error extraction) since that's the closest existing analog, not an existing pattern to copy.

**Files:**
- Create: `htr-frontend/src/features/auth/pages/RegisterGuestPage.tsx`
- Test: `htr-frontend/src/features/auth/pages/RegisterGuestPage.test.tsx`

**Interfaces:**
- Consumes: `blogApi.registerGuest` (Task 21), `useAuthStore.setUser` (existing, same as `LoginPage.tsx`), `homePathForRole` (Task 19).
- Produces: `export default function RegisterGuestPage()` — routed at `/blog/register`.

- [ ] **Step 1: Write the failing test**

```tsx
// src/features/auth/pages/RegisterGuestPage.test.tsx
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { blogApi } from '@/api'
import { useAuthStore } from '@/stores/authStore'
import RegisterGuestPage from './RegisterGuestPage'

vi.mock('@/api', () => ({
  blogApi: { registerGuest: vi.fn() },
}))

describe('RegisterGuestPage', () => {
  beforeEach(() => {
    useAuthStore.setState({ user: null })
  })

  it('registers and logs the guest in on submit', async () => {
    vi.mocked(blogApi.registerGuest).mockResolvedValue({
      accessToken: 'a', refreshToken: 'r',
      user: { id: 'u1', fullName: 'Khách A', email: 'a@example.com', role: 'GUEST', active: true },
    })

    render(<MemoryRouter><RegisterGuestPage /></MemoryRouter>)

    fireEvent.change(screen.getByLabelText(/họ tên/i), { target: { value: 'Khách A' } })
    fireEvent.change(screen.getByLabelText(/^email$/i), { target: { value: 'a@example.com' } })
    fireEvent.change(screen.getByLabelText(/mật khẩu/i), { target: { value: 'Password1!' } })
    fireEvent.click(screen.getByRole('button', { name: /đăng ký/i }))

    await waitFor(() => expect(blogApi.registerGuest).toHaveBeenCalledWith({
      fullName: 'Khách A', email: 'a@example.com', password: 'Password1!',
    }))
    await waitFor(() => expect(useAuthStore.getState().user?.role).toBe('GUEST'))
  })

  it('shows an error message when the email is already taken', async () => {
    vi.mocked(blogApi.registerGuest).mockRejectedValue({
      isAxiosError: true,
      response: { status: 400, data: { message: 'Email đã được sử dụng' } },
    })

    render(<MemoryRouter><RegisterGuestPage /></MemoryRouter>)

    fireEvent.change(screen.getByLabelText(/họ tên/i), { target: { value: 'Khách A' } })
    fireEvent.change(screen.getByLabelText(/^email$/i), { target: { value: 'a@example.com' } })
    fireEvent.change(screen.getByLabelText(/mật khẩu/i), { target: { value: 'Password1!' } })
    fireEvent.click(screen.getByRole('button', { name: /đăng ký/i }))

    expect(await screen.findByText('Email đã được sử dụng')).toBeInTheDocument()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-frontend && npx vitest run src/features/auth/pages/RegisterGuestPage.test.tsx`
Expected: FAIL — `Cannot find module './RegisterGuestPage'`

- [ ] **Step 3: Create `RegisterGuestPage.tsx`**

```tsx
// src/features/auth/pages/RegisterGuestPage.tsx
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'
import { blogApi } from '@/api'
import { useAuthStore } from '@/stores/authStore'
import { homePathForRole } from '@/lib/homePath'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

function getRegisterErrorMessage(error: unknown) {
  if (axios.isAxiosError(error)) {
    const message = error.response?.data?.message
    if (typeof message === 'string' && message.trim()) {
      return message
    }
  }
  return 'Hệ thống đang gặp sự cố. Vui lòng thử lại sau.'
}

export default function RegisterGuestPage() {
  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const navigate = useNavigate()
  const { setUser } = useAuthStore()

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const { user } = await blogApi.registerGuest({ fullName, email, password })
      setUser(user)
      navigate(homePathForRole(user.role))
    } catch (err: unknown) {
      setError(getRegisterErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-bg px-6 py-12">
      <div className="w-full max-w-[420px]">
        <h1 className="text-2xl font-semibold tracking-[-0.03em] text-fg">Tạo tài khoản</h1>
        <p className="mt-2 text-sm text-fg-muted">Đăng ký để bình luận và thích bài viết.</p>

        <form onSubmit={handleSubmit} className="mt-8 space-y-5" noValidate>
          <Input
            label="Họ tên"
            value={fullName}
            onChange={e => setFullName(e.target.value)}
            required
            autoComplete="name"
          />
          <Input
            label="Email"
            type="email"
            value={email}
            onChange={e => setEmail(e.target.value)}
            required
            autoComplete="email"
          />
          <Input
            label="Mật khẩu"
            type="password"
            value={password}
            onChange={e => setPassword(e.target.value)}
            required
            minLength={8}
            autoComplete="new-password"
          />

          {error && (
            <p className="rounded-xl border border-error-border bg-error-surface p-3 text-sm text-error-fg" role="alert">
              {error}
            </p>
          )}

          <Button type="submit" className="w-full" loading={loading}>
            {loading ? 'Đang đăng ký…' : 'Đăng ký'}
          </Button>
        </form>
      </div>
    </div>
  )
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd htr-frontend && npx vitest run src/features/auth/pages/RegisterGuestPage.test.tsx`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add htr-frontend/src/features/auth/pages/RegisterGuestPage.tsx htr-frontend/src/features/auth/pages/RegisterGuestPage.test.tsx
git commit -m "feat(blog): add guest self-registration page"
```

---

## Phase 10 — Frontend: admin pages

### Task 25: `/admin/blog` list page

**Files:**
- Modify: `htr-frontend/src/lib/utils.ts`
- Create: `htr-frontend/src/features/admin/pages/blog/AdminBlogListPage.tsx`
- Modify: `htr-frontend/src/router/adminRoutes.tsx`
- Test: `htr-frontend/src/lib/utils.test.ts` (extend)
- Test: `htr-frontend/src/features/admin/pages/blog/AdminBlogListPage.test.tsx`

**Interfaces:**
- Consumes: `adminBlogApi.listAll()` (Task 21), `RequireRole` (existing, `src/router/RequireRole.tsx`).
- Produces: `postStatusLabel('PUBLISHED' | 'DRAFT' | 'NONE'): string` in `lib/utils.ts`; `export default function AdminBlogListPage()` routed at `/admin/blog`.

- [ ] **Step 1: Add the failing test to `lib/utils.test.ts`**

```ts
// add to src/lib/utils.test.ts
describe('postStatusLabel', () => {
  it('maps each status to a Vietnamese label', () => {
    expect(postStatusLabel('PUBLISHED')).toBe('Đã xuất bản')
    expect(postStatusLabel('DRAFT')).toBe('Bản nháp')
    expect(postStatusLabel('NONE')).toBe('Chưa có bài viết')
  })
})
```

Add `import { postStatusLabel } from './utils'` alongside the existing `directionLabel` import at the top of the file (or extend the existing combined import line).

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-frontend && npx vitest run src/lib/utils.test.ts`
Expected: FAIL — `postStatusLabel is not a function`

- [ ] **Step 3: Add `postStatusLabel` to `lib/utils.ts`**

```ts
// lib/utils.ts — add next to directionLabel
export function postStatusLabel(status: 'PUBLISHED' | 'DRAFT' | 'NONE'): string {
  const map: Record<string, string> = {
    PUBLISHED: 'Đã xuất bản',
    DRAFT: 'Bản nháp',
    NONE: 'Chưa có bài viết',
  }
  return map[status] ?? status
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd htr-frontend && npx vitest run src/lib/utils.test.ts`
Expected: PASS

- [ ] **Step 5: Write the failing page test**

```tsx
// src/features/admin/pages/blog/AdminBlogListPage.test.tsx
import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { adminBlogApi } from '@/api'
import AdminBlogListPage from './AdminBlogListPage'

vi.mock('@/api', () => ({
  adminBlogApi: { listAll: vi.fn() },
}))

function renderPage() {
  const client = new QueryClient()
  return render(
    <QueryClientProvider client={client}>
      <MemoryRouter><AdminBlogListPage /></MemoryRouter>
    </QueryClientProvider>
  )
}

describe('AdminBlogListPage', () => {
  it('shows each property with its post status', async () => {
    vi.mocked(adminBlogApi.listAll).mockResolvedValue([
      { propertyId: 'p1', propertyName: 'Nhà A', postId: '1', title: 'Bài A', slug: 'bai-a', published: true, updatedAt: null },
      { propertyId: 'p2', propertyName: 'Nhà B', postId: null, title: null, slug: null, published: false, updatedAt: null },
    ])

    renderPage()

    expect(await screen.findByText('Nhà A')).toBeInTheDocument()
    expect(screen.getByText('Đã xuất bản')).toBeInTheDocument()
    expect(screen.getByText('Nhà B')).toBeInTheDocument()
    expect(screen.getByText('Chưa có bài viết')).toBeInTheDocument()
  })
})
```

- [ ] **Step 6: Run test to verify it fails**

Run: `cd htr-frontend && npx vitest run src/features/admin/pages/blog/AdminBlogListPage.test.tsx`
Expected: FAIL — `Cannot find module './AdminBlogListPage'`

- [ ] **Step 7: Create `AdminBlogListPage.tsx`**

```tsx
// src/features/admin/pages/blog/AdminBlogListPage.tsx
import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { adminBlogApi } from '@/api'
import { postStatusLabel } from '@/lib/utils'

export default function AdminBlogListPage() {
  const { data: rows, isLoading } = useQuery({
    queryKey: ['admin-blog-posts'],
    queryFn: adminBlogApi.listAll,
  })

  return (
    <div className="p-8">
      <h1 className="text-xl font-semibold text-fg">Blog bất động sản</h1>
      <p className="mt-1 text-sm text-fg-muted">Quản lý bài viết cho từng nhà trọ.</p>

      {isLoading && <p className="mt-6 text-sm text-fg-muted">Đang tải…</p>}

      <div className="mt-6 overflow-x-auto rounded-2xl border border-border">
        <table className="w-full text-sm">
          <thead className="bg-surface text-left text-fg-muted">
            <tr>
              <th className="px-4 py-3">Nhà trọ</th>
              <th className="px-4 py-3">Trạng thái</th>
              <th className="px-4 py-3" />
            </tr>
          </thead>
          <tbody>
            {rows?.map(row => {
              const status = !row.postId ? 'NONE' : row.published ? 'PUBLISHED' : 'DRAFT'
              return (
                <tr key={row.propertyId} className="border-t border-border">
                  <td className="px-4 py-3 text-fg">{row.propertyName}</td>
                  <td className="px-4 py-3 text-fg-muted">{postStatusLabel(status)}</td>
                  <td className="px-4 py-3 text-right">
                    <Link to={`/admin/blog/${row.propertyId}`} className="font-medium text-accent hover:text-accent-hover">
                      {row.postId ? 'Chỉnh sửa' : 'Tạo bài viết'}
                    </Link>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </div>
  )
}
```

- [ ] **Step 8: Run test to verify it passes**

Run: `cd htr-frontend && npx vitest run src/features/admin/pages/blog/AdminBlogListPage.test.tsx`
Expected: PASS

- [ ] **Step 9: Wire `/admin/blog` into `adminRoutes.tsx`**

```tsx
// router/adminRoutes.tsx — add import
import AdminBlogListPage from '@/features/admin/pages/blog/AdminBlogListPage'

// add to the adminRoutes array, using the existing narrower PLATFORM_ADMIN const (['ADMIN','PLATFORM_ADMIN'])
// per spec §5.3's explicit gating for the blog admin routes:
<Route key="/admin/blog" path="/admin/blog" element={<RequireRole roles={PLATFORM_ADMIN}><AdminBlogListPage /></RequireRole>} />,
```

- [ ] **Step 10: Run the full frontend unit test suite**

Run: `cd htr-frontend && npm run test:unit`
Expected: PASS

- [ ] **Step 11: Commit**

```bash
git add htr-frontend/src/lib/utils.ts htr-frontend/src/lib/utils.test.ts htr-frontend/src/features/admin/pages/blog/AdminBlogListPage.tsx htr-frontend/src/features/admin/pages/blog/AdminBlogListPage.test.tsx htr-frontend/src/router/adminRoutes.tsx
git commit -m "feat(blog): add admin blog list page"
```

### Task 26: `/admin/blog/:propertyId` editor (Tiptap WYSIWYG)

**Context:** no rich-text editor exists anywhere in this codebase (confirmed by research — `package.json` has no `tiptap`/`slate`/`draft-js`/`lexical`/`react-quill`). `@tiptap/react` + `@tiptap/starter-kit` is the choice for this plan — it's ProseMirror-based (no legacy `findDOMNode`/string-ref usage), so it's React-19-safe, unlike some older editors.

**Files:**
- Modify: `htr-frontend/package.json` (add `@tiptap/react`, `@tiptap/starter-kit`, `@tiptap/pm`)
- Create: `htr-frontend/src/features/admin/pages/blog/AdminBlogEditorPage.tsx`
- Modify: `htr-frontend/src/router/adminRoutes.tsx`
- Test: `htr-frontend/src/features/admin/pages/blog/AdminBlogEditorPage.test.tsx`

**Interfaces:**
- Consumes: `adminBlogApi.{get, update, generateDraft, uploadCoverImage, publish, unpublish}` (Task 21), `useGuardedMutation`.
- Produces: `export default function AdminBlogEditorPage()` — routed at `/admin/blog/:propertyId`.

- [ ] **Step 1: Install the editor dependency**

```bash
cd htr-frontend && npm install @tiptap/react @tiptap/starter-kit @tiptap/pm
```

- [ ] **Step 2: Write the failing test (mocking Tiptap — ProseMirror's DOM range APIs are unreliable in jsdom, so the test verifies this page's own logic, not the editor library's internals)**

```tsx
// src/features/admin/pages/blog/AdminBlogEditorPage.test.tsx
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { adminBlogApi } from '@/api'
import AdminBlogEditorPage from './AdminBlogEditorPage'

vi.mock('@tiptap/react', () => ({
  useEditor: () => ({ getHTML: () => '<p>Nội dung</p>', commands: { setContent: vi.fn() } }),
  EditorContent: () => <div data-testid="editor-content" />,
}))
vi.mock('@tiptap/starter-kit', () => ({ default: {} }))
vi.mock('@/api', () => ({
  adminBlogApi: { get: vi.fn(), update: vi.fn(), generateDraft: vi.fn(), uploadCoverImage: vi.fn(), publish: vi.fn(), unpublish: vi.fn() },
}))

function renderAtProperty(propertyId: string) {
  const client = new QueryClient()
  return render(
    <QueryClientProvider client={client}>
      <MemoryRouter initialEntries={[`/admin/blog/${propertyId}`]}>
        <Routes>
          <Route path="/admin/blog/:propertyId" element={<AdminBlogEditorPage />} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>
  )
}

describe('AdminBlogEditorPage', () => {
  beforeEach(() => vi.mocked(adminBlogApi.get).mockReset())

  it('shows a not-yet-created hint when no post exists for the property', async () => {
    vi.mocked(adminBlogApi.get).mockRejectedValue({ isAxiosError: true, response: { status: 404 } })

    renderAtProperty('prop-1')

    expect(await screen.findByText(/chưa có bài viết/i)).toBeInTheDocument()
  })

  it('saves the title and generated content on submit', async () => {
    vi.mocked(adminBlogApi.get).mockRejectedValue({ isAxiosError: true, response: { status: 404 } })
    vi.mocked(adminBlogApi.update).mockResolvedValue({
      id: '1', propertyId: 'prop-1', propertyName: 'Nhà A', title: 'Bài viết mới', slug: 'bai-viet-moi',
      content: '<p>Nội dung</p>', coverImageUrl: null, published: false, publishedAt: null,
      authorId: null, authorName: null, createdAt: '', updatedAt: '',
    })

    renderAtProperty('prop-1')
    await screen.findByText(/chưa có bài viết/i)

    fireEvent.change(screen.getByLabelText(/tiêu đề/i), { target: { value: 'Bài viết mới' } })
    fireEvent.click(screen.getByRole('button', { name: /lưu bài viết/i }))

    await waitFor(() => expect(adminBlogApi.update).toHaveBeenCalledWith('prop-1', {
      title: 'Bài viết mới', slug: '', content: '<p>Nội dung</p>', coverImageUrl: undefined,
    }))
  })

  it('fills the title from the generated draft', async () => {
    vi.mocked(adminBlogApi.get).mockRejectedValue({ isAxiosError: true, response: { status: 404 } })
    vi.mocked(adminBlogApi.generateDraft).mockResolvedValue({
      title: 'Nhà A - Cho thuê phòng trọ', content: '<h2>Nhà A</h2>', coverImageUrl: null,
    })

    renderAtProperty('prop-1')
    await screen.findByText(/chưa có bài viết/i)

    fireEvent.click(screen.getByRole('button', { name: /tạo bản nháp tự động/i }))

    await waitFor(() => expect(screen.getByLabelText(/tiêu đề/i)).toHaveValue('Nhà A - Cho thuê phòng trọ'))
  })
})
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd htr-frontend && npx vitest run src/features/admin/pages/blog/AdminBlogEditorPage.test.tsx`
Expected: FAIL — `Cannot find module './AdminBlogEditorPage'`

- [ ] **Step 4: Create `AdminBlogEditorPage.tsx`**

```tsx
// src/features/admin/pages/blog/AdminBlogEditorPage.tsx
import { useState, useEffect } from 'react'
import { useParams } from 'react-router-dom'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useEditor, EditorContent } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import { adminBlogApi } from '@/api'
import { useGuardedMutation } from '@/hooks/useGuardedMutation'
import { showToast } from '@/lib/toast'
import { getErrorMessage } from '@/lib/apiError'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

export default function AdminBlogEditorPage() {
  const { propertyId = '' } = useParams<{ propertyId: string }>()
  const qc = useQueryClient()
  const [title, setTitle] = useState('')
  const [slug, setSlug] = useState('')
  const [coverImageUrl, setCoverImageUrl] = useState<string | null>(null)

  const { data: post, isError } = useQuery({
    queryKey: ['admin-blog-post', propertyId],
    queryFn: () => adminBlogApi.get(propertyId),
    enabled: !!propertyId,
    retry: false,
  })

  const editor = useEditor({ extensions: [StarterKit], content: '' })

  useEffect(() => {
    if (post) {
      setTitle(post.title)
      setSlug(post.slug)
      setCoverImageUrl(post.coverImageUrl)
      editor?.commands.setContent(post.content ?? '')
    }
  }, [post, editor])

  const save = useGuardedMutation({
    mutationFn: () => adminBlogApi.update(propertyId, {
      title,
      slug: slug || undefined,
      content: editor?.getHTML() ?? '',
      coverImageUrl: coverImageUrl ?? undefined,
    }),
    onSuccess: () => {
      showToast({ message: 'Đã lưu bài viết', type: 'success' })
      qc.invalidateQueries({ queryKey: ['admin-blog-post', propertyId] })
      qc.invalidateQueries({ queryKey: ['admin-blog-posts'] })
    },
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Lưu bài viết thất bại'), type: 'error' }),
  })

  const generateDraft = useGuardedMutation({
    mutationFn: () => adminBlogApi.generateDraft(propertyId),
    onSuccess: draft => {
      setTitle(draft.title)
      editor?.commands.setContent(draft.content)
      if (draft.coverImageUrl) setCoverImageUrl(draft.coverImageUrl)
    },
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Tạo bản nháp thất bại'), type: 'error' }),
  })

  const togglePublish = useGuardedMutation({
    mutationFn: () => (post?.published ? adminBlogApi.unpublish(propertyId) : adminBlogApi.publish(propertyId)),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-blog-post', propertyId] }),
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Cập nhật trạng thái thất bại'), type: 'error' }),
  })

  const uploadCoverImage = useGuardedMutation({
    mutationFn: (file: File) => adminBlogApi.uploadCoverImage(propertyId, file),
    onSuccess: updated => setCoverImageUrl(updated.coverImageUrl),
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Tải ảnh bìa thất bại'), type: 'error' }),
  })

  return (
    <div className="p-8">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-semibold text-fg">Soạn bài viết</h1>
        <div className="flex items-center gap-2">
          {post?.published && (
            <a href={`/blog/${post.slug}`} target="_blank" rel="noreferrer" className="text-sm font-medium text-accent hover:text-accent-hover">
              Xem trước
            </a>
          )}
          <Button type="button" variant="secondary" onClick={() => generateDraft.mutate(undefined)} loading={generateDraft.isPending}>
            Tạo bản nháp tự động
          </Button>
          {post && (
            <Button type="button" variant="secondary" onClick={() => togglePublish.mutate(undefined)} loading={togglePublish.isPending}>
              {post.published ? 'Gỡ xuất bản' : 'Xuất bản'}
            </Button>
          )}
        </div>
      </div>

      {isError && !post && (
        <p className="mt-4 text-sm text-fg-muted">
          Chưa có bài viết cho nhà trọ này — điền thông tin và lưu để tạo mới, hoặc bấm &quot;Tạo bản nháp tự động&quot;.
        </p>
      )}

      <div className="mt-6 space-y-5">
        <Input label="Tiêu đề" value={title} onChange={e => setTitle(e.target.value)} required />
        <Input label="Đường dẫn (slug)" value={slug} onChange={e => setSlug(e.target.value)} hint="Để trống để tự tạo từ tiêu đề" />

        <div>
          <p className="mb-2 text-sm font-medium text-fg">Ảnh bìa</p>
          {coverImageUrl && <img src={coverImageUrl} alt="" className="mb-2 h-40 w-full rounded-xl object-cover" />}
          <input
            type="file"
            accept="image/*"
            onChange={e => {
              const file = e.target.files?.[0]
              if (file) uploadCoverImage.mutate(file)
            }}
          />
        </div>

        <div>
          <p className="mb-2 text-sm font-medium text-fg">Nội dung</p>
          <div className="rounded-xl border border-border bg-bg p-3">
            <EditorContent editor={editor} />
          </div>
        </div>

        <Button type="button" onClick={() => save.mutate(undefined)} loading={save.isPending}>
          Lưu bài viết
        </Button>
      </div>
    </div>
  )
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd htr-frontend && npx vitest run src/features/admin/pages/blog/AdminBlogEditorPage.test.tsx`
Expected: PASS

- [ ] **Step 6: Wire `/admin/blog/:propertyId` into `adminRoutes.tsx`**

```tsx
// router/adminRoutes.tsx — add import
import AdminBlogEditorPage from '@/features/admin/pages/blog/AdminBlogEditorPage'

// add to the adminRoutes array
<Route key="/admin/blog/:propertyId" path="/admin/blog/:propertyId" element={<RequireRole roles={PLATFORM_ADMIN}><AdminBlogEditorPage /></RequireRole>} />,
```

- [ ] **Step 7: Run the full frontend unit test suite**

Run: `cd htr-frontend && npm run test:unit`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add htr-frontend/package.json htr-frontend/package-lock.json htr-frontend/src/features/admin/pages/blog/AdminBlogEditorPage.tsx htr-frontend/src/features/admin/pages/blog/AdminBlogEditorPage.test.tsx htr-frontend/src/router/adminRoutes.tsx
git commit -m "feat(blog): add admin blog editor page with Tiptap WYSIWYG"
```

### Task 27: `/admin/blog/comments` moderation page

**Files:**
- Create: `htr-frontend/src/features/admin/pages/blog/AdminBlogCommentsPage.tsx`
- Modify: `htr-frontend/src/router/adminRoutes.tsx`
- Test: `htr-frontend/src/features/admin/pages/blog/AdminBlogCommentsPage.test.tsx`

**Interfaces:**
- Consumes: `adminBlogApi.{listComments, deleteComment}` (Task 21), `Dialog` (`@/components/ui/dialog` — existing, confirm-before-destructive-action per this repo's convention).
- Produces: `export default function AdminBlogCommentsPage()` — routed at `/admin/blog/comments`.

- [ ] **Step 1: Write the failing test**

```tsx
// src/features/admin/pages/blog/AdminBlogCommentsPage.test.tsx
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { adminBlogApi } from '@/api'
import AdminBlogCommentsPage from './AdminBlogCommentsPage'

vi.mock('@/api', () => ({
  adminBlogApi: { listComments: vi.fn(), deleteComment: vi.fn() },
}))

function renderPage() {
  const client = new QueryClient()
  return render(
    <QueryClientProvider client={client}>
      <MemoryRouter><AdminBlogCommentsPage /></MemoryRouter>
    </QueryClientProvider>
  )
}

describe('AdminBlogCommentsPage', () => {
  beforeEach(() => {
    vi.mocked(adminBlogApi.listComments).mockResolvedValue([
      { id: 'c1', content: 'Spam link…', userId: 'u1', userName: 'Khách X', postId: 'p1', postTitle: 'Bài A', postSlug: 'bai-a', createdAt: '2026-08-01T00:00:00' },
    ])
    vi.mocked(adminBlogApi.deleteComment).mockResolvedValue(undefined)
  })

  it('lists comments with post context and deletes after confirmation', async () => {
    renderPage()

    expect(await screen.findByText('Spam link…')).toBeInTheDocument()
    expect(screen.getByText('Bài A')).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: /xóa/i }))
    expect(await screen.findByText(/xóa bình luận này/i)).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: /xác nhận xóa/i }))

    await waitFor(() => expect(adminBlogApi.deleteComment).toHaveBeenCalledWith('c1'))
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-frontend && npx vitest run src/features/admin/pages/blog/AdminBlogCommentsPage.test.tsx`
Expected: FAIL — `Cannot find module './AdminBlogCommentsPage'`

- [ ] **Step 3: Create `AdminBlogCommentsPage.tsx`**

```tsx
// src/features/admin/pages/blog/AdminBlogCommentsPage.tsx
import { useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { adminBlogApi } from '@/api'
import { useGuardedMutation } from '@/hooks/useGuardedMutation'
import { showToast } from '@/lib/toast'
import { getErrorMessage } from '@/lib/apiError'
import { Dialog } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'

export default function AdminBlogCommentsPage() {
  const qc = useQueryClient()
  const [pendingDeleteId, setPendingDeleteId] = useState<string | null>(null)

  const { data: comments, isLoading } = useQuery({
    queryKey: ['admin-blog-comments'],
    queryFn: adminBlogApi.listComments,
  })

  const deleteComment = useGuardedMutation({
    mutationFn: (id: string) => adminBlogApi.deleteComment(id),
    onSuccess: () => {
      setPendingDeleteId(null)
      qc.invalidateQueries({ queryKey: ['admin-blog-comments'] })
    },
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Xóa bình luận thất bại'), type: 'error' }),
  })

  return (
    <div className="p-8">
      <h1 className="text-xl font-semibold text-fg">Kiểm duyệt bình luận</h1>

      {isLoading && <p className="mt-6 text-sm text-fg-muted">Đang tải…</p>}

      <ul className="mt-6 space-y-4">
        {comments?.map(comment => (
          <li key={comment.id} className="rounded-2xl border border-border bg-surface p-4">
            <div className="flex items-start justify-between gap-4">
              <div>
                <p className="text-sm font-medium text-fg">{comment.userName} · {comment.postTitle}</p>
                <p className="mt-1 text-sm text-fg-muted">{comment.content}</p>
              </div>
              <Button type="button" variant="danger" onClick={() => setPendingDeleteId(comment.id)}>
                Xóa
              </Button>
            </div>
          </li>
        ))}
      </ul>

      <Dialog open={!!pendingDeleteId} onClose={() => setPendingDeleteId(null)} title="Xóa bình luận này?">
        <div className="space-y-5">
          <p className="text-sm leading-6 text-fg-muted">Bình luận sẽ bị xóa vĩnh viễn và không thể khôi phục.</p>
          <div className="flex justify-end gap-2">
            <Button type="button" variant="secondary" onClick={() => setPendingDeleteId(null)}>Hủy</Button>
            <Button
              type="button"
              variant="danger"
              onClick={() => pendingDeleteId && deleteComment.mutate(pendingDeleteId)}
              loading={deleteComment.isPending}
            >
              Xác nhận xóa
            </Button>
          </div>
        </div>
      </Dialog>
    </div>
  )
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd htr-frontend && npx vitest run src/features/admin/pages/blog/AdminBlogCommentsPage.test.tsx`
Expected: PASS

- [ ] **Step 5: Wire `/admin/blog/comments` into `adminRoutes.tsx`**

```tsx
// router/adminRoutes.tsx — add import
import AdminBlogCommentsPage from '@/features/admin/pages/blog/AdminBlogCommentsPage'

// add to the adminRoutes array
<Route key="/admin/blog/comments" path="/admin/blog/comments" element={<RequireRole roles={PLATFORM_ADMIN}><AdminBlogCommentsPage /></RequireRole>} />,
```

**Note on route ordering:** react-router v7 matches by specificity, not array order, so `/admin/blog/comments` and `/admin/blog/:propertyId` don't conflict — but keep `/admin/blog/comments` visually grouped next to the other two blog routes for readability, order doesn't affect matching here.

- [ ] **Step 6: Run the full frontend unit test suite**

Run: `cd htr-frontend && npm run test:unit`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add htr-frontend/src/features/admin/pages/blog/AdminBlogCommentsPage.tsx htr-frontend/src/features/admin/pages/blog/AdminBlogCommentsPage.test.tsx htr-frontend/src/router/adminRoutes.tsx
git commit -m "feat(blog): add admin comment moderation page"
```

---

## Phase 11 — Frontend: SEO

### Task 28: `useDocumentMeta` hook (real implementation) + `robots.txt`

**Context:** Task 23 created a no-op stub of this hook so `BlogPostPage.tsx` would compile before this task landed. This task replaces it with the real implementation and adds the static `robots.txt`.

**Files:**
- Modify: `htr-frontend/src/hooks/useDocumentMeta.ts`
- Create: `htr-frontend/src/hooks/useDocumentMeta.test.ts`
- Create: `htr-frontend/public/robots.txt`

**Interfaces:**
- Produces: `useDocumentMeta(title: string, description: string): void` — already consumed by `BlogPostPage.tsx` (Task 23); no other call sites need updating since the signature is unchanged from the stub.

- [ ] **Step 1: Write the failing test**

```ts
// src/hooks/useDocumentMeta.test.ts
import { describe, it, expect, afterEach } from 'vitest'
import { renderHook } from '@testing-library/react'
import { useDocumentMeta } from './useDocumentMeta'

describe('useDocumentMeta', () => {
  afterEach(() => {
    document.title = ''
    document.querySelector('meta[name="description"]')?.remove()
  })

  it('sets document.title and the description meta tag', () => {
    renderHook(() => useDocumentMeta('Phòng trọ đẹp · HowsTheRent', 'Nhà trọ Xanh — 12 Lê Lợi'))

    expect(document.title).toBe('Phòng trọ đẹp · HowsTheRent')
    expect(document.querySelector('meta[name="description"]')?.getAttribute('content'))
      .toBe('Nhà trọ Xanh — 12 Lê Lợi')
  })

  it('reuses an existing meta tag instead of creating duplicates', () => {
    const { rerender } = renderHook(
      ({ title, description }) => useDocumentMeta(title, description),
      { initialProps: { title: 'A', description: 'first' } }
    )
    rerender({ title: 'B', description: 'second' })

    expect(document.querySelectorAll('meta[name="description"]')).toHaveLength(1)
    expect(document.querySelector('meta[name="description"]')?.getAttribute('content')).toBe('second')
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd htr-frontend && npx vitest run src/hooks/useDocumentMeta.test.ts`
Expected: FAIL — the current stub is a no-op, so `document.title` stays `''` and no meta tag is created

- [ ] **Step 3: Replace the stub with the real implementation**

```ts
// src/hooks/useDocumentMeta.ts
import { useEffect } from 'react'

export function useDocumentMeta(title: string, description: string) {
  useEffect(() => {
    if (title) {
      document.title = title
    }
    if (description) {
      let meta = document.querySelector<HTMLMetaElement>('meta[name="description"]')
      if (!meta) {
        meta = document.createElement('meta')
        meta.setAttribute('name', 'description')
        document.head.appendChild(meta)
      }
      meta.setAttribute('content', description)
    }
  }, [title, description])
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd htr-frontend && npx vitest run src/hooks/useDocumentMeta.test.ts`
Expected: PASS

- [ ] **Step 5: Add `robots.txt`**

```
# htr-frontend/public/robots.txt
User-agent: *
Allow: /blog
Allow: /blog/*
Disallow: /admin
Disallow: /tenant
Disallow: /tech

Sitemap: https://REPLACE_WITH_PRODUCTION_DOMAIN/sitemap.xml
```

Vite serves everything under `public/` from the site root unchanged, so this becomes `https://<domain>/robots.txt` with no routing changes needed. Replace `REPLACE_WITH_PRODUCTION_DOMAIN` with the actual production domain at deploy time (same domain `PUBLIC_BASE_URL` is set to for Task 18's `SitemapController`).

- [ ] **Step 6: Run the full frontend unit test suite and build**

Run: `cd htr-frontend && npm run test:unit && npm run build`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add htr-frontend/src/hooks/useDocumentMeta.ts htr-frontend/src/hooks/useDocumentMeta.test.ts htr-frontend/public/robots.txt
git commit -m "feat(blog): add per-post SEO meta tags and robots.txt"
```

---

## Final verification

### Task 29: Full-stack manual verification

**Context:** per spec §7.1.4, this follows `CLAUDE.md`'s "Manual full-stack verification recipe" rather than rediscovering the local-dev setup from scratch.

- [ ] **Step 1: Start the stack**

```bash
docker compose up -d postgres redis minio
```

- [ ] **Step 2: Start the backend with the required env var overrides (CLAUDE.md gotcha #1)**

```bash
CORS_ALLOWED_ORIGINS="http://localhost:5173,http://localhost:3000" \
MINIO_URL="http://localhost:9000" MINIO_PUBLIC_URL="http://localhost:9000/htr" \
MINIO_ACCESS_KEY="minioadmin" MINIO_SECRET_KEY="minioadmin" MINIO_AUTO_CREATE_BUCKET="true" \
cd htr-backend && ./mvnw spring-boot:run
```

- [ ] **Step 2: Apply the seed/password/MinIO-policy workarounds (CLAUDE.md gotchas #2, #3, #4 — this feature touches images via cover uploads and the auto-draft generator's room photos, so #4 applies)**

Follow `CLAUDE.md`'s exact commands: fix `seed.sql`'s missing `auth_version` default, reset the admin password hash, set the MinIO bucket's public-read policy.

- [ ] **Step 3: Start the frontend**

```bash
cd htr-frontend && npm run dev
```

- [ ] **Step 4: Drive the flow with Playwright, covering the feature's critical path end to end**

1. Log in as the seeded admin, go to `/admin/blog`, confirm every property lists with "Chưa có bài viết".
2. Open a property's editor at `/admin/blog/:propertyId`, click "Tạo bản nháp tự động", confirm title/content/cover image populate from real room data.
3. Save, then "Xuất bản" — confirm the "Xem trước" link appears and opens `/blog/:slug` in a new tab showing the published content and live vacancy count.
4. Log out, visit `/blog` unauthenticated — confirm the post appears with the correct vacancy badge, and `/blog/:slug` shows "Đăng nhập để bình luận" instead of a comment form.
5. Go to `/blog/register`, create a `GUEST` account — confirm it logs in automatically and lands on `/blog` (not `/tech`).
6. As the logged-in `GUEST`, post a comment and click the like button on `/blog/:slug` — confirm both appear/update without a page reload.
7. Log back in as admin, go to `/admin/blog/comments`, confirm the guest's comment appears with post context, delete it with the confirm dialog, confirm it disappears from the public page.
8. Hit `GET /sitemap.xml` and `GET /robots.txt` directly — confirm the sitemap lists the published post's URL and robots.txt allows `/blog`.
9. As a spot-check on Task 2's hardening: log in as a `TENANT` (or any pre-existing seeded role) and confirm `GET /api/properties/{id}`, `GET /api/users/me`, and one maintenance endpoint still work exactly as before (regression check, not new behavior).

- [ ] **Step 5: Tear down**

```bash
# stop backend and frontend processes
docker compose down -v
git status --short   # confirm clean before considering this plan done
```

- [ ] **Step 6: Update the feature tracker**

Mark blog (#5) as implemented in `docs/superpowers/plans/2026-08-30-htr-feature-tracker.md`, following the same format used for the other four tracked features.

---

## Self-review notes

- **Spec coverage:** every numbered section of `docs/superpowers/specs/2026-08-30-htr-blog-design.md` maps to a task — §3 data model → Tasks 3–5; §4.1 `GUEST` role + hardening → Tasks 1–2; §4.1 register endpoint → Task 6; §4.2 public/authenticated/admin endpoints → Tasks 7–17; §5.1 public routes + `PublicShell` → Tasks 19–20, 22–24; §5.2 redirect fixes → Task 19; §5.3 admin routes → Tasks 25–27; §6 SEO → Tasks 18, 28; §7.1's four mandatory rules → the Global Constraints block plus Tasks 1–2 (rule 1: no cookie change — enforced by reusing `setTokenCookies` verbatim in Task 6, never introducing a new cookie name; rule 2: `@Transactional(readOnly=true)`/`@EntityGraph` — applied to every `PostService` method from Task 8 onward; rule 3: hardening before `GUEST` login — Task 2 ordered before Task 6; rule 4: manual verification recipe — Task 29). The one spec gap found (§5.3's `/admin/blog/comments` list needs a `GET` the spec's endpoint table never names) is called out explicitly in Task 17 and filled rather than silently worked around.
- **Placeholder scan:** no `TODO`/`TBD`/"add appropriate handling" phrasing anywhere in the task bodies; every code block is complete, copy-pasteable source, not a description of source.
- **Type/name consistency checked across tasks:** `PostService` method names (`listPublished`, `getPublishedBySlug`, `listComments`, `addComment`, `like`, `unlike`, `listAllForAdmin`, `getForAdmin`, `upsertPost`, `generateDraft`, `uploadCoverImage`, `publish`, `unpublish`, `listAllCommentsForAdmin`, `deleteComment`) are each defined exactly once (in the task that introduces them) and referenced identically by every later task and by `blogApi.ts`/`adminBlogApi.ts`'s method names, which mirror them 1:1. DTO field names (`emptyRoomCount`/`totalRoomCount` on `BlogPostSummaryResponse`, `liked`/`likeCount` on `LikeStatusResponse`, `published`/`publishedAt` on both `Post` and every DTO derived from it) are consistent between the Java records, their `blogApi.ts`/`adminBlogApi.ts` TypeScript mirrors, and every test that constructs them. `homePathForRole` (Task 19) is the single definition consumed by both `App.tsx` and `LoginPage.tsx` — no divergent second implementation was left behind.
