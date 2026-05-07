package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.VehicleConfig;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface VehicleConfigRepository extends JpaRepository<VehicleConfig, UUID> {
    Optional<VehicleConfig> findByPropertyId(UUID propertyId);
}
