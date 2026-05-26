package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.RoomNote;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RoomNoteRepository extends JpaRepository<RoomNote, UUID> {
    List<RoomNote> findByRoomIdOrderByCreatedAtDesc(UUID roomId);
}
