# Thiết kế CI/CD với GitHub Actions, Vercel và Render

**Ngày:** 2026-07-30  
**Trạng thái:** Chờ duyệt đặc tả  
**Nhánh phát hành:** `master`

## 1. Mục tiêu

Bổ sung cổng kiểm tra tự động cho mọi pull request vào `master` và mọi commit trên `master`, sau đó phát hành bằng các Git integration sẵn có:

- Frontend React/Vite trên Vercel
- Backend Spring Boot trên Render
- PostgreSQL hiện có trên Render

Mọi **phát hành tự động** lên production phải chờ cổng CI bắt buộc thành công. Vercel và Render vẫn cho người có quyền cao thao tác thủ công; các thao tác đó được coi là quy trình break-glass, không phải luồng CD thông thường.

## 2. CI và CD là gì?

- **Continuous Integration (CI):** tự động cài dependency, lint, test và build mỗi thay đổi. Nếu một bước bắt buộc thất bại, thay đổi chưa đủ điều kiện merge hoặc phát hành.
- **Continuous Delivery/Deployment (CD):** đưa commit đã qua CI lên nền tảng hosting. Trong thiết kế này, Render và Vercel tự triển khai bằng native Git integration; GitHub Actions không giữ deploy token và không gọi deploy API.

## 3. Hiện trạng repository

- Chưa có workflow trong `.github/workflows/`.
- Frontend có `npm run lint` và `npm run build`, nhưng chưa có test script hoặc test suite thực thi được.
- Frontend có cả `package-lock.json` và `bun.lock`. Vercel và tài liệu deployment đang dùng npm, còn frontend Dockerfile dùng Bun. CI sẽ dùng npm; chuẩn hóa toàn bộ npm/Bun là công việc riêng.
- Backend dùng Java 21, Maven và có test suite.
- `@SpringBootTest` hiện chưa có test profile. Chỉ thêm H2 dependency không tự ghi đè PostgreSQL URL trong `application.properties`, nên Maven verification trên runner sạch có thể cố kết nối PostgreSQL localhost.
- Backend Dockerfile build JAR bằng `-DskipTests`; CI phải chạy Maven verification riêng trước khi kiểm tra Docker build.
- `render.yaml` đang dùng `autoDeploy: true` và chưa khai báo health-check path.
- `/api/health` đã tồn tại và trả `{ "status": "ok" }`.
- Database không được khai báo trong `render.yaml`; thiết kế coi Render PostgreSQL mà người dùng đã tạo là tài nguyên bên ngoài Blueprint này.
- Schema production đang dựa vào `spring.jpa.hibernate.ddl-auto=update`; chưa có Flyway hoặc Liquibase.

## 4. Kiến trúc được chọn

Dùng native Git integration của từng nền tảng làm nguồn deploy duy nhất.

```text
Pull request / push
        |
        v
GitHub Actions CI
  |-- Frontend quality
  |     npm ci -> lint -> build
  |-- Backend verify
  |     Maven verify với test profile + H2
  |-- Backend Docker build
  |     chỉ chạy sau Backend verify
  `-- Release gate
        luôn được tạo và chỉ pass khi ba job trên đều success
        |
        | Release gate thành công trên master
        v
Native Git integrations
  |-- Vercel: promote frontend candidate
  `-- Render: build, start và health-check backend
        |
        v
Production branch/domain
```

Đây là **application-wide gate** có chủ đích: lỗi frontend có thể chặn backend release và lỗi backend có thể chặn frontend promotion. Cách này ưu tiên một commit ứng dụng nhất quán hơn tốc độ phát hành riêng từng phần.

GitHub Actions không gọi Render Deploy Hook/API hoặc Vercel Deploy Hook/CLI. Nhờ vậy không có hai nguồn cùng deploy một SHA và không cần lưu credential nền tảng trong GitHub.

### Các phương án không chọn

1. **GitHub Actions điều khiển deploy:** kiểm soát tập trung hơn nhưng cần Render/Vercel credential, polling trạng thái và tắt native deployment ở cả hai nền tảng.
2. **Duyệt production thủ công:** phù hợp tổ chức cần change approval nhưng không đúng lựa chọn tự động hiện tại; có thể bổ sung sau.

## 5. Thiết kế GitHub Actions CI

Tạo `.github/workflows/ci.yml`.

### Trigger

- `pull_request` targeting `master`
- `push` trên `master`

Không cần `workflow_dispatch`; khi cần chạy lại cùng SHA, dùng chức năng **Re-run jobs** của GitHub để tránh tạo một run ad-hoc có semantics khác.

### Quyền và concurrency

- Khai báo `permissions: contents: read` ở workflow level.
- Dùng concurrency theo workflow và PR/ref.
- Hủy CI cũ khi một commit mới xuất hiện trên cùng PR/ref. Run bị hủy không được coi là gate thành công; commit mới phải hoàn thành gate riêng.

### Frontend quality

Chạy trên Ubuntu với working directory `htr-frontend`:

1. Checkout commit.
2. Cài Node.js 22 LTS và bật npm cache theo `package-lock.json`.
3. Chạy `npm ci`.
4. Chạy `npm run lint`.
5. Chạy `npm run build`, bao gồm TypeScript project build và Vite production build.

Vercel Project Settings cũng phải dùng Node.js 22 để CI và production build cùng runtime.

Chưa thêm bước frontend test cho đến khi có test thật. Không tạo test placeholder, skipped test hoặc script luôn pass chỉ để pipeline trông đầy đủ.

### Backend test isolation và verification

Bổ sung `htr-backend/src/test/resources/application-test.properties` với datasource H2 in-memory, H2 driver/dialect và `ddl-auto=create-drop`. CI kích hoạt profile `test`, không truyền `DB_URL`, `DB_USER`, `DB_PASSWORD` hoặc secret production.

Chạy trên Ubuntu với working directory `htr-backend`:

1. Checkout commit.
2. Cài Temurin Java 21 và bật Maven cache.
3. Bảo đảm `mvnw` có quyền thực thi.
4. Chạy `./mvnw --batch-mode verify` với `SPRING_PROFILES_ACTIVE=test`.

Acceptance bắt buộc chứng minh lệnh này pass trên runner sạch, không có `.env`, PostgreSQL local hoặc `DB_*`.

### Backend Docker build

Job này phụ thuộc `Backend verify`. Với Docker context là `htr-backend`, chạy tương đương:

```bash
docker build --tag htr-backend:ci .
```

Job chỉ chứng minh đúng Dockerfile mà Render dùng có thể build. Nó không thay thế test vì Dockerfile hiện chủ động dùng `-DskipTests`.

### Release gate tổng hợp

Tạo job `Release gate` với `if: always()` và direct dependencies:

- `Frontend quality`
- `Backend verify`
- `Backend Docker build`

Dù `Backend Docker build` đã phụ thuộc `Backend verify`, gate vẫn khai báo trực tiếp cả ba dependency để đọc được đầy đủ `needs.<job>.result`.

`if: always()` chỉ bảo đảm gate được chạy; nó không tự làm job thất bại. Gate phải có assertion trả exit code khác 0 nếu bất kỳ dependency nào không phải `success`, theo cấu trúc tương đương:

```yaml
release-gate:
  name: Release gate
  runs-on: ubuntu-latest
  if: ${{ always() }}
  needs: [frontend-quality, backend-verify, backend-docker-build]
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

Do đó, kết quả `failure`, `cancelled` hoặc `skipped` ở bất kỳ dependency bắt buộc nào làm chính `Release gate` có conclusion `failure`, thay vì chỉ làm gate không chạy. Điều này tạo một check ổn định cho GitHub branch protection và Vercel.

Các job name phải duy nhất trong toàn repository:

- `Frontend quality`
- `Backend verify`
- `Backend Docker build`
- `Release gate`

Không đổi tên `Release gate` nếu chưa cập nhật GitHub ruleset và Vercel Deployment Checks trước.

## 6. Thiết kế Render CD

Cập nhật backend service trong `render.yaml`:

- Thay `autoDeploy: true` bằng `autoDeployTrigger: checksPass`.
- Thêm `healthCheckPath: /api/health`.
- Xác nhận service/Blueprint thực tế liên kết với nhánh `master` và Blueprint Auto Sync đang bật.

### Semantics cần hiểu đúng

Render `checksPass` không cho chọn allowlist ba job như Vercel. Render chờ **mọi GitHub check mà nó phát hiện trên commit**. Theo tài liệu Render, `success`, `neutral` và `skipped` được coi là pass; nếu Render không phát hiện check nào hoặc phát hiện kết quả không đạt, nó không auto-deploy.

`Release gate` khắc phục trường hợp một dependency bắt buộc bị skip: gate tổng hợp vẫn được tạo và tự fail. Tuy nhiên, thêm một workflow/check mới trong tương lai vẫn có thể ảnh hưởng Render vì Render xét toàn bộ detected checks.

Không tạo path filter làm ba job bắt buộc biến mất theo loại thay đổi. Mọi commit vào `master` phải tạo `Release gate`.

### Health check và Free plan

Render chỉ route release mới khi service trả thành công tại `/api/health`. Endpoint này chứng minh process đã khởi động và phục vụ HTTP; nó không phải deep health check cho PostgreSQL, object storage, mail hoặc PayOS.

Service đang dùng Render Free, nên có thể sleep sau thời gian không có traffic và request đầu tiên có cold start đáng kể. `healthCheckPath` bảo vệ rollout nhưng không biến Free plan thành dịch vụ có production SLA. Trong tài liệu này, “production” chỉ nhánh/domain người dùng thật đang truy cập; mức availability vẫn là demo/free-tier.

### Render PostgreSQL

PostgreSQL không có Git build để deploy. Backend kết nối bằng environment variables do Render quản lý. CI không nhận database credential.

Hibernate hiện cập nhật schema khi backend khởi động. Nếu startup hoặc health check thất bại, release backend mới thất bại. Versioned migration và schema rollback không thuộc thay đổi này.

## 7. Thiết kế Vercel CD

Giữ Vercel project kết nối cùng GitHub repository, root directory `htr-frontend`, production branch `master` và automatic production aliasing bật.

Trong Vercel Project Settings:

1. Bật **Deployment Checks** với GitHub provider.
2. Chọn duy nhất check ổn định `Release gate`.
3. Xác nhận Node.js runtime là 22.

Vercel có thể tạo/build production candidate ngay sau push, nhưng không promote candidate đó sang production domain trước khi `Release gate` pass. Đây là **promotion gate**, không phải pre-build gate.

Vercel có chức năng **Force Promote** cho người đủ quyền. Render cũng cho phép manual deploy. Hai thao tác này là break-glass bypass: chỉ project owner/admin được dùng khi xử lý sự cố, phải ghi lý do và kiểm tra deployment audit/history. Luồng tự động không sử dụng chúng.

Không cần `VERCEL_TOKEN`, deploy hook, organization ID hoặc project ID trong GitHub Actions.

## 8. GitHub ruleset cho `master`

Thiết lập một ruleset rõ ràng:

- Bắt buộc pull request trước khi merge.
- Bắt buộc check `Release gate` pass.
- Bắt buộc branch up to date trước khi merge.
- Không cho direct push, force push hoặc xóa `master` trong luồng bình thường.
- Áp dụng rule cho repository administrators; thay đổi/bypass rule chỉ là break-glass có audit.

Ruleset giúp phát hiện lỗi trước khi commit tới `master`; Render/Vercel gate tiếp tục bảo vệ trường hợp platform nhận commit nhưng CI chưa đạt.

## 9. Secrets và bảo mật

Workflow CI không cần application hoặc deployment secrets.

- Chỉ dùng `GITHUB_TOKEN` với `contents: read`.
- Không đưa Render DB, JWT, PayOS, SMTP hoặc object-storage credential vào GitHub Actions.
- Runtime secrets tiếp tục nằm trong Render.
- Vercel settings tiếp tục nằm trong Vercel.
- Không thêm deploy hook khi native integrations đang bật; hook URL là credential và tạo nguy cơ deploy trùng.

Vì jobs không dùng secret, pull request từ fork vẫn có thể chạy quality checks theo policy mặc định an toàn của GitHub.

## 10. Runbook kích hoạt lần đầu

Thứ tự này ngăn chính commit cài CI/CD bị deploy theo cấu hình `autoDeploy: true` cũ:

1. Tạo PR chứa workflow, H2 test profile và thay đổi `render.yaml`.
2. Chờ PR chạy đủ bốn check và xác nhận các tên check là duy nhất.
3. Trên GitHub, tạo ruleset cho `master` và require `Release gate`.
4. Trên Vercel, bật Deployment Checks và chọn `Release gate` trước khi merge.
5. Trên Render, xác nhận đúng service/branch và Blueprint Auto Sync. Chuyển dashboard sang **After CI Checks Pass** trước khi merge. Nếu Blueprint-managed service không cho sửa trực tiếp, tạm tắt auto-deploy và không merge cho đến khi có thể áp dụng gate an toàn.
6. Merge PR.
7. Xác nhận Blueprint sync giữ `autoDeployTrigger: checksPass` và `/api/health`.
8. Đối chiếu cùng commit SHA: `Release gate` hoàn tất trước Vercel production promotion và trước Render deploy start.
9. Chạy smoke checks ở mục 12.

Nếu check name sai hoặc gate bị pending, không Force Promote và không bật lại `autoDeploy: true`; sửa cấu hình/tên check hoặc revert commit cấu hình bằng PR đã qua gate.

## 11. Failure, rollback và break-glass

| Sự cố | Hành vi mong đợi | Khôi phục bình thường |
|---|---|---|
| Frontend lint/build fail | `Release gate` fail; không auto-promote/deploy | Sửa code và push commit mới |
| Backend verify fail | Docker job bị skip, `Release gate` fail | Sửa test/backend và push commit mới |
| Backend Docker build fail | `Release gate` fail | Sửa Docker build path và push commit mới |
| Workflow bị cancel | `Release gate` không đạt | Chờ commit mới hoặc re-run cùng SHA |
| Render build/start/health fail | Backend release mới fail; xem logs | Push bản sửa; rollback về deployment tốt gần nhất nếu cần |
| Vercel candidate build fail | Candidate không được promote | Xem logs và push bản sửa |
| Gate treo do đổi/trùng tên | Production promotion dừng | Khôi phục tên duy nhất hoặc cập nhật dashboard/ruleset có kiểm soát |
| GitHub Actions outage | Không có approval tự động | Chờ dịch vụ hồi phục; không bypass trong vận hành thường |

Break-glass chỉ dành cho owner/admin khi outage hoặc incident nghiêm trọng:

- Vercel Force Promote hoặc rollback về deployment tốt gần nhất.
- Render manual deploy/rollback về deployment tốt gần nhất.
- Thay đổi ruleset hoặc deployment setting tạm thời.

Mỗi lần break-glass phải ghi SHA, người thao tác, lý do và kết quả. Sau sự cố phải khôi phục gate native và xác minh bằng commit tiếp theo.

## 12. Verification và acceptance criteria

### Kiểm tra repository

- Kiểm tra workflow bằng `actionlint` nếu có và bằng parser/run thực tế của GitHub Actions.
- Chạy frontend `npm ci`, `npm run lint`, `npm run build`.
- Chạy backend `verify` với test profile trên môi trường không có `.env`, PostgreSQL hoặc `DB_*`.
- Build backend image với context `htr-backend`.
- Quét file thay đổi để bảo đảm không thêm placeholder, `test.skip`, `test.only`, stub test hoặc nhánh CI chưa triển khai.

### Kiểm tra integration không phá production

1. PR đầu tiên phải hiển thị đủ bốn check.
2. Trên một PR chưa merge, tạo rồi sửa một lint failure để chứng minh `Frontend quality` và `Release gate` chuyển sang fail; không merge commit lỗi.
3. Kiểm tra GitHub ruleset đang require đúng `Release gate`.
4. Kiểm tra Vercel Deployment Checks đang chọn đúng `Release gate` và automatic production aliasing bật.
5. Kiểm tra Render dùng `checksPass`, liên kết `master`, Blueprint Auto Sync bật và health path là `/api/health`.
6. Merge commit pass và đối chiếu timestamp/SHA: gate hoàn tất trước Vercel promotion và Render deploy start.
7. Xác nhận không có deploy hook hoặc CLI deployment nào tạo candidate thứ hai cho cùng SHA. Platform retry nội bộ không bị tính là nguồn deploy trùng.
8. Nếu có staging/shadow Render và Vercel environment, chạy thêm negative gate test ở đó với failed/cancelled check. Không cố tình đưa commit CI-failing vào production `master` chỉ để thử gate.

Do không có staging trong scope hiện tại, negative test trên PR chứng minh logic CI/aggregate gate; cấu hình dashboard và timestamp của lần phát hành pass chứng minh wiring production. Kiểm thử end-to-end negative production-equivalent cần staging riêng và được ghi nhận là follow-up, không được tuyên bố đã chạy nếu chưa có môi trường đó.

### Smoke checks sau deploy

- `GET https://<render-service>/api/health` trả HTTP 2xx và `{ "status": "ok" }`; cho phép retry phù hợp cold start Free plan.
- Frontend production domain tải thành công.
- Frontend gọi `/api` qua Vercel rewrite tới Render backend.
- Đăng nhập và một luồng đọc API chính hoạt động mà không lặp 401.

### Definition of done

- Mỗi PR vào `master` và mỗi push trên `master` tạo đủ bốn check.
- `Release gate` chỉ pass khi ba job bắt buộc đều `success`.
- GitHub ruleset require `Release gate` và chặn direct push bình thường.
- Vercel chỉ auto-promote production candidate sau `Release gate`.
- Render dùng `checksPass`, hiểu rằng nó xét mọi detected check chứ không có allowlist riêng.
- GitHub Actions không chứa deploy token, hook hoặc lệnh deploy nền tảng.
- Mỗi platform chỉ có một nguồn deploy tự động là native Git integration; retry/rollback nội bộ được ghi nhận riêng.
- Backend Maven verify pass trên runner sạch với H2 test profile.
- Backend release mới pass `/api/health`.

## 13. Ngoài phạm vi và follow-up

- Frontend unit/component/E2E test suite thật
- Chuẩn hóa npm và Bun trên local, Docker và docs
- Flyway/Liquibase và thay production `ddl-auto=update`
- Staging/shadow environments để thử negative release gate đầy đủ
- Deep health check cho database và external services
- Automated post-deploy end-to-end smoke tests
- Production SLA hoặc nâng Render Free plan
- Manual approval environment
- GitHub-controlled Render/Vercel deployments

Các mục này nên là thay đổi riêng để cổng CI/CD ban đầu nhỏ, dễ audit và dễ rollback.

## 14. Tài liệu chính thức

- [GitHub Actions workflow syntax](https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions)
- [GitHub protected branches và required status checks](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub re-run workflows and jobs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs)
- [Render Blueprint `autoDeployTrigger`](https://render.com/docs/blueprint-spec#autodeploytrigger)
- [Render CI integration](https://render.com/docs/deploys#integrating-with-ci)
- [Render health checks](https://render.com/docs/health-checks)
- [Render Free service behavior](https://render.com/docs/free)
- [Vercel Deployment Checks](https://vercel.com/docs/deployment-checks)
- [Vercel Git integration](https://vercel.com/docs/git/vercel-for-github)
