package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.PostComment;

import java.time.LocalDateTime;
import java.util.UUID;

public record PostCommentResponse(
        UUID id,
        String content,
        UUID userId,
        String userName,
        LocalDateTime createdAt
) {
    public static PostCommentResponse from(PostComment comment) {
        return new PostCommentResponse(
                comment.getId(),
                comment.getContent(),
                comment.getUser().getId(),
                comment.getUser().getFullName(),
                comment.getCreatedAt()
        );
    }
}
