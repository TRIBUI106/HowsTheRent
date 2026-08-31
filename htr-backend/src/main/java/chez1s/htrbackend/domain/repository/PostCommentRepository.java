package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.PostComment;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface PostCommentRepository extends JpaRepository<PostComment, UUID> {

    @EntityGraph(attributePaths = {"user"})
    List<PostComment> findByPostIdOrderByCreatedAtAsc(UUID postId);

    @EntityGraph(attributePaths = {"user", "post"})
    List<PostComment> findAllByOrderByCreatedAtDesc();

    void deleteAllByPostId(UUID postId);
}
