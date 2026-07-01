package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.enums.RoomStatus;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RoomRepository extends JpaRepository<Room, UUID> {
    @EntityGraph(attributePaths = {"property", "images"})
    List<Room> findByPropertyId(UUID propertyId);

    @EntityGraph(attributePaths = {"property", "images"})
    List<Room> findByStatus(RoomStatus status);

    @EntityGraph(attributePaths = {"property", "images"})
    List<Room> findByPropertyOwnerIdAndStatus(UUID ownerId, RoomStatus status);

    @EntityGraph(attributePaths = {"property", "images"})
    List<Room> findByPropertyOwnerId(UUID ownerId);

    @EntityGraph(attributePaths = {"property", "images"})
    List<Room> findAll();

    @EntityGraph(attributePaths = {"property", "images"})
    Optional<Room> findById(UUID id);

    @EntityGraph(attributePaths = {"property", "images"})
    Optional<Room> findByIdAndPropertyId(UUID id, UUID propertyId);

    long countByPropertyIdAndStatus(UUID propertyId, RoomStatus status);
    void deleteByPropertyId(UUID propertyId);
}
