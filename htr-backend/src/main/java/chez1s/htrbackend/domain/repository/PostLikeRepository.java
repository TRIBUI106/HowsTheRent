package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.PostLike;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface PostLikeRepository extends JpaRepository<PostLike, UUID> {

    Optional<PostLike> findByPostIdAndUserId(UUID postId, UUID userId);

    long countByPostId(UUID postId);

    boolean existsByPostIdAndUserId(UUID postId, UUID userId);

    void deleteByPostIdAndUserId(UUID postId, UUID userId);
}
