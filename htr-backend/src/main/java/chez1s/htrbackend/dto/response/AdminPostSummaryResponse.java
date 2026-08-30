package chez1s.htrbackend.dto.response;

import java.time.LocalDateTime;
import java.util.UUID;

public record AdminPostSummaryResponse(
        UUID propertyId,
        String propertyName,
        UUID postId,
        String title,
        String slug,
        boolean published,
        LocalDateTime updatedAt
) {
}
