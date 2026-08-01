# Technician Completion Image Flow Design

## Goal

Make the technician completion-image flow explicit and reliable before fixing external object-storage credentials. Completion evidence remains mandatory: a technician may submit work for review only after the backend confirms at least one uploaded image.

## Current Failure

The frontend sends the correct multipart request to `POST /api/maintenance/{id}/completion-images`. The backend currently returns `503` when object storage rejects the upload. The page shows a transient toast, clears the file input, and continues to derive submit eligibility from an asynchronously refetched task list. This leaves the technician without a durable error, retry state, or immediate server-confirmed task update.

## Chosen Approach

Keep the existing upload endpoint and mandatory backend rule, but harden the frontend state flow:

1. Validate selected files as images before sending them.
2. Retain selected files in component state while the upload is pending or failed.
3. On success, use the returned normalized `MaintenanceRequest` to update the `tech-maintenance` query cache immediately.
4. Clear pending files and upload errors only after a successful upload.
5. On failure, keep the panel and selected files, display an inline error, and expose a retry action.
6. Enable submit-review only when the cached server response has at least one `completionImages` URL.
7. Guard the submit handler locally as a second UX check; the backend remains authoritative and rejects submissions without completion images.

## Components

### Technician maintenance page

`htr-frontend/src/features/tech/pages/MaintenancePage.tsx` will own:

- pending completion image files;
- an inline upload error message;
- upload/retry actions;
- immediate query-cache replacement after upload success;
- submit eligibility based only on server-confirmed image URLs.

The pending state resets when the selected request changes or the panel closes, preventing files from one task being uploaded to another.

### Maintenance API

`htr-frontend/src/api/maintenanceApi.ts` already returns a normalized `MaintenanceRequest` from `addCompletionImages`. Its request contract remains unchanged.

### Backend

The existing endpoint and `submitWork` validation remain unchanged. Regression tests will verify the controller orchestration:

- accepted image files are uploaded and persisted;
- storage failures remain mapped to `503` by the existing exception handler;
- submit-review remains blocked when no server-side completion image exists.

## Error Handling

- Invalid local file type: no request; show an inline Vietnamese validation message.
- Storage/API failure: preserve files, show the backend message inline and via the existing toast, allow retry.
- Successful upload: clear pending files/error, replace the affected cached task, show success toast.
- Submit attempted without confirmed images: no API request; show an inline/toast reminder.

No optimistic success state is allowed. A local filename or preview never counts as uploaded evidence.

## Testing

Frontend tests will cover pure state/cache helpers where possible:

- replacing one task in the cached assigned-task list with the server-returned task;
- determining whether submit-review is allowed only from server-confirmed image URLs;
- filtering/validating image files without treating pending files as confirmed.

Backend focused tests will cover the completion-image controller/service path with mocked storage and the existing submit-work validation.

Verification commands:

- frontend tests and production build;
- backend focused maintenance/controller tests, followed by the full suite with the existing H2 test datasource;
- separate code-review/verifier pass.

## Storage Handoff

After this code flow is complete, external storage still must be configured. The final handoff will explain how to regenerate Cloudflare R2 credentials, align `MINIO_BUCKET`, set `MINIO_PUBLIC_URL`, update local and Render environment variables, redeploy, and verify with a multipart request.
