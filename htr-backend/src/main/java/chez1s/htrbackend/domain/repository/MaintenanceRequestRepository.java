package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.MaintenanceRequest;
import chez1s.htrbackend.domain.enums.MaintenanceStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface MaintenanceRequestRepository extends JpaRepository<MaintenanceRequest, UUID> {
    @EntityGraph(attributePaths = {"room", "room.property", "tenant", "assignedTo"})
    List<MaintenanceRequest> findByRoomIdOrderByCreatedAtDesc(UUID roomId);

    @EntityGraph(attributePaths = {"room", "room.property", "tenant", "assignedTo"})
    Page<MaintenanceRequest> findByTenantId(UUID tenantId, Pageable pageable);

    @EntityGraph(attributePaths = {"room", "room.property", "tenant", "assignedTo"})
    List<MaintenanceRequest> findByTenantIdOrderByCreatedAtDesc(UUID tenantId);

    @EntityGraph(attributePaths = {"room", "room.property", "tenant", "assignedTo"})
    Page<MaintenanceRequest> findByAssignedToId(UUID technicianId, Pageable pageable);

    @EntityGraph(attributePaths = {"room", "room.property", "tenant", "assignedTo"})
    List<MaintenanceRequest> findByAssignedToIdOrderByCreatedAtDesc(UUID technicianId);

    @EntityGraph(attributePaths = {"room", "room.property", "tenant", "assignedTo"})
    Page<MaintenanceRequest> findByRoomPropertyOwnerId(UUID ownerId, Pageable pageable);

    long countByStatus(MaintenanceStatus status);
    long countByRoomPropertyOwnerIdAndStatus(UUID ownerId, MaintenanceStatus status);
}
