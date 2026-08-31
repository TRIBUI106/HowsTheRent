package chez1s.htrbackend.dto.response;

import java.time.LocalDateTime;
import java.util.UUID;

public record BlogPostDetailResponse(
        UUID id,
        String slug,
        String title,
        String content,
        String coverImageUrl,
        UUID propertyId,
        String propertyName,
        String propertyAddress,
        LocalDateTime publishedAt,
        long likeCount,
        boolean liked
) {
}
