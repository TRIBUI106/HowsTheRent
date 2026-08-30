package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Post;
import chez1s.htrbackend.domain.entity.PostComment;
import chez1s.htrbackend.domain.entity.PostLike;
import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.*;
import chez1s.htrbackend.dto.request.UpdatePostRequest;
import chez1s.htrbackend.dto.response.AdminPostDetailResponse;
import chez1s.htrbackend.dto.response.AdminPostSummaryResponse;
import chez1s.htrbackend.dto.response.BlogPostDetailResponse;
import chez1s.htrbackend.dto.response.BlogPostSummaryResponse;
import chez1s.htrbackend.dto.response.GeneratedDraftResponse;
import chez1s.htrbackend.dto.response.LikeStatusResponse;
import chez1s.htrbackend.dto.response.PostCommentResponse;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import chez1s.htrbackend.service.StorageService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class PostServiceTest {

    @Mock PostRepository postRepository;
    @Mock PostCommentRepository postCommentRepository;
    @Mock PostLikeRepository postLikeRepository;
    @Mock RoomRepository roomRepository;
    @Mock PropertyRepository propertyRepository;
    @Mock UserRepository userRepository;
    @Mock PropertyService propertyService;
    @Mock StorageService storageService;

    @InjectMocks PostService postService;

    @Test
    void listPublishedIncludesLiveVacancyCounts() {
        UUID propertyId = UUID.randomUUID();
        Property property = Property.builder().id(propertyId).name("Nhà trọ Xanh").address("12 Lê Lợi").build();
        Post post = Post.builder().id(UUID.randomUUID()).property(property).title("Phòng trọ đẹp")
                .slug("phong-tro-dep").coverImageUrl("http://img/1.jpg").published(true).build();
        when(postRepository.findByPublishedTrueOrderByPublishedAtDesc()).thenReturn(List.of(post));
        when(roomRepository.countByPropertyIdAndStatus(propertyId, RoomStatus.EMPTY)).thenReturn(1L);
        when(roomRepository.countByPropertyIdAndStatus(propertyId, RoomStatus.RENTED)).thenReturn(3L);

        List<BlogPostSummaryResponse> result = postService.listPublished();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).emptyRoomCount()).isEqualTo(1L);
        assertThat(result.get(0).totalRoomCount()).isEqualTo(4L);
        assertThat(result.get(0).propertyName()).isEqualTo("Nhà trọ Xanh");
    }

    @Test
    void getPublishedBySlugReturnsDetail() {
        UUID propertyId = UUID.randomUUID();
        Property property = Property.builder().id(propertyId).name("Nhà trọ Xanh").address("12 Lê Lợi").build();
        Post post = Post.builder().id(UUID.randomUUID()).property(property).title("Phòng trọ đẹp")
                .slug("phong-tro-dep").content("<p>Nội dung</p>").published(true).build();
        when(postRepository.findBySlugAndPublishedTrue("phong-tro-dep")).thenReturn(Optional.of(post));
        when(postLikeRepository.countByPostId(post.getId())).thenReturn(7L);

        BlogPostDetailResponse result = postService.getPublishedBySlug("phong-tro-dep");

        assertThat(result.content()).isEqualTo("<p>Nội dung</p>");
        assertThat(result.likeCount()).isEqualTo(7L);
    }

    @Test
    void getPublishedBySlugThrowsWhenMissing() {
        when(postRepository.findBySlugAndPublishedTrue("missing")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> postService.getPublishedBySlug("missing"))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void listCommentsReturnsInChronologicalOrder() {
        UUID postId = UUID.randomUUID();
        Post post = Post.builder().id(postId).published(true).build();
        User commenter = User.builder().id(UUID.randomUUID()).fullName("Khách A").build();
        PostComment comment = PostComment.builder().id(UUID.randomUUID()).post(post).user(commenter).content("Đẹp quá").build();
        when(postRepository.findBySlugAndPublishedTrue("phong-tro-dep")).thenReturn(Optional.of(post));
        when(postCommentRepository.findByPostIdOrderByCreatedAtAsc(postId)).thenReturn(List.of(comment));

        List<PostCommentResponse> result = postService.listComments("phong-tro-dep");

        assertThat(result).hasSize(1);
        assertThat(result.get(0).content()).isEqualTo("Đẹp quá");
        assertThat(result.get(0).userName()).isEqualTo("Khách A");
    }

    @Test
    void addCommentSavesAndReturnsIt() {
        UUID postId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        Post post = Post.builder().id(postId).published(true).build();
        User user = User.builder().id(userId).fullName("Khách A").build();
        when(postRepository.findBySlugAndPublishedTrue("phong-tro-dep")).thenReturn(Optional.of(post));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(postCommentRepository.save(org.mockito.ArgumentMatchers.any(PostComment.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        PostCommentResponse result = postService.addComment("phong-tro-dep", userId, "Rất hài lòng");

        assertThat(result.content()).isEqualTo("Rất hài lòng");
        assertThat(result.userName()).isEqualTo("Khách A");
    }

    @Test
    void listAllForAdminIncludesPropertiesWithNoPostYet() {
        UUID propertyWithPostId = UUID.randomUUID();
        UUID propertyWithoutPostId = UUID.randomUUID();
        Property withPost = Property.builder().id(propertyWithPostId).name("Nhà A").build();
        Property withoutPost = Property.builder().id(propertyWithoutPostId).name("Nhà B").build();
        Post post = Post.builder().id(UUID.randomUUID()).property(withPost).title("Bài viết A")
                .slug("bai-viet-a").published(true).build();
        when(propertyRepository.findAll()).thenReturn(List.of(withPost, withoutPost));
        when(postRepository.findAll()).thenReturn(List.of(post));

        List<AdminPostSummaryResponse> result = postService.listAllForAdmin();

        assertThat(result).hasSize(2);
        AdminPostSummaryResponse rowA = result.stream().filter(r -> r.propertyId().equals(propertyWithPostId)).findFirst().orElseThrow();
        assertThat(rowA.published()).isTrue();
        assertThat(rowA.slug()).isEqualTo("bai-viet-a");
        AdminPostSummaryResponse rowB = result.stream().filter(r -> r.propertyId().equals(propertyWithoutPostId)).findFirst().orElseThrow();
        assertThat(rowB.published()).isFalse();
        assertThat(rowB.postId()).isNull();
    }

    @Test
    void generateDraftBuildsHtmlFromPropertyAndRooms() {
        UUID propertyId = UUID.randomUUID();
        Property property = Property.builder().id(propertyId).name("Nhà trọ Xanh").address("12 Lê Lợi").build();
        Room room1 = Room.builder().roomNumber("A1").status(chez1s.htrbackend.domain.enums.RoomStatus.EMPTY)
                .direction(chez1s.htrbackend.domain.enums.RoomDirection.NORTH)
                .images(new java.util.ArrayList<>(List.of("http://img/a1.jpg"))).build();
        Room room2 = Room.builder().roomNumber("A2").status(chez1s.htrbackend.domain.enums.RoomStatus.RENTED)
                .images(new java.util.ArrayList<>()).build();
        when(propertyService.getById(propertyId)).thenReturn(property);
        when(roomRepository.findByPropertyId(propertyId)).thenReturn(List.of(room1, room2));

        GeneratedDraftResponse result = postService.generateDraft(propertyId);

        assertThat(result.title()).contains("Nhà trọ Xanh");
        assertThat(result.content()).contains("A1").contains("Bắc").contains("12 Lê Lợi").contains("1/2 phòng còn trống");
        assertThat(result.coverImageUrl()).isEqualTo("http://img/a1.jpg");
    }

    @Test
    void getForAdminThrowsWhenNoPostExistsYet() {
        UUID propertyId = UUID.randomUUID();
        when(postRepository.findByPropertyId(propertyId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> postService.getForAdmin(propertyId))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void upsertPostCreatesOnFirstCallWithGeneratedSlug() {
        UUID propertyId = UUID.randomUUID();
        UUID authorId = UUID.randomUUID();
        Property property = Property.builder().id(propertyId).name("Nhà trọ Xanh").build();
        User author = User.builder().id(authorId).fullName("Admin A").build();
        UpdatePostRequest req = new UpdatePostRequest();
        req.setTitle("Phòng Trọ Đẹp Quận 1");
        req.setContent("<p>Nội dung</p>");
        when(postRepository.findByPropertyId(propertyId)).thenReturn(Optional.empty());
        when(propertyService.getById(propertyId)).thenReturn(property);
        when(userRepository.findById(authorId)).thenReturn(Optional.of(author));
        when(roomRepository.findByPropertyId(propertyId)).thenReturn(List.of());
        when(postRepository.existsBySlug("phong-tro-dep-quan-1")).thenReturn(false);
        when(postRepository.save(org.mockito.ArgumentMatchers.any(Post.class))).thenAnswer(inv -> inv.getArgument(0));

        AdminPostDetailResponse result = postService.upsertPost(propertyId, req, authorId);

        assertThat(result.slug()).isEqualTo("phong-tro-dep-quan-1");
        assertThat(result.title()).isEqualTo("Phòng Trọ Đẹp Quận 1");
        assertThat(result.published()).isFalse();
    }

    @Test
    void upsertPostAppendsSuffixOnSlugCollision() {
        UUID propertyId = UUID.randomUUID();
        UUID authorId = UUID.randomUUID();
        Property property = Property.builder().id(propertyId).name("Nhà trọ Xanh").build();
        UpdatePostRequest req = new UpdatePostRequest();
        req.setTitle("Phòng Đẹp");
        when(postRepository.findByPropertyId(propertyId)).thenReturn(Optional.empty());
        when(propertyService.getById(propertyId)).thenReturn(property);
        when(userRepository.findById(authorId)).thenReturn(Optional.of(User.builder().id(authorId).build()));
        when(roomRepository.findByPropertyId(propertyId)).thenReturn(List.of());
        when(postRepository.existsBySlug("phong-dep")).thenReturn(true);
        when(postRepository.existsBySlug("phong-dep-2")).thenReturn(false);
        when(postRepository.save(org.mockito.ArgumentMatchers.any(Post.class))).thenAnswer(inv -> inv.getArgument(0));

        AdminPostDetailResponse result = postService.upsertPost(propertyId, req, authorId);

        assertThat(result.slug()).isEqualTo("phong-dep-2");
    }

    @Test
    void publishSetsPublishedAtOnlyOnFirstPublish() {
        UUID propertyId = UUID.randomUUID();
        Post post = Post.builder().id(UUID.randomUUID()).property(Property.builder().id(propertyId).name("Nhà A").build())
                .published(false).build();
        when(postRepository.findByPropertyId(propertyId)).thenReturn(Optional.of(post));
        when(postRepository.save(post)).thenReturn(post);

        AdminPostDetailResponse result = postService.publish(propertyId);

        assertThat(result.published()).isTrue();
        assertThat(result.publishedAt()).isNotNull();
    }

    @Test
    void publishPreservesExistingPublishedAtWhenAlreadyPublished() {
        UUID propertyId = UUID.randomUUID();
        java.time.LocalDateTime firstPublishedAt = java.time.LocalDateTime.now().minusDays(3);
        Post post = Post.builder().id(UUID.randomUUID()).property(Property.builder().id(propertyId).name("Nhà A").build())
                .published(true).publishedAt(firstPublishedAt).build();
        when(postRepository.findByPropertyId(propertyId)).thenReturn(Optional.of(post));
        when(postRepository.save(post)).thenReturn(post);

        AdminPostDetailResponse result = postService.publish(propertyId);

        assertThat(result.published()).isTrue();
        assertThat(result.publishedAt()).isEqualTo(firstPublishedAt);
    }

    @Test
    void unpublishClearsPublishedFlagButKeepsPublishedAt() {
        UUID propertyId = UUID.randomUUID();
        java.time.LocalDateTime firstPublishedAt = java.time.LocalDateTime.now().minusDays(3);
        Post post = Post.builder().id(UUID.randomUUID()).property(Property.builder().id(propertyId).name("Nhà A").build())
                .published(true).publishedAt(firstPublishedAt).build();
        when(postRepository.findByPropertyId(propertyId)).thenReturn(Optional.of(post));
        when(postRepository.save(post)).thenReturn(post);

        AdminPostDetailResponse result = postService.unpublish(propertyId);

        assertThat(result.published()).isFalse();
        assertThat(result.publishedAt()).isEqualTo(firstPublishedAt);
    }

    @Test
    void uploadCoverImageStoresReturnedUrlOnPost() {
        UUID propertyId = UUID.randomUUID();
        Post post = Post.builder().id(UUID.randomUUID()).property(Property.builder().id(propertyId).name("Nhà A").build()).build();
        org.springframework.web.multipart.MultipartFile file = new org.springframework.mock.web.MockMultipartFile(
                "file", "cover.jpg", "image/jpeg", new byte[]{1, 2, 3});
        when(postRepository.findByPropertyId(propertyId)).thenReturn(Optional.of(post));
        when(storageService.upload("blog/" + propertyId, file)).thenReturn("http://storage/blog/cover.jpg");
        when(postRepository.save(post)).thenReturn(post);

        AdminPostDetailResponse result = postService.uploadCoverImage(propertyId, file);

        assertThat(result.coverImageUrl()).isEqualTo("http://storage/blog/cover.jpg");
    }

    @Test
    void likeCreatesRowWhenNotAlreadyLiked() {
        UUID postId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        Post post = Post.builder().id(postId).published(true).build();
        User user = User.builder().id(userId).build();
        when(postRepository.findBySlugAndPublishedTrue("phong-tro-dep")).thenReturn(Optional.of(post));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(postLikeRepository.existsByPostIdAndUserId(postId, userId)).thenReturn(false);
        when(postLikeRepository.countByPostId(postId)).thenReturn(1L);

        LikeStatusResponse result = postService.like("phong-tro-dep", userId);

        assertThat(result.liked()).isTrue();
        assertThat(result.likeCount()).isEqualTo(1L);
        org.mockito.Mockito.verify(postLikeRepository).save(org.mockito.ArgumentMatchers.any(PostLike.class));
    }

    @Test
    void likeIsIdempotentWhenAlreadyLiked() {
        UUID postId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        Post post = Post.builder().id(postId).published(true).build();
        when(postRepository.findBySlugAndPublishedTrue("phong-tro-dep")).thenReturn(Optional.of(post));
        when(userRepository.findById(userId)).thenReturn(Optional.of(User.builder().id(userId).build()));
        when(postLikeRepository.existsByPostIdAndUserId(postId, userId)).thenReturn(true);
        when(postLikeRepository.countByPostId(postId)).thenReturn(1L);

        postService.like("phong-tro-dep", userId);

        org.mockito.Mockito.verify(postLikeRepository, org.mockito.Mockito.never()).save(org.mockito.ArgumentMatchers.any(PostLike.class));
    }

    @Test
    void unlikeDeletesTheRow() {
        UUID postId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        Post post = Post.builder().id(postId).published(true).build();
        when(postRepository.findBySlugAndPublishedTrue("phong-tro-dep")).thenReturn(Optional.of(post));
        when(postLikeRepository.countByPostId(postId)).thenReturn(0L);

        LikeStatusResponse result = postService.unlike("phong-tro-dep", userId);

        assertThat(result.liked()).isFalse();
        org.mockito.Mockito.verify(postLikeRepository).deleteByPostIdAndUserId(postId, userId);
    }
}
