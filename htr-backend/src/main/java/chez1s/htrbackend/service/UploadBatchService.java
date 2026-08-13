package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.UploadBatch;
import chez1s.htrbackend.domain.entity.UploadBatchItem;
import chez1s.htrbackend.domain.repository.UploadBatchItemRepository;
import chez1s.htrbackend.domain.repository.UploadBatchRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UploadBatchService {
    private final UploadBatchRepository batchRepository;
    private final UploadBatchItemRepository itemRepository;
    private final StorageService storageService;

    @Transactional
    public UploadBatch begin(String key, String domainType, UUID domainId) {
        return batchRepository.findByIdempotencyKey(key).orElseGet(() -> batchRepository.save(
                UploadBatch.builder().idempotencyKey(key).domainType(domainType).domainId(domainId)
                        .status("UPLOADING").cleanupRequired(false).build()));
    }

    @Transactional
    public void record(UploadBatch batch, String url, String contentType, long size) {
        itemRepository.save(UploadBatchItem.builder().batch(batch).objectName(url)
                .contentType(contentType).sizeBytes(size).status("UPLOADED").build());
    }

    @Transactional
    public void complete(UploadBatch batch) {
        batch.setStatus("COMPLETED");
        batch.setCleanupRequired(false);
        batchRepository.save(batch);
    }

    @Transactional
    public void requireCleanup(UploadBatch batch) {
        batch.setStatus("FAILED");
        batch.setCleanupRequired(true);
        batchRepository.save(batch);
    }

    @Scheduled(fixedDelayString = "${app.upload-cleanup.delay-ms:300000}")
    @Transactional
    public void cleanupFailedBatches() {
        for (UploadBatch batch : batchRepository.findByCleanupRequiredTrue()) {
            for (UploadBatchItem item : itemRepository.findByBatchId(batch.getId())) {
                storageService.delete(item.getObjectName());
                item.setStatus("CLEANED");
                itemRepository.save(item);
            }
            batch.setCleanupRequired(false);
            batch.setStatus("CLEANED");
            batchRepository.save(batch);
        }
    }
}
