# GitHub Actions and Render CI/CD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a reproducible four-check GitHub Actions CI gate and configure the existing Vercel/Render Git integrations to release `master` only after the shared gate passes.

**Architecture:** GitHub Actions validates frontend, backend, and the backend Docker image, then publishes a stable aggregate `Release gate` check. Vercel uses that check as a production promotion gate, while Render uses `autoDeployTrigger: checksPass` plus `/api/health`; neither platform is deployed directly by GitHub Actions. The two platform releases remain non-atomic, so the runbook requires compatible API changes, paired-SHA tracking, and schema-aware recovery.

**Tech Stack:** GitHub Actions, Node.js 22, npm, React/Vite/TypeScript, Java 21, Maven Wrapper 3.9.15, Spring Boot 4, H2, Docker, Render Blueprint, Vercel Git Integration

## Global Constraints

- Target branch is exactly `master`.
- Required check display names are exactly `Frontend quality`, `Backend verify`, `Backend Docker build`, and `Release gate`.
- GitHub Actions receives no application, database, Render, or Vercel secrets.
- CI uses Node.js 22 and npm; npm/Bun standardization is out of scope.
- Backend tests use Java 21 and H2 under the `test` Spring profile; production PostgreSQL is never contacted.
- Render remains the only automatic backend deployment authority; Vercel remains the only automatic frontend deployment authority.
- Do not add deploy hooks, Vercel CLI deployment, Render API deployment, `workflow_dispatch`, or path filters.
- Do not add placeholder frontend tests, skipped/only tests, Flyway/Liquibase, staging, or a production probe.
- Schema changes must remain expand/contract compatible; Render image rollback does not rollback PostgreSQL schema.
- Negative production-equivalent gate behavior remains an explicitly documented residual risk until a separate staging/shadow project is approved.
- Each command block is independent and must start from the active worktree's repository root; do not rely on `cd` from a prior step.
- The four implementation commits in this plan require explicit user authorization before execution. The user selected subagent-driven implementation after the first plan draft, which authorizes these local implementation commits but does not authorize pushing or changing external dashboard settings.

---

## File Structure

- Create `.github/workflows/ci.yml`: owns CI triggers, four stable checks, job dependency order, and fail-closed aggregate gate.
- Modify `.gitignore`: selectively exposes only `.github/workflows/ci.yml` while keeping other `.github` operational artifacts ignored.
- Create `htr-backend/src/test/resources/application-test.properties`: owns isolated H2 and disabled MinIO bucket initialization for the `test` profile.
- Modify `render.yaml`: owns Render's native `checksPass` trigger and shallow HTTP health-check path.
- Modify `DEPLOYMENT.md`: owns external GitHub/Vercel/Render setup, activation order, paired-SHA recovery, break-glass policy, and residual-risk disclosure.
- Do not modify `htr-backend/pom.xml`: H2 already exists at test scope.
- Do not modify `docs/DEPLOYMENT.md`: it is the separate provider-agnostic guide.
- Do not modify `PropertyTypeMigration.java` unless Task 1 produces direct evidence that the clean H2 profile executes its PostgreSQL-specific migration branch; such evidence requires stopping and revising this plan before expanding scope.

---

### Task 1: Isolate Backend Verification with H2

**Files:**
- Create: `htr-backend/src/test/resources/application-test.properties`
- Inspect only: `htr-backend/src/main/resources/application.properties:1-10,30-36`
- Inspect only: `htr-backend/src/main/java/chez1s/htrbackend/config/PropertyTypeMigration.java:15-90`
- Test: `htr-backend/src/test/java/chez1s/htrbackend/HtrBackendApplicationTests.java`

**Interfaces:**
- Consumes: Spring profile name `test`, existing test-scope `com.h2database:h2`, existing `@SpringBootTest` context load.
- Produces: `SPRING_PROFILES_ACTIVE=test ./mvnw --batch-mode verify` that succeeds without `.env`, PostgreSQL, `DB_URL`, `DB_USER`, `DB_PASSWORD`, or MinIO network initialization.

- [ ] **Step 1: Record the current failure or unexpected baseline**

Run from the repository root in a clean tracked snapshot:

```bash
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git archive --format=tar HEAD htr-backend | tar -xf - -C "$tmp"

docker run --rm \
  --volume "$tmp/htr-backend:/workspace" \
  --workdir /workspace \
  --env SPRING_PROFILES_ACTIVE=test \
  eclipse-temurin:21-jdk \
  sh -lc '
    env -u DB_URL -u DB_USER -u DB_PASSWORD \
      ./mvnw --batch-mode verify
  '
```

Expected before implementation: non-zero exit because the nonexistent `test` profile does not override `jdbc:postgresql://localhost:5432/htr`. If it unexpectedly passes, capture the effective datasource from logs and continue only after confirming no host database or environment value was used.

- [ ] **Step 2: Create the isolated test profile**

Create `htr-backend/src/test/resources/application-test.properties` with exactly:

```properties
spring.datasource.url=jdbc:h2:mem:htr;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.hibernate.ddl-auto=create-drop
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.H2Dialect
minio.auto-create-bucket=false
```

Why each non-obvious line exists:

- `MODE=PostgreSQL` improves SQL/type compatibility but does not make H2 a PostgreSQL replacement.
- `DATABASE_TO_LOWER=TRUE` keeps `information_schema` table/column matching aligned with `PropertyTypeMigration`.
- `create-drop` ensures each context test gets an isolated schema.
- The explicit H2 dialect overrides the PostgreSQL dialect inherited from the main properties file.
- `minio.auto-create-bucket=false` prevents a context test from attempting localhost object-storage initialization.

- [ ] **Step 3: Run backend verification from the working tree**

```bash
(
  cd "$(git rev-parse --show-toplevel)/htr-backend"
  env -u DB_URL -u DB_USER -u DB_PASSWORD \
    SPRING_PROFILES_ACTIVE=test \
    ./mvnw --batch-mode verify
)
```

Expected: exit code `0`, including `HtrBackendApplicationTests.contextLoads`.

- [ ] **Step 4: Stage the profile so the tracked-snapshot test includes it**

```bash
repo="$(git rev-parse --show-toplevel)"
git -C "$repo" add htr-backend/src/test/resources/application-test.properties
git -C "$repo" diff --cached --check
```

Expected: no output from `git diff --cached --check`.

- [ ] **Step 5: Verify isolation in a fresh tracked snapshot**

`git checkout-index` includes staged files without copying ignored root `.env`:

```bash
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git checkout-index --all --prefix="$tmp/"

docker run --rm \
  --volume "$tmp/htr-backend:/workspace" \
  --workdir /workspace \
  --env SPRING_PROFILES_ACTIVE=test \
  --env SPRING_JPA_SHOW_SQL=true \
  eclipse-temurin:21-jdk \
  sh -lc '
    env -u DB_URL -u DB_USER -u DB_PASSWORD \
      ./mvnw --batch-mode verify >/tmp/backend-verify.log 2>&1
    rc=$?
    cat /tmp/backend-verify.log
    if [ "$rc" -ne 0 ]; then
      exit "$rc"
    fi
    if grep -Eiq "jdbc:postgresql://localhost|type_uuid" /tmp/backend-verify.log; then
      echo "unexpected production datasource or destructive migration SQL" >&2
      exit 1
    fi
  '
```

Expected: exit code `0`; no PostgreSQL localhost connection and no destructive `PropertyTypeMigration` branch.

If the command fails because H2 reports `properties.type` as a non-UUID type and the migration runs its PostgreSQL-specific SQL, stop this task. Do not suppress or edit the migration opportunistically; revise the design/plan with a narrow, tested PostgreSQL-only migration guard.

- [ ] **Step 6: Commit the isolated backend profile**

This step is authorized only after the user explicitly approves implementation with commits. Otherwise stop before executing it.

```bash
git diff --cached --name-only
git commit \
  -m "test(backend): isolate verification with H2" \
  -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

Expected staged path before commit:

```text
htr-backend/src/test/resources/application-test.properties
```

---

### Task 2: Add the Four-Check GitHub Actions Gate

**Files:**
- Modify: `.gitignore:1-3`
- Create: `.github/workflows/ci.yml`
- Test: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: npm lockfile `htr-frontend/package-lock.json`, frontend scripts `lint` and `build`, backend command from Task 1, Docker context `htr-backend`.
- Produces: four unique GitHub check names, with `Release gate` succeeding only when all three implementation jobs report `success`.

- [ ] **Step 1: Prove that `.github` is currently ignored**

```bash
git check-ignore -v .github/workflows/ci.yml
```

Expected before implementation:

```text
.gitignore:2:/.github/ .github/workflows/ci.yml
```

- [ ] **Step 2: Selectively expose only the CI workflow**

Change `.gitignore` from:

```gitignore
/.omc/
/.github/
/.claude/
```

to:

```gitignore
/.omc/
/.github/*
!/.github/workflows/
/.github/workflows/*
!/.github/workflows/ci.yml
/.claude/
```

This keeps `.github/modernize/` and any future non-workflow operational artifacts ignored while versioning only `ci.yml`. Do not modify any other ignore rule.

- [ ] **Step 3: Create the complete workflow**

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  pull_request:
    branches:
      - master
  push:
    branches:
      - master

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

jobs:
  frontend-quality:
    name: Frontend quality
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: htr-frontend
    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
          cache-dependency-path: htr-frontend/package-lock.json

      - name: Install frontend dependencies
        run: npm ci

      - name: Lint frontend
        run: npm run lint

      - name: Build frontend
        run: npm run build

  backend-verify:
    name: Backend verify
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: htr-backend
    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 21
          cache: maven
          cache-dependency-path: htr-backend/pom.xml

      - name: Verify backend
        env:
          SPRING_PROFILES_ACTIVE: test
        run: ./mvnw --batch-mode verify

  backend-docker-build:
    name: Backend Docker build
    runs-on: ubuntu-latest
    needs:
      - backend-verify
    defaults:
      run:
        working-directory: htr-backend
    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Build backend image
        run: docker build --tag htr-backend:ci .

  release-gate:
    name: Release gate
    runs-on: ubuntu-latest
    if: ${{ always() }}
    needs:
      - frontend-quality
      - backend-verify
      - backend-docker-build
    steps:
      - name: Require all CI jobs to pass
        env:
          FRONTEND_RESULT: ${{ needs.frontend-quality.result }}
          BACKEND_RESULT: ${{ needs.backend-verify.result }}
          DOCKER_RESULT: ${{ needs.backend-docker-build.result }}
        run: |
          test "$FRONTEND_RESULT" = success
          test "$BACKEND_RESULT" = success
          test "$DOCKER_RESULT" = success
```

The Maven wrapper is already executable in git; do not add a chmod step unless an actual clean-runner failure proves it is necessary.

- [ ] **Step 4: Verify the workflow is trackable and operational artifacts remain ignored**

```bash
if git check-ignore -q .github/workflows/ci.yml; then
  echo ".github/workflows/ci.yml is still ignored" >&2
  exit 1
fi

if ! git check-ignore -q .github/modernize/java-upgrade/.gitignore; then
  echo ".github/modernize artifacts are unexpectedly exposed" >&2
  exit 1
fi

git status --short -- .gitignore .github/workflows/ci.yml .github/modernize
```

Expected: `.gitignore` modified and `.github/workflows/ci.yml` untracked, not ignored; `.github/modernize/` remains absent from status.

- [ ] **Step 5: Lint the workflow**

Prefer an installed `actionlint`:

```bash
actionlint .github/workflows/ci.yml
```

If unavailable, use the pinned container:

```bash
docker run --rm \
  --volume "$PWD:/repo" \
  --workdir /repo \
  rhysd/actionlint:1.7.7 \
  .github/workflows/ci.yml
```

Expected: exit code `0` and no diagnostics. The first GitHub pull-request run remains the authoritative platform parser/execution check.

- [ ] **Step 6: Verify the aggregate gate's truth table locally**

```bash
gate='test "$FRONTEND_RESULT" = success &&
      test "$BACKEND_RESULT" = success &&
      test "$DOCKER_RESULT" = success'

env FRONTEND_RESULT=success BACKEND_RESULT=success DOCKER_RESULT=success \
  sh -c "$gate"

! env FRONTEND_RESULT=failure BACKEND_RESULT=success DOCKER_RESULT=success \
  sh -c "$gate"

! env FRONTEND_RESULT=success BACKEND_RESULT=cancelled DOCKER_RESULT=success \
  sh -c "$gate"

! env FRONTEND_RESULT=success BACKEND_RESULT=success DOCKER_RESULT=skipped \
  sh -c "$gate"
```

Expected: the first command succeeds; all three negated commands observe a failure.

- [ ] **Step 7: Scan for forbidden deployment behavior or credentials**

```bash
if grep -nE \
  '\$\{\{[[:space:]]*secrets\.|VERCEL_TOKEN[[:space:]]*[:=]|RENDER_(API_KEY|DEPLOY_HOOK)[[:space:]]*[:=]|(^|[[:space:]])vercel[[:space:]]+deploy|render[[:space:]]+deploy|workflow_dispatch' \
  .github/workflows/ci.yml; then
  echo "forbidden deploy behavior or credential found" >&2
  exit 1
fi
```

Expected: no matches.

- [ ] **Step 8: Commit the CI gate**

This local commit is covered by the user's selected subagent-driven implementation mode; do not push it.

```bash
git add .gitignore .github/workflows/ci.yml
git diff --cached --check
git diff --cached --name-only
git commit \
  -m "ci: add GitHub release eligibility gate" \
  -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

Expected staged paths before commit:

```text
.github/workflows/ci.yml
.gitignore
```

---

### Task 3: Gate Render's Native Deployment

**Files:**
- Modify: `render.yaml:1-10`
- Test: `render.yaml`

**Interfaces:**
- Consumes: GitHub checks emitted by Task 2, existing public `GET /api/health`, existing Render service `hows-the-rent-api`.
- Produces: Blueprint fields `autoDeployTrigger: checksPass` and `healthCheckPath: /api/health`, with legacy `autoDeploy` removed.

- [ ] **Step 1: Replace the legacy deploy trigger and add the health path**

Change this service fragment:

```yaml
    dockerfilePath: ./Dockerfile
    autoDeploy: true
    envVars:
```

to:

```yaml
    dockerfilePath: ./Dockerfile
    autoDeployTrigger: checksPass
    healthCheckPath: /api/health
    envVars:
```

Do not add a Render database resource, `preDeployCommand`, deploy hook, or credential.

- [ ] **Step 2: Validate the Blueprint fields**

With local `yq`:

```bash
yq -e '
  .services[]
  | select(.name == "hows-the-rent-api")
  | .autoDeployTrigger == "checksPass"
    and .healthCheckPath == "/api/health"
    and (has("autoDeploy") | not)
' render.yaml
```

Or with the pinned container:

```bash
docker run --rm \
  --volume "$PWD:/workdir" \
  mikefarah/yq:4.44.3 \
  e -e '
    .services[]
    | select(.name == "hows-the-rent-api")
    | .autoDeployTrigger == "checksPass"
      and .healthCheckPath == "/api/health"
      and (has("autoDeploy") | not)
  ' /workdir/render.yaml
```

Expected output: `true` and exit code `0`.

- [ ] **Step 3: Confirm the referenced health endpoint remains public**

```bash
grep -n 'RequestMapping("/api/health")' \
  htr-backend/src/main/java/chez1s/htrbackend/controller/HealthController.java

grep -n 'requestMatchers("/api/health").permitAll()' \
  htr-backend/src/main/java/chez1s/htrbackend/config/SecurityConfig.java
```

Expected: one match from each file.

- [ ] **Step 4: Commit the Render Blueprint change**

This local commit is covered by the user's selected subagent-driven implementation mode; do not push it.

```bash
git add render.yaml
git diff --cached --check
git diff --cached --name-only
git commit \
  -m "chore(render): gate backend deploys on CI" \
  -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

Expected staged path before commit: `render.yaml` only.

---

### Task 4: Document Dashboard Bootstrap and Recovery

**Files:**
- Modify: `DEPLOYMENT.md:1-124`
- Do not modify: `docs/DEPLOYMENT.md`

**Interfaces:**
- Consumes: stable `Release gate` check from Task 2 and Render fields from Task 3.
- Produces: an operator runbook that can configure external GitHub, Vercel, and Render settings before the implementation PR is merged, without claiming those external actions happened locally.

- [ ] **Step 1: Update the deployment overview and runtime requirements**

Revise the opening to state:

```markdown
# Deployment Guide

This repository uses:

- Frontend: Vercel Git Integration (`htr-frontend`, Node.js 22)
- Backend: Render Blueprint (`hows-the-rent-api`)
- Database: the existing external Render PostgreSQL instance
- CI gate: GitHub Actions check `Release gate`

GitHub Actions validates the application but never stores deployment credentials or calls platform deployment APIs.
```

Retain the existing cookie/rewrite explanation and environment-variable details.

- [ ] **Step 2: Replace the database topology section**

Replace the existing Neon/Supabase instructions under `## 1. Database` with:

````markdown
## 1. Database

Use the existing Render PostgreSQL instance. It is managed outside this repository's `render.yaml`; do not add a second Blueprint database.

Keep these values in the Render backend service environment:

```env
DB_URL=jdbc:postgresql://<render-host>/<database>?sslmode=require
DB_USER=<username>
DB_PASSWORD=<password>
```

The backend currently uses `spring.jpa.hibernate.ddl-auto=update`. Schema-breaking changes are not safe in a single release; follow the expand/contract policy in the recovery section.
````

Do not leave instructions to create Neon or Supabase in this guide. Those providers may remain valid alternatives in the separate provider-agnostic `docs/DEPLOYMENT.md`, which this plan does not modify.

- [ ] **Step 3: Add a `CI/CD dashboard bootstrap` section**

Add the following exact operational requirements:

```markdown
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
```

- [ ] **Step 4: Add the first-rollout runbook**

Add:

```markdown
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
```

The 30-minute value is an operator cutoff, not a claimed Render timeout.

- [ ] **Step 5: Add non-atomic release and schema-safe recovery guidance**

Add:

```markdown
## Recovery and break-glass

Vercel and Render release independently. The shared gate is not an atomic cross-platform deployment. API changes must remain backward/forward compatible for at least one release window.

- If Vercel succeeds and Render fails, fix-forward the backend when compatible; otherwise restore the frontend paired with the backend still serving production.
- If Render succeeds and Vercel fails, fix-forward the frontend when compatible; otherwise inspect database compatibility before restoring the backend.
- Record paired frontend/backend SHAs after every release.

Render rollback restores application image/config only. It does not restore PostgreSQL schema. Until versioned migrations exist, schema changes must use expand/contract: add compatible schema, deploy compatible code, then remove old schema in a later release. Inspect schema mutation before any backend rollback because startup migration code can execute `ALTER`, `DROP`, and rename statements before health checks finish.

Only owners/admins may use Vercel Force Promote, Render manual deploy/rollback, or temporary ruleset changes. Record both SHAs, the operator, reason, action, and result, then restore the normal gate.
```

- [ ] **Step 6: Add the residual-risk statement without overstating verification**

Add:

```markdown
## Residual verification risk

This change configures and audits the production gates and observes the passing path. Without a separate staging/shadow environment, it does not behaviorally prove that failed, missing, cancelled, or renamed production-equivalent checks remain fail-closed. That negative test and the Render/Vercel status interaction probe are follow-up work; do not claim they ran as part of this rollout.
```

- [ ] **Step 7: Verify documentation consistency**

```bash
grep -nE \
  'Release gate|Node\.js 22|After CI Checks Pass|30 minutes|paired|expand/contract|Residual verification risk' \
  DEPLOYMENT.md

if grep -nE \
  '\$\{\{[[:space:]]*secrets\.|VERCEL_TOKEN[[:space:]]*[:=]|RENDER_(API_KEY|DEPLOY_HOOK)[[:space:]]*[:=]|(^|[[:space:]])vercel[[:space:]]+deploy|render[[:space:]]+deploy' \
  .github/workflows/ci.yml; then
  echo "unexpected deployment secret or deploy command in CI" >&2
  exit 1
fi

if grep -nE 'Neon|Supabase' DEPLOYMENT.md; then
  echo "obsolete production database provider remains in root guide" >&2
  exit 1
fi
```

Expected: all required concepts appear; no credential/deploy command usage appears in CI; root deployment guide no longer names Neon/Supabase as the active database topology.

- [ ] **Step 8: Commit the operator runbook**

This local commit is covered by the user's selected subagent-driven implementation mode; do not push it.

```bash
git add DEPLOYMENT.md
git diff --cached --check
git diff --cached --name-only
git commit \
  -m "docs(deploy): add CI-gated rollout runbook" \
  -m "Co-Authored-By: Claude <noreply@anthropic.com>"
```

Expected staged path before commit: `DEPLOYMENT.md` only.

---

### Task 5: Validate the Complete Implementation Snapshot

**Files:**
- Verify only: `.github/workflows/ci.yml`
- Verify only: `.gitignore`
- Verify only: `DEPLOYMENT.md`
- Verify only: `htr-backend/src/test/resources/application-test.properties`
- Verify only: `render.yaml`

**Interfaces:**
- Consumes: committed outputs of Tasks 1-4.
- Produces: local evidence for syntax, frontend quality, isolated backend tests, Docker buildability, scope control, and clean working-tree status. External dashboard behavior remains a post-PR operator action rather than a local completion claim.

- [ ] **Step 1: Run static and scope checks**

Capture the pre-implementation base once; when following the exact four local commits above, it is `HEAD~4` at this point:

```bash
base_ref="HEAD~4"
git diff --check "$base_ref"..HEAD

if command -v actionlint >/dev/null 2>&1; then
  actionlint .github/workflows/ci.yml
else
  docker run --rm \
    --volume "$PWD:/repo" \
    --workdir /repo \
    rhysd/actionlint:1.7.7 \
    .github/workflows/ci.yml
fi

if git check-ignore -q .github/workflows/ci.yml; then
  echo "workflow is ignored" >&2
  exit 1
fi

if ! git check-ignore -q .github/modernize/java-upgrade/.gitignore; then
  echo ".github/modernize artifacts are unexpectedly exposed" >&2
  exit 1
fi

changed_files="$(git diff --name-only "$base_ref"..HEAD)"
printf '%s\n' "$changed_files"
```

Expected paths:

```text
.github/workflows/ci.yml
.gitignore
DEPLOYMENT.md
htr-backend/src/test/resources/application-test.properties
render.yaml
```

If `actionlint` is unavailable, run the pinned container from Task 2. GitHub's first PR run remains authoritative.

- [ ] **Step 2: Run the frontend pipeline on Node.js 22**

```bash
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git archive --format=tar HEAD htr-frontend | tar -xf - -C "$tmp"

docker run --rm \
  --volume "$tmp/htr-frontend:/workspace" \
  --workdir /workspace \
  node:22-bookworm \
  sh -lc 'npm ci && npm run lint && npm run build'
```

Expected: all three commands exit `0`. Do not run or add `npm test`; no real frontend suite exists.

- [ ] **Step 3: Re-run backend verification in a committed clean snapshot**

```bash
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git archive --format=tar HEAD htr-backend | tar -xf - -C "$tmp"

docker run --rm \
  --volume "$tmp/htr-backend:/workspace" \
  --workdir /workspace \
  --env SPRING_PROFILES_ACTIVE=test \
  --env SPRING_JPA_SHOW_SQL=true \
  eclipse-temurin:21-jdk \
  sh -lc '
    env -u DB_URL -u DB_USER -u DB_PASSWORD \
      ./mvnw --batch-mode verify >/tmp/backend-verify.log 2>&1
    rc=$?
    cat /tmp/backend-verify.log
    if [ "$rc" -ne 0 ]; then
      exit "$rc"
    fi
    if grep -Eiq "jdbc:postgresql://localhost|type_uuid" /tmp/backend-verify.log; then
      echo "unexpected production datasource or destructive migration SQL" >&2
      exit 1
    fi
  '
```

Expected: test suite passes with H2 and no production-like datasource or destructive startup migration branch.

- [ ] **Step 4: Build the exact backend Docker context used by Render**

```bash
docker build --tag htr-backend:ci htr-backend
```

Expected: image build exits `0`. This does not replace Step 3 because `htr-backend/Dockerfile` uses `-DskipTests`.

- [ ] **Step 5: Re-run Blueprint and release-gate assertions**

```bash
yq -e '
  .services[]
  | select(.name == "hows-the-rent-api")
  | .autoDeployTrigger == "checksPass"
    and .healthCheckPath == "/api/health"
    and (has("autoDeploy") | not)
' render.yaml

gate='test "$FRONTEND_RESULT" = success &&
      test "$BACKEND_RESULT" = success &&
      test "$DOCKER_RESULT" = success'

env FRONTEND_RESULT=success BACKEND_RESULT=success DOCKER_RESULT=success sh -c "$gate"
! env FRONTEND_RESULT=failure BACKEND_RESULT=success DOCKER_RESULT=success sh -c "$gate"
! env FRONTEND_RESULT=success BACKEND_RESULT=cancelled DOCKER_RESULT=success sh -c "$gate"
! env FRONTEND_RESULT=success BACKEND_RESULT=success DOCKER_RESULT=skipped sh -c "$gate"
```

Expected: Blueprint expression is `true`; gate truth table behaves fail-closed.

- [ ] **Step 6: Scan changed files for placeholders and prohibited shortcuts**

```bash
base_ref="HEAD~4"
changed_files="$(git diff --name-only "$base_ref"..HEAD)"

if grep -nE \
  'test\.(skip|only)|it\.(skip|only)|describe\.(skip|only)|PLACEHOLDER_MARKER' \
  $changed_files; then
  echo "placeholder marker or skipped/only test found" >&2
  exit 1
fi

if grep -nE \
  '\$\{\{[[:space:]]*secrets\.|VERCEL_TOKEN[[:space:]]*[:=]|RENDER_(API_KEY|DEPLOY_HOOK)[[:space:]]*[:=]|(^|[[:space:]])vercel[[:space:]]+deploy|render[[:space:]]+deploy|workflow_dispatch' \
  .github/workflows/ci.yml; then
  echo "out-of-scope deployment behavior found" >&2
  exit 1
fi
```

Expected: no matches.

- [ ] **Step 7: Verify repository state and commit boundaries**

```bash
git status --short --branch
git log -4 --oneline
git show --stat --oneline HEAD~3
git show --stat --oneline HEAD~2
git show --stat --oneline HEAD~1
git show --stat --oneline HEAD
```

Expected new commit sequence:

```text
docs(deploy): add CI-gated rollout runbook
chore(render): gate backend deploys on CI
ci: add GitHub release eligibility gate
test(backend): isolate verification with H2
```

The only pre-existing local modification allowed outside this implementation is `.claude/settings.local.json`; do not stage, revert, or include it. Report that the implementation files are committed and tests passed, while external GitHub/Vercel/Render dashboard configuration and production behavior have not yet been performed locally.
