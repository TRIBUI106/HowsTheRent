package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.UploadBatch;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UploadBatchRepository extends JpaRepository<UploadBatch, UUID> {
    Optional<UploadBatch> findByIdempotencyKey(String idempotencyKey);
    List<UploadBatch> findByCleanupRequiredTrue();
}
