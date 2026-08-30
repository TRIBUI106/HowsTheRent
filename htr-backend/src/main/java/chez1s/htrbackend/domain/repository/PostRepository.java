package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.Post;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PostRepository extends JpaRepository<Post, UUID> {

    @EntityGraph(attributePaths = {"property", "author"})
    Optional<Post> findBySlugAndPublishedTrue(String slug);

    @EntityGraph(attributePaths = {"property", "author"})
    Optional<Post> findByPropertyId(UUID propertyId);

    @EntityGraph(attributePaths = {"property"})
    List<Post> findByPublishedTrueOrderByPublishedAtDesc();

    boolean existsBySlug(String slug);

    boolean existsBySlugAndIdNot(String slug, UUID id);
}
