package chez1s.htrbackend.service;

import chez1s.htrbackend.exception.StorageException;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class StorageServiceTest {

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
