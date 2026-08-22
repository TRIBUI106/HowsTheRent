package chez1s.htrbackend.service;

import chez1s.htrbackend.exception.StorageException;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import io.minio.RemoveObjectArgs;
import org.mockito.ArgumentCaptor;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class StorageServiceTest {

    @Test
    void buildPublicUrlNeverIncludesBucketForR2StyleBucketBoundDomain() {
        // Cloudflare R2 public access (pub-*.r2.dev or a custom domain) binds the
        // domain to exactly one bucket, so objects are served directly at
        // {publicUrl}/{objectName} — no bucket segment. Verified against a live
        // R2 bucket: {url}/{key} -> 200, {url}/{bucket}/{key} -> 404.
        MinioClient minioClient = mock(MinioClient.class);
        StorageService storageService = new StorageService(minioClient);
        ReflectionTestUtils.setField(storageService, "bucket", "htr-minio");
        ReflectionTestUtils.setField(storageService, "publicUrl", "https://pub.example.r2.dev");

        String url = ReflectionTestUtils.invokeMethod(storageService, "buildPublicUrl", "avatars/file.png");

        assertThat(url).isEqualTo("https://pub.example.r2.dev/avatars/file.png");
    }

    @Test
    void buildPublicUrlUsesBucketSuffixedRootAsIsForLocalMinio() {
        // Local MinIO's default public URL is {minio.url}/{minio.bucket} (see
        // application.properties) — the bucket is already part of the
        // configured root, so it's used as-is with no further bucket logic.
        MinioClient minioClient = mock(MinioClient.class);
        StorageService storageService = new StorageService(minioClient);
        ReflectionTestUtils.setField(storageService, "bucket", "htr");
        ReflectionTestUtils.setField(storageService, "publicUrl", "http://localhost:9000/htr");

        String url = ReflectionTestUtils.invokeMethod(storageService, "buildPublicUrl", "avatars/file.png");

        assertThat(url).isEqualTo("http://localhost:9000/htr/avatars/file.png");
    }

    @Test
    void deleteStripsPublicUrlPrefixToRecoverObjectName() throws Exception {
        MinioClient minioClient = mock(MinioClient.class);
        StorageService storageService = new StorageService(minioClient);
        ReflectionTestUtils.setField(storageService, "bucket", "htr-minio");
        ReflectionTestUtils.setField(storageService, "publicUrl", "https://pub.example.r2.dev");

        storageService.delete("https://pub.example.r2.dev/avatars/file.png");

        ArgumentCaptor<RemoveObjectArgs> args = ArgumentCaptor.forClass(RemoveObjectArgs.class);
        verify(minioClient).removeObject(args.capture());
        assertThat(args.getValue().bucket()).isEqualTo("htr-minio");
        assertThat(args.getValue().object()).isEqualTo("avatars/file.png");
    }

    @Test
    void deleteStripsBucketSuffixedPublicUrlPrefixForLocalMinio() throws Exception {
        MinioClient minioClient = mock(MinioClient.class);
        StorageService storageService = new StorageService(minioClient);
        ReflectionTestUtils.setField(storageService, "bucket", "htr");
        ReflectionTestUtils.setField(storageService, "publicUrl", "http://localhost:9000/htr");

        storageService.delete("http://localhost:9000/htr/avatars/file.png");

        ArgumentCaptor<RemoveObjectArgs> args = ArgumentCaptor.forClass(RemoveObjectArgs.class);
        verify(minioClient).removeObject(args.capture());
        assertThat(args.getValue().bucket()).isEqualTo("htr");
        assertThat(args.getValue().object()).isEqualTo("avatars/file.png");
    }

    @Test
    void uploadWrapsObjectStorageFailuresInFriendlyStorageException() throws Exception {
        MinioClient minioClient = mock(MinioClient.class);
        StorageService storageService = new StorageService(minioClient);
        ReflectionTestUtils.setField(storageService, "bucket", "htr");
        ReflectionTestUtils.setField(storageService, "publicUrl", "https://pub.example.r2.dev");
        MockMultipartFile file = new MockMultipartFile(
                "images",
                "broken.jpg",
                "image/jpeg",
                "image-bytes".getBytes()
        );

        when(minioClient.putObject(any(PutObjectArgs.class)))
                .thenThrow(new RuntimeException("AccessDenied"));

        assertThatThrownBy(() -> storageService.upload("maintenance/request-id", file))
                .isInstanceOf(StorageException.class)
                .hasMessage("Dịch vụ tải ảnh hiện không khả dụng. Vui lòng thử lại sau.")
                .hasCauseInstanceOf(RuntimeException.class);
    }
}
