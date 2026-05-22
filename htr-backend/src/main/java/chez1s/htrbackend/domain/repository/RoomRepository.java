package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.enums.RoomStatus;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RoomRepository extends JpaRepository<Room, UUID> {
    @EntityGraph(attributePaths = "property")
    List<Room> findByPropertyId(UUID propertyId);

    @EntityGraph(attributePaths = "property")
    List<Room> findByStatus(RoomStatus status);

    @EntityGraph(attributePaths = "property")
    List<Room> findAll();

    @EntityGraph(attributePaths = "property")
    Optional<Room> findById(UUID id);

    long countByPropertyIdAndStatus(UUID propertyId, RoomStatus status);
    void deleteByPropertyId(UUID propertyId);
}
