package chez1s.htrbackend.dto.response;

import java.time.LocalDateTime;
import java.util.UUID;

public record BlogPostSummaryResponse(
        UUID id,
        String slug,
        String title,
        String coverImageUrl,
        UUID roomId,
        String roomNumber,
        String roomStatus,
        UUID propertyId,
        String propertyName,
        String propertyAddress,
        LocalDateTime publishedAt
) {
}
