package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.Post;

import java.time.LocalDateTime;
import java.util.UUID;

public record AdminPostDetailResponse(
        UUID id,
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
        return new AdminPostDetailResponse(
                post.getId(),
                post.getProperty().getId(),
                post.getProperty().getName(),
                post.getTitle(),
                post.getSlug(),
                post.getContent(),
                post.getCoverImageUrl(),
                post.isPublished(),
                post.getPublishedAt(),
                post.getAuthor() != null ? post.getAuthor().getId() : null,
                post.getAuthor() != null ? post.getAuthor().getFullName() : null,
                post.getCreatedAt(),
                post.getUpdatedAt()
        );
    }
}
