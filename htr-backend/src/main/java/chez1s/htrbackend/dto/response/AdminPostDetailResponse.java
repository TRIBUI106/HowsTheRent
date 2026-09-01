package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.Post;
import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.Room;

import java.time.LocalDateTime;
import java.util.UUID;

public record AdminPostDetailResponse(
        UUID id,
        UUID roomId,
        String roomNumber,
        UUID propertyId,
        String propertyName,
        String title,
        String slug,
        String content,
        String coverImageUrl,
        boolean published,
        LocalDateTime publishedAt,
        UUID authorId,
        String authorName,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
    public static AdminPostDetailResponse from(Post post) {
        Room room = post.getRoom();
        Property property = room.getProperty();
        return new AdminPostDetailResponse(
                post.getId(),
                room.getId(),
                room.getRoomNumber(),
                property.getId(),
                property.getName(),
                post.getTitle(),
                post.getSlug(),
                post.getContent(),
                post.getEffectiveCoverImageUrl(),
                post.isPublished(),
                post.getPublishedAt(),
                post.getAuthor() != null ? post.getAuthor().getId() : null,
                post.getAuthor() != null ? post.getAuthor().getFullName() : null,
                post.getCreatedAt(),
                post.getUpdatedAt()
        );
    }
}
