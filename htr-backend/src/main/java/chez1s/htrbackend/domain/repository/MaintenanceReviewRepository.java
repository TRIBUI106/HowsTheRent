package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.MaintenanceReview;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MaintenanceReviewRepository extends JpaRepository<MaintenanceReview, UUID> {
    Page<MaintenanceReview> findByTechnicianId(UUID technicianId, Pageable pageable);
    List<MaintenanceReview> findByTechnicianId(UUID technicianId);
    Optional<MaintenanceReview> findByMaintenanceRequestId(UUID requestId);
}
