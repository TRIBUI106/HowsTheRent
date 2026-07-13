package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.MaintenanceNote;
import java.time.LocalDateTime;
import java.util.UUID;

public record MaintenanceNoteResponse(
        UUID id,
        UUID requestId,
        UUID actorId,
        String actorName,
        String status,
        String note,
        LocalDateTime createdAt
) {
    public static MaintenanceNoteResponse from(MaintenanceNote n) {
        return new MaintenanceNoteResponse(
                n.getId(),
                n.getRequest().getId(),
                n.getActor() != null ? n.getActor().getId() : null,
                n.getActor() != null ? n.getActor().getFullName() : "Hệ thống",
                n.getStatus() != null ? n.getStatus().name() : null,
                n.getNote(),
                n.getCreatedAt()
        );
    }
}
