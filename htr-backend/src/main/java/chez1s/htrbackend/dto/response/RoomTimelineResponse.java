package chez1s.htrbackend.dto.response;

import java.time.LocalDateTime;
import java.util.Map;

public record RoomTimelineResponse(
        String type,
        LocalDateTime date,
        String title,
        String description,
        Map<String, Object> metadata
) {}
