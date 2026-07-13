package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.MaintenanceMaterial;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface MaintenanceMaterialRepository extends JpaRepository<MaintenanceMaterial, UUID> {
    List<MaintenanceMaterial> findByRequestIdOrderByCreatedAtAsc(UUID requestId);
}
