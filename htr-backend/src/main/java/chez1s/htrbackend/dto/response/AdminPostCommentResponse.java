package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.PostComment;

import java.time.LocalDateTime;
import java.util.UUID;

public record AdminPostCommentResponse(
        UUID id,
        String content,
        UUID userId,
        String userName,
        UUID postId,
        String postTitle,
        String postSlug,
        LocalDateTime createdAt
) {
    public static AdminPostCommentResponse from(PostComment comment) {
        return new AdminPostCommentResponse(
                comment.getId(),
                comment.getContent(),
                comment.getUser().getId(),
                comment.getUser().getFullName(),
                comment.getPost().getId(),
                comment.getPost().getTitle(),
                comment.getPost().getSlug(),
                comment.getCreatedAt()
        );
    }
}
