package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.Post;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PostRepository extends JpaRepository<Post, UUID> {

    // "tags" deliberately NOT in this graph: Hibernate cannot join-fetch two bag collections
    // (unordered java.util.List without @OrderColumn) in the same query, and this method already
    // needs room.images. Combining {"room.images", "tags"} throws
    // org.hibernate.loader.MultipleBagFetchException. Tags is instead force-initialized in
    // PostService.toDetail() while the transaction from getPublishedBySlug() is still open — see
    // the comment there for the same root-cause shape (an @ElementCollection read into a DTO
    // without being touched first) that findById()/findByPublishedTrueOrderByPublishedAtDesc()
    // fix via @EntityGraph instead, since those two don't have a second bag to conflict with.
    @EntityGraph(attributePaths = {"room", "room.property", "room.images", "author"})
    Optional<Post> findBySlugAndPublishedTrue(String slug);

    @EntityGraph(attributePaths = {"room", "room.property", "author", "tags"})
    Optional<Post> findById(UUID id);

    @EntityGraph(attributePaths = {"room", "room.property", "tags"})
    List<Post> findByPublishedTrueOrderByPublishedAtDesc();

    @EntityGraph(attributePaths = {"room", "room.property"})
    List<Post> findAllByOrderByUpdatedAtDesc();

    boolean existsBySlug(String slug);

    boolean existsBySlugAndIdNot(String slug, UUID id);

    List<Post> findByPublishedFalseAndPublishAtLessThanEqual(LocalDateTime now);
}
