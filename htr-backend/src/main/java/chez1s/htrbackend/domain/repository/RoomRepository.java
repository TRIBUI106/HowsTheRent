package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.enums.RoomStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RoomRepository extends JpaRepository<Room, UUID> {
    List<Room> findByPropertyId(UUID propertyId);
    List<Room> findByStatus(RoomStatus status);
    long countByPropertyIdAndStatus(UUID propertyId, RoomStatus status);
}
