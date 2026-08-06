package chez1s.htrbackend.config;

import io.minio.BucketExistsArgs;
import io.minio.MakeBucketArgs;
import io.minio.MinioClient;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@Slf4j
public class MinioConfig {

    @Value("${minio.url}")
    private String url;

    @Value("${minio.access-key}")
    private String accessKey;

    @Value("${minio.secret-key}")
    private String secretKey;

    @Value("${minio.bucket}")
    private String bucket;

    @Value("${minio.auto-create-bucket:true}")
    private boolean autoCreateBucket;

    @Bean
    public MinioClient minioClient() {
        // TODO: no explicit .region(...) is set here. Against non-AWS S3-compatible
        // endpoints (e.g. Cloudflare R2 in production, per application.properties),
        // the SDK's region auto-detection can intermittently fail signature/region
        // validation. Needs a human to check prod Render env vars / R2 config;
        // not verifiable from this repo alone.
        MinioClient client = MinioClient.builder()
                .endpoint(url)
                .credentials(accessKey, secretKey)
                .build();
        if (autoCreateBucket) {
            try {
                if (!client.bucketExists(BucketExistsArgs.builder().bucket(bucket).build())) {
                    client.makeBucket(MakeBucketArgs.builder().bucket(bucket).build());
                    log.info("Created object storage bucket: {}", bucket);
                }
            } catch (Exception e) {
                log.warn("Could not initialize object storage bucket: {}", e.getMessage());
            }
        }
        return client;
    }
}
