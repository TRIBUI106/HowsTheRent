package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.FeeConfig;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface FeeConfigRepository extends JpaRepository<FeeConfig, UUID> {
    Optional<FeeConfig> findByPropertyId(UUID propertyId);
    void deleteByPropertyId(UUID propertyId);
}
