package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.MaintenanceRequest;
import chez1s.htrbackend.domain.enums.MaintenancePriority;
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

    @EntityGraph(attributePaths = {"room", "room.property", "tenant", "assignedTo"})
    Page<MaintenanceRequest> findByStatusIn(List<MaintenanceStatus> statuses, Pageable pageable);

    @EntityGraph(attributePaths = {"room", "room.property", "tenant", "assignedTo"})
    Page<MaintenanceRequest> findByRoomPropertyOwnerIdAndStatusIn(UUID ownerId, List<MaintenanceStatus> statuses, Pageable pageable);

    long countByStatus(MaintenanceStatus status);
    long countByRoomPropertyOwnerIdAndStatus(UUID ownerId, MaintenanceStatus status);
    long countByStatusIn(List<MaintenanceStatus> statuses);
    long countByRoomPropertyOwnerIdAndStatusIn(UUID ownerId, List<MaintenanceStatus> statuses);
    long countByStatusNotIn(List<MaintenanceStatus> statuses);
    long countByRoomPropertyOwnerIdAndStatusNotIn(UUID ownerId, List<MaintenanceStatus> statuses);
    long countByRoomIdAndStatusNotIn(UUID roomId, List<MaintenanceStatus> statuses);
    long countByPriorityInAndStatusNotIn(List<MaintenancePriority> priorities, List<MaintenanceStatus> statuses);
    long countByRoomPropertyOwnerIdAndPriorityInAndStatusNotIn(UUID ownerId, List<MaintenancePriority> priorities, List<MaintenanceStatus> statuses);
    long countByAssignedToIdAndStatusNotIn(UUID technicianId, List<MaintenanceStatus> statuses);
}
