package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.Post;
import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.PropertyType;
import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.dto.response.BlogPostDetailResponse;
import chez1s.htrbackend.service.PostService;
import chez1s.htrbackend.service.StorageService;
import org.hibernate.Hibernate;
import org.junit.jupiter.api.Test;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.boot.jpa.test.autoconfigure.TestEntityManager;
import org.springframework.boot.jdbc.test.autoconfigure.AutoConfigureTestDatabase;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

@DataJpaTest
@ActiveProfiles("test")
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class PostRepositoryTest {

    @org.springframework.beans.factory.annotation.Autowired
    private TestEntityManager entityManager;

    @org.springframework.beans.factory.annotation.Autowired
    private PostRepository postRepository;

    // Persists one published post with a couple of tags plus its room/property graph, then
    // flushes and clears — same rationale as InvoiceRepositoryTest.persistAndDetachOneInvoice():
    // without clear(), the entities would still sit initialized in the first-level cache and every
    // isInitialized() assertion below would trivially pass regardless of what @EntityGraph does.
    private Post persistAndDetachOnePost() {
        PropertyType type = PropertyType.builder()
                .code("APARTMENT")
                .name("Apartment")
                .build();
        entityManager.persist(type);

        User owner = User.builder()
                .fullName("Owner")
                .email("owner@test.com")
                .passwordHash("hash")
                .role(UserRole.LANDLORD_ADMIN)
                .build();
        entityManager.persist(owner);

        Property property = Property.builder()
                .owner(owner)
                .name("Property")
                .address("123 Street")
                .type(type)
                .build();
        entityManager.persist(property);

        Room room = Room.builder()
                .property(property)
                .roomNumber("101")
                .maxPeople(2)
                .status(RoomStatus.RENTED)
                .build();
        entityManager.persist(room);

        Post post = Post.builder()
                .room(room)
                .title("Post title")
                .slug("post-title-" + UUID.randomUUID())
                .published(true)
                .tags(List.of("noi-that", "gan-truong-hoc"))
                .build();
        entityManager.persist(post);

        entityManager.flush();
        entityManager.clear();
        return post;
    }

    // Regression test: findById() had no "tags" in its @EntityGraph, unlike "room"/"room.property"/
    // "author" which were already covered. Confirmed in production: PostService.getForAdmin() ->
    // AdminPostDetailResponse.from(post) threw LazyInitializationException the moment Jackson
    // serialized the detached DTO's tags field, because tags is an @ElementCollection (a separate
    // persistent collection, not covered by fetching the post row itself) and had never been forced
    // to initialize while the session was still open.
    @Test
    void findById_eagerFetchesTags() {
        Post persisted = persistAndDetachOnePost();

        Post found = postRepository.findById(persisted.getId()).orElseThrow();

        assertThat(Hibernate.isInitialized(found.getTags())).isTrue();
        assertThat(found.getTags()).containsExactlyInAnyOrder("noi-that", "gan-truong-hoc");
    }

    // Regression test: same gap on findByPublishedTrueOrderByPublishedAtDesc(), used by
    // PostService.listPublished() -> toSummary(post) -> BlogPostSummaryResponse, which failed in
    // production with the exact same LazyInitializationException shape.
    @Test
    void findByPublishedTrueOrderByPublishedAtDesc_eagerFetchesTags() {
        persistAndDetachOnePost();

        List<Post> found = postRepository.findByPublishedTrueOrderByPublishedAtDesc();

        assertThat(found).hasSize(1);
        assertThat(Hibernate.isInitialized(found.get(0).getTags())).isTrue();
        assertThat(found.get(0).getTags()).containsExactlyInAnyOrder("noi-that", "gan-truong-hoc");
    }

    // findBySlugAndPublishedTrue() deliberately does NOT eager-fetch tags via @EntityGraph: it
    // already needs room.images, and Hibernate refuses to join-fetch two bag collections
    // (unordered List, no @OrderColumn) in one query (MultipleBagFetchException) — see the comment
    // on the repository method. This documents that boundary rather than asserting it's initialized.
    @Test
    void findBySlugAndPublishedTrue_doesNotEagerFetchTagsDueToBagFetchConflict() {
        Post persisted = persistAndDetachOnePost();

        Post found = postRepository.findBySlugAndPublishedTrue(persisted.getSlug()).orElseThrow();

        assertThat(Hibernate.isInitialized(found.getRoom().getImages())).isTrue();
        assertThat(Hibernate.isInitialized(found.getTags())).isFalse();
    }

    // Regression test for the actual production-facing guarantee: even though the repository can't
    // eager-fetch tags here, PostService.getPublishedBySlug() -> toDetail() must still return them
    // correctly, by force-initializing the lazy collection itself while its own transaction is open
    // (see the comment in PostService.toDetail()). Wires the real Spring Data-backed postRepository
    // (so tags stays a genuine uninitialized Hibernate proxy straight out of the query, exactly like
    // production) together with a real PostService instance, rather than mocking the repository —
    // a fully-mocked PostServiceTest can't reproduce this bug at all, since a plain in-memory
    // List<String> is never lazy in the first place.
    @Test
    void postServiceGetPublishedBySlug_returnsCorrectTagsDespiteBagFetchConflict() {
        Post persisted = persistAndDetachOnePost();
        PostService postService = new PostService(
                postRepository,
                mock(PostCommentRepository.class),
                mock(PostLikeRepository.class),
                mock(RoomRepository.class),
                mock(UserRepository.class),
                mock(StorageService.class)
        );

        BlogPostDetailResponse result = postService.getPublishedBySlug(persisted.getSlug(), null);

        assertThat(result.tags()).containsExactlyInAnyOrder("noi-that", "gan-truong-hoc");
    }
}
