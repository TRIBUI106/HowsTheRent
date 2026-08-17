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
    void buildPublicUrlAppendsBucketWhenPublicUrlDoesNotIncludeIt() {
        MinioClient minioClient = mock(MinioClient.class);
        StorageService storageService = new StorageService(minioClient);
        ReflectionTestUtils.setField(storageService, "bucket", "htr");
        ReflectionTestUtils.setField(storageService, "publicUrl", "https://pub.example.r2.dev");

        String url = ReflectionTestUtils.invokeMethod(storageService, "buildPublicUrl", "avatars/file.png");

        assertThat(url).isEqualTo("https://pub.example.r2.dev/htr/avatars/file.png");
    }

    @Test
    void buildPublicUrlDoesNotDuplicateBucketWhenPublicUrlAlreadyIncludesIt() {
        MinioClient minioClient = mock(MinioClient.class);
        StorageService storageService = new StorageService(minioClient);
        ReflectionTestUtils.setField(storageService, "bucket", "htr");
        ReflectionTestUtils.setField(storageService, "publicUrl", "https://pub.example.r2.dev/htr");

        String url = ReflectionTestUtils.invokeMethod(storageService, "buildPublicUrl", "avatars/file.png");

        assertThat(url).isEqualTo("https://pub.example.r2.dev/htr/avatars/file.png");
    }

    @Test
    void deleteRemovesBucketPrefixWhenPublicUrlDoesNotIncludeIt() throws Exception {
        MinioClient minioClient = mock(MinioClient.class);
        StorageService storageService = new StorageService(minioClient);
        ReflectionTestUtils.setField(storageService, "bucket", "htr");
        ReflectionTestUtils.setField(storageService, "publicUrl", "https://pub.example.r2.dev");

        storageService.delete("https://pub.example.r2.dev/htr/avatars/file.png");

        ArgumentCaptor<RemoveObjectArgs> args = ArgumentCaptor.forClass(RemoveObjectArgs.class);
        verify(minioClient).removeObject(args.capture());
        assertThat(args.getValue().bucket()).isEqualTo("htr");
        assertThat(args.getValue().object()).isEqualTo("avatars/file.png");
    }

    @Test
    void deleteKeepsObjectNameWhenPublicUrlAlreadyIncludesBucket() throws Exception {
        MinioClient minioClient = mock(MinioClient.class);
        StorageService storageService = new StorageService(minioClient);
        ReflectionTestUtils.setField(storageService, "bucket", "htr");
        ReflectionTestUtils.setField(storageService, "publicUrl", "https://pub.example.r2.dev/htr");

        storageService.delete("https://pub.example.r2.dev/htr/avatars/file.png");

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
