package chez1s.htrbackend.dto.response;

import java.time.LocalDateTime;
import java.util.UUID;

public record AdminPostSummaryResponse(
        UUID postId,
        UUID roomId,
        String roomNumber,
        UUID propertyId,
        String propertyName,
        String title,
        String slug,
        boolean published,
        long likeCount,
        LocalDateTime updatedAt,
        LocalDateTime publishAt
) {
}
