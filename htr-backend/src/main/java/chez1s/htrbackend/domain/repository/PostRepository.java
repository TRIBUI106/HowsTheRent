package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.Post;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PostRepository extends JpaRepository<Post, UUID> {

    @EntityGraph(attributePaths = {"room", "room.property", "room.images", "author"})
    Optional<Post> findBySlugAndPublishedTrue(String slug);

    @EntityGraph(attributePaths = {"room", "room.property", "author"})
    Optional<Post> findById(UUID id);

    @EntityGraph(attributePaths = {"room", "room.property"})
    List<Post> findByPublishedTrueOrderByPublishedAtDesc();

    @EntityGraph(attributePaths = {"room", "room.property"})
    List<Post> findAllByOrderByUpdatedAtDesc();

    boolean existsBySlug(String slug);

    boolean existsBySlugAndIdNot(String slug, UUID id);
}
