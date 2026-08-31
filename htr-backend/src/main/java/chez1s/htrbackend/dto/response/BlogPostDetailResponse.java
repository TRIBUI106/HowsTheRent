package chez1s.htrbackend.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public record BlogPostDetailResponse(
        UUID id,
        String slug,
        String title,
        String content,
        String coverImageUrl,
        UUID roomId,
        String roomNumber,
        String roomStatus,
        String roomDirection,
        BigDecimal roomAreaM2,
        Integer roomMaxPeople,
        List<String> roomImages,
        UUID propertyId,
        String propertyName,
        String propertyAddress,
        LocalDateTime publishedAt,
        long likeCount,
        boolean liked
) {
}
