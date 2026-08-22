package chez1s.htrbackend.service;

import chez1s.htrbackend.exception.StorageException;
import io.minio.GetPresignedObjectUrlArgs;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import io.minio.RemoveObjectArgs;
import io.minio.http.Method;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
@Slf4j
public class StorageService {

    private final MinioClient minioClient;

    @Value("${minio.bucket}")
    private String bucket;

    @Value("${minio.public-url:${minio.url}}")
    private String publicUrl;

    public String upload(String folder, MultipartFile file) {
        String originalFilename = file.getOriginalFilename();
        String ext = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            ext = originalFilename.substring(originalFilename.lastIndexOf("."));
        }
        String objectName = folder + "/" + UUID.randomUUID() + ext;

        try (InputStream is = file.getInputStream()) {
            minioClient.putObject(PutObjectArgs.builder()
                    .bucket(bucket)
                    .object(objectName)
                    .stream(is, file.getSize(), -1)
                    .contentType(file.getContentType())
                    .build());
        } catch (Exception e) {
            log.error("Storage upload failed for folder={}, filename={}: {}", folder, originalFilename, e.getMessage(), e);
            throw new StorageException("Dịch vụ tải ảnh hiện không khả dụng. Vui lòng thử lại sau.", e);
        }

        return buildPublicUrl(objectName);
    }

    public void delete(String objectName) {
        try {
            String normalized = normalizeObjectName(objectName);
            minioClient.removeObject(RemoveObjectArgs.builder().bucket(bucket).object(normalized).build());
        } catch (Exception e) {
            log.warn("Storage cleanup failed for object={}", objectName);
        }
    }

    // publicUrl always represents the full public root objects hang directly
    // off of — for local MinIO that's {minio.url}/{minio.bucket} (see the
    // application.properties default), and for Cloudflare R2's public access
    // (both pub-*.r2.dev domains and custom domains) the domain itself is
    // already bound to a single bucket, so the object key follows the root
    // directly with no bucket segment. Object names are therefore always
    // normalized/built relative to publicUrl alone, never the bucket name.
    private String normalizeObjectName(String objectName) {
        String baseUrl = publicUrl.endsWith("/") ? publicUrl.substring(0, publicUrl.length() - 1) : publicUrl;
        if (!objectName.startsWith(baseUrl)) {
            return objectName;
        }
        return objectName.substring(baseUrl.length()).replaceFirst("^/", "");
    }

    public String getPresignedUrl(String objectName) {
        try {
            return minioClient.getPresignedObjectUrl(GetPresignedObjectUrlArgs.builder()
                    .bucket(bucket)
                    .object(objectName)
                    .method(Method.GET)
                    .expiry(1, TimeUnit.HOURS)
                    .build());
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate presigned URL", e);
        }
    }

    private String buildPublicUrl(String objectName) {
        String baseUrl = publicUrl.endsWith("/") ? publicUrl.substring(0, publicUrl.length() - 1) : publicUrl;
        return baseUrl + "/" + objectName;
    }
}
