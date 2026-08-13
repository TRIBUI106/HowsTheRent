package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.UploadBatchItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface UploadBatchItemRepository extends JpaRepository<UploadBatchItem, UUID> {
    List<UploadBatchItem> findByBatchId(UUID batchId);
}
