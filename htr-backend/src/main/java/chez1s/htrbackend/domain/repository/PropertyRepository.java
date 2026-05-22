package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.Property;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PropertyRepository extends JpaRepository<Property, UUID> {
    @EntityGraph(attributePaths = "owner")
    List<Property> findByOwnerId(UUID ownerId);

    @EntityGraph(attributePaths = "owner")
    List<Property> findAll();

    @EntityGraph(attributePaths = "owner")
    Optional<Property> findById(UUID id);
}
