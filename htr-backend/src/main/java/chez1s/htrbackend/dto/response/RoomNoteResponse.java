package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.RoomNote;

import java.time.LocalDateTime;
import java.util.UUID;

public record RoomNoteResponse(
        UUID id,
        String authorName,
        String authorEmail,
        String content,
        LocalDateTime createdAt
) {
    public static RoomNoteResponse from(RoomNote n) {
        return new RoomNoteResponse(
                n.getId(),
                n.getAuthor().getFullName(),
                n.getAuthor().getEmail(),
                n.getContent(),
                n.getCreatedAt()
        );
    }
}
