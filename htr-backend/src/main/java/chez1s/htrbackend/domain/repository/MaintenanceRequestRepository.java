package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.MaintenanceRequest;
import chez1s.htrbackend.domain.enums.MaintenanceStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface MaintenanceRequestRepository extends JpaRepository<MaintenanceRequest, UUID> {
    List<MaintenanceRequest> findByTenantIdOrderByCreatedAtDesc(UUID tenantId);
    List<MaintenanceRequest> findByAssignedToIdOrderByCreatedAtDesc(UUID technicianId);
    long countByStatus(MaintenanceStatus status);
}
