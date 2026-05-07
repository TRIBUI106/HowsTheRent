package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.Property;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface PropertyRepository extends JpaRepository<Property, UUID> {
    List<Property> findByOwnerId(UUID ownerId);
}
