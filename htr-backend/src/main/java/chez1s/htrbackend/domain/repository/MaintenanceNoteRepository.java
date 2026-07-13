package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.MaintenanceNote;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface MaintenanceNoteRepository extends JpaRepository<MaintenanceNote, UUID> {
    List<MaintenanceNote> findByRequestIdOrderByCreatedAtDesc(UUID requestId);
}
