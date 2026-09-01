package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Post;
import chez1s.htrbackend.domain.entity.PostComment;
import chez1s.htrbackend.domain.entity.PostLike;
import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.RoomDirection;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.*;
import chez1s.htrbackend.dto.request.CreatePostRequest;
import chez1s.htrbackend.dto.request.UpdatePostRequest;
import chez1s.htrbackend.dto.response.AdminPostCommentResponse;
import chez1s.htrbackend.dto.response.AdminPostDetailResponse;
import chez1s.htrbackend.dto.response.AdminPostSummaryResponse;
import chez1s.htrbackend.dto.response.BlogPostDetailResponse;
import chez1s.htrbackend.dto.response.BlogPostSummaryResponse;
import chez1s.htrbackend.dto.response.GeneratedDraftResponse;
import chez1s.htrbackend.dto.response.LikeStatusResponse;
import chez1s.htrbackend.dto.response.PostCommentResponse;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InOrder;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class PostServiceTest {

    @Mock PostRepository postRepository;
    @Mock PostCommentRepository postCommentRepository;
    @Mock PostLikeRepository postLikeRepository;
    @Mock RoomRepository roomRepository;
    @Mock UserRepository userRepository;
    @Mock StorageService storageService;

    @InjectMocks PostService postService;

    @Test
    void listPublishedIncludesRoomStatus() {
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà trọ Xanh").address("12 Lê Lợi").build();
        Room room = Room.builder().id(UUID.randomUUID()).roomNumber("A1").status(RoomStatus.EMPTY).property(property).build();
        Post post = Post.builder().id(UUID.randomUUID()).room(room).title("Phòng trọ đẹp")
                .slug("phong-tro-dep").coverImageUrl("http://img/1.jpg").published(true).build();
        when(postRepository.findByPublishedTrueOrderByPublishedAtDesc()).thenReturn(List.of(post));

        List<BlogPostSummaryResponse> result = postService.listPublished();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).roomNumber()).isEqualTo("A1");
        assertThat(result.get(0).roomStatus()).isEqualTo("EMPTY");
        assertThat(result.get(0).propertyName()).isEqualTo("Nhà trọ Xanh");
    }

    @Test
    void listPublishedResolvesMissingCoverImageLiveFromRoomsCurrentImages() {
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà trọ Xanh").address("12 Lê Lợi").build();
        Room room = Room.builder().id(UUID.randomUUID()).roomNumber("A1").status(RoomStatus.EMPTY).property(property)
                .images(new ArrayList<>(List.of("http://img/room-current.jpg"))).build();
        // coverImageUrl deliberately left unset -- must resolve live, not from a stale snapshot
        Post post = Post.builder().id(UUID.randomUUID()).room(room).title("Phòng trọ đẹp")
                .slug("phong-tro-dep").published(true).build();
        when(postRepository.findByPublishedTrueOrderByPublishedAtDesc()).thenReturn(List.of(post));

        List<BlogPostSummaryResponse> result = postService.listPublished();

        assertThat(result.get(0).coverImageUrl()).isEqualTo("http://img/room-current.jpg");
    }

    @Test
    void getPublishedBySlugReturnsDetailWithLikedFalseForAnonymousViewer() {
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà trọ Xanh").address("12 Lê Lợi").build();
        Room room = Room.builder().id(UUID.randomUUID()).roomNumber("A1").status(RoomStatus.EMPTY).property(property).build();
        Post post = Post.builder().id(UUID.randomUUID()).room(room).title("Phòng trọ đẹp")
                .slug("phong-tro-dep").content("<p>Nội dung</p>").published(true).build();
        when(postRepository.findBySlugAndPublishedTrue("phong-tro-dep")).thenReturn(Optional.of(post));
        when(postLikeRepository.countByPostId(post.getId())).thenReturn(7L);

        BlogPostDetailResponse result = postService.getPublishedBySlug("phong-tro-dep", null);

        assertThat(result.content()).isEqualTo("<p>Nội dung</p>");
        assertThat(result.likeCount()).isEqualTo(7L);
        assertThat(result.liked()).isFalse();
    }

    @Test
    void getPublishedBySlugReturnsLikedTrueWhenViewerAlreadyLiked() {
        UUID viewerId = UUID.randomUUID();
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà trọ Xanh").address("12 Lê Lợi").build();
        Room room = Room.builder().id(UUID.randomUUID()).roomNumber("A1").status(RoomStatus.EMPTY).property(property).build();
        Post post = Post.builder().id(UUID.randomUUID()).room(room).title("Phòng trọ đẹp")
                .slug("phong-tro-dep").content("<p>Nội dung</p>").published(true).build();
        when(postRepository.findBySlugAndPublishedTrue("phong-tro-dep")).thenReturn(Optional.of(post));
        when(postLikeRepository.countByPostId(post.getId())).thenReturn(7L);
        when(postLikeRepository.existsByPostIdAndUserId(post.getId(), viewerId)).thenReturn(true);

        BlogPostDetailResponse result = postService.getPublishedBySlug("phong-tro-dep", viewerId);

        assertThat(result.liked()).isTrue();
    }

    @Test
    void getPublishedBySlugResolvesMissingCoverImageLiveFromRoomsCurrentImages() {
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà trọ Xanh").address("12 Lê Lợi").build();
        Room room = Room.builder().id(UUID.randomUUID()).roomNumber("A1").status(RoomStatus.EMPTY).property(property)
                .images(new ArrayList<>(List.of("http://img/room-current.jpg"))).build();
        Post post = Post.builder().id(UUID.randomUUID()).room(room).title("Phòng trọ đẹp")
                .slug("phong-tro-dep").content("<p>Nội dung</p>").published(true).build();
        when(postRepository.findBySlugAndPublishedTrue("phong-tro-dep")).thenReturn(Optional.of(post));

        BlogPostDetailResponse result = postService.getPublishedBySlug("phong-tro-dep", null);

        assertThat(result.coverImageUrl()).isEqualTo("http://img/room-current.jpg");
    }

    @Test
    void getPublishedBySlugThrowsWhenMissing() {
        when(postRepository.findBySlugAndPublishedTrue("missing")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> postService.getPublishedBySlug("missing", null))
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
        when(postCommentRepository.save(any(PostComment.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        PostCommentResponse result = postService.addComment("phong-tro-dep", userId, "Rất hài lòng");

        assertThat(result.content()).isEqualTo("Rất hài lòng");
        assertThat(result.userName()).isEqualTo("Khách A");
    }

    @Test
    void listAllCommentsForAdminIncludesPostContext() {
        Post post = Post.builder().id(UUID.randomUUID()).title("Bài viết A").slug("bai-viet-a").build();
        User commenter = User.builder().id(UUID.randomUUID()).fullName("Khách A").build();
        PostComment comment = PostComment.builder().id(UUID.randomUUID()).post(post).user(commenter).content("Đẹp quá").build();
        when(postCommentRepository.findAllByOrderByCreatedAtDesc()).thenReturn(List.of(comment));

        List<AdminPostCommentResponse> result = postService.listAllCommentsForAdmin();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).postTitle()).isEqualTo("Bài viết A");
        assertThat(result.get(0).postSlug()).isEqualTo("bai-viet-a");
        assertThat(result.get(0).userName()).isEqualTo("Khách A");
    }

    @Test
    void deleteCommentThrowsWhenMissing() {
        UUID commentId = UUID.randomUUID();
        when(postCommentRepository.existsById(commentId)).thenReturn(false);

        assertThatThrownBy(() -> postService.deleteComment(commentId))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void deleteCommentDeletesExistingComment() {
        UUID commentId = UUID.randomUUID();
        when(postCommentRepository.existsById(commentId)).thenReturn(true);

        postService.deleteComment(commentId);

        Mockito.verify(postCommentRepository).deleteById(commentId);
    }

    @Test
    void listAllForAdminReturnsFlatListOfAllPosts() {
        UUID roomId = UUID.randomUUID();
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà A").build();
        Room room = Room.builder().id(roomId).roomNumber("A1").property(property).build();
        // Two posts sharing the SAME room — the direct proof the old 1-post-per-property
        // constraint (which previously crashed via Collectors.toMap on duplicate keys) is gone.
        Post post1 = Post.builder().id(UUID.randomUUID()).room(room).title("Bài viết A")
                .slug("bai-viet-a").published(true).build();
        Post post2 = Post.builder().id(UUID.randomUUID()).room(room).title("Bài viết B")
                .slug("bai-viet-b").published(false).build();
        when(postRepository.findAllByOrderByUpdatedAtDesc()).thenReturn(List.of(post1, post2));
        when(postLikeRepository.countByPostId(post1.getId())).thenReturn(5L);
        when(postLikeRepository.countByPostId(post2.getId())).thenReturn(0L);

        List<AdminPostSummaryResponse> result = postService.listAllForAdmin();

        assertThat(result).hasSize(2);
        assertThat(result).extracting(AdminPostSummaryResponse::roomId).containsOnly(roomId);
        AdminPostSummaryResponse rowA = result.stream().filter(r -> r.slug().equals("bai-viet-a")).findFirst().orElseThrow();
        assertThat(rowA.published()).isTrue();
        assertThat(rowA.likeCount()).isEqualTo(5L);
        AdminPostSummaryResponse rowB = result.stream().filter(r -> r.slug().equals("bai-viet-b")).findFirst().orElseThrow();
        assertThat(rowB.published()).isFalse();
        assertThat(rowB.likeCount()).isEqualTo(0L);
    }

    @Test
    void generateDraftBuildsHtmlFromSingleRoom() {
        UUID roomId = UUID.randomUUID();
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà trọ Xanh").address("12 Lê Lợi").build();
        Room room = Room.builder().id(roomId).roomNumber("A1").property(property)
                .status(RoomStatus.EMPTY).direction(RoomDirection.NORTH)
                .areaM2(new BigDecimal("20.5")).maxPeople(2)
                .images(new ArrayList<>(List.of("http://img/a1.jpg"))).build();
        when(roomRepository.findById(roomId)).thenReturn(Optional.of(room));

        GeneratedDraftResponse result = postService.generateDraft(roomId);

        assertThat(result.title()).contains("Nhà trọ Xanh").contains("A1");
        assertThat(result.content()).contains("A1").contains("Bắc").contains("12 Lê Lợi").contains("Còn trống");
        assertThat(result.coverImageUrl()).isEqualTo("http://img/a1.jpg");
    }

    @Test
    void getForAdminThrowsWhenPostIdMissing() {
        UUID postId = UUID.randomUUID();
        when(postRepository.findById(postId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> postService.getForAdmin(postId))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void createPostGeneratesSlugFromTitle() {
        UUID roomId = UUID.randomUUID();
        UUID authorId = UUID.randomUUID();
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà trọ Xanh").build();
        Room room = Room.builder().id(roomId).roomNumber("A1").property(property).images(new ArrayList<>()).build();
        User author = User.builder().id(authorId).fullName("Admin A").build();
        CreatePostRequest req = new CreatePostRequest();
        req.setRoomId(roomId);
        req.setTitle("Phòng Trọ Đẹp Quận 1");
        req.setContent("<p>Nội dung</p>");
        when(roomRepository.findById(roomId)).thenReturn(Optional.of(room));
        when(userRepository.findById(authorId)).thenReturn(Optional.of(author));
        when(postRepository.existsBySlug("phong-tro-dep-quan-1")).thenReturn(false);
        when(postRepository.save(any(Post.class))).thenAnswer(inv -> inv.getArgument(0));

        AdminPostDetailResponse result = postService.createPost(roomId, req, authorId);

        assertThat(result.slug()).isEqualTo("phong-tro-dep-quan-1");
        assertThat(result.title()).isEqualTo("Phòng Trọ Đẹp Quận 1");
        assertThat(result.published()).isFalse();
        assertThat(result.roomId()).isEqualTo(roomId);
    }

    @Test
    void createPostAppendsSuffixOnSlugCollision() {
        UUID roomId = UUID.randomUUID();
        UUID authorId = UUID.randomUUID();
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà trọ Xanh").build();
        Room room = Room.builder().id(roomId).roomNumber("A1").property(property).images(new ArrayList<>()).build();
        CreatePostRequest req = new CreatePostRequest();
        req.setRoomId(roomId);
        req.setTitle("Phòng Đẹp");
        when(roomRepository.findById(roomId)).thenReturn(Optional.of(room));
        when(userRepository.findById(authorId)).thenReturn(Optional.of(User.builder().id(authorId).build()));
        when(postRepository.existsBySlug("phong-dep")).thenReturn(true);
        when(postRepository.existsBySlug("phong-dep-2")).thenReturn(false);
        when(postRepository.save(any(Post.class))).thenAnswer(inv -> inv.getArgument(0));

        AdminPostDetailResponse result = postService.createPost(roomId, req, authorId);

        assertThat(result.slug()).isEqualTo("phong-dep-2");
    }

    @Test
    void createPostLeavesCoverImageUrlNullWhenNotExplicitlyProvidedSoItResolvesLiveFromRoom() {
        UUID roomId = UUID.randomUUID();
        UUID authorId = UUID.randomUUID();
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà trọ Xanh").build();
        Room room = Room.builder().id(roomId).roomNumber("A1").property(property)
                .images(new ArrayList<>(List.of("http://img/room-current.jpg"))).build();
        User author = User.builder().id(authorId).fullName("Admin A").build();
        CreatePostRequest req = new CreatePostRequest();
        req.setRoomId(roomId);
        req.setTitle("Phòng Đẹp");
        when(roomRepository.findById(roomId)).thenReturn(Optional.of(room));
        when(userRepository.findById(authorId)).thenReturn(Optional.of(author));
        when(postRepository.existsBySlug(anyString())).thenReturn(false);
        ArgumentCaptor<Post> captor = ArgumentCaptor.forClass(Post.class);
        when(postRepository.save(captor.capture())).thenAnswer(inv -> inv.getArgument(0));

        AdminPostDetailResponse result = postService.createPost(roomId, req, authorId);

        // the persisted field must stay null -- no snapshot taken at create time
        assertThat(captor.getValue().getCoverImageUrl()).isNull();
        // but the response still resolves it live from the room's current images
        assertThat(result.coverImageUrl()).isEqualTo("http://img/room-current.jpg");
    }

    @Test
    void createPostPersistsExplicitCoverImageUrlWhenProvided() {
        UUID roomId = UUID.randomUUID();
        UUID authorId = UUID.randomUUID();
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà trọ Xanh").build();
        Room room = Room.builder().id(roomId).roomNumber("A1").property(property)
                .images(new ArrayList<>(List.of("http://img/room.jpg"))).build();
        User author = User.builder().id(authorId).fullName("Admin A").build();
        CreatePostRequest req = new CreatePostRequest();
        req.setRoomId(roomId);
        req.setTitle("Phòng Đẹp");
        req.setCoverImageUrl("http://img/explicit.jpg");
        when(roomRepository.findById(roomId)).thenReturn(Optional.of(room));
        when(userRepository.findById(authorId)).thenReturn(Optional.of(author));
        when(postRepository.existsBySlug(anyString())).thenReturn(false);
        when(postRepository.save(any(Post.class))).thenAnswer(inv -> inv.getArgument(0));

        AdminPostDetailResponse result = postService.createPost(roomId, req, authorId);

        assertThat(result.coverImageUrl()).isEqualTo("http://img/explicit.jpg");
    }

    @Test
    void createPostAllowsMultiplePostsOnSameRoom() {
        UUID roomId = UUID.randomUUID();
        UUID authorId = UUID.randomUUID();
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà A").build();
        Room room = Room.builder().id(roomId).roomNumber("A1").property(property).images(new ArrayList<>()).build();
        User author = User.builder().id(authorId).build();
        when(roomRepository.findById(roomId)).thenReturn(Optional.of(room));
        when(userRepository.findById(authorId)).thenReturn(Optional.of(author));
        when(postRepository.existsBySlug(anyString())).thenReturn(false);
        when(postRepository.save(any(Post.class))).thenAnswer(inv -> inv.getArgument(0));

        CreatePostRequest req1 = new CreatePostRequest();
        req1.setRoomId(roomId);
        req1.setTitle("Bài viết lần 1");
        CreatePostRequest req2 = new CreatePostRequest();
        req2.setRoomId(roomId);
        req2.setTitle("Bài viết lần 2");

        AdminPostDetailResponse result1 = postService.createPost(roomId, req1, authorId);
        AdminPostDetailResponse result2 = postService.createPost(roomId, req2, authorId);

        assertThat(result1.roomId()).isEqualTo(roomId);
        assertThat(result2.roomId()).isEqualTo(roomId);
        assertThat(result1.slug()).isNotEqualTo(result2.slug());
    }

    @Test
    void updatePostRegeneratesSlugExcludingSelf() {
        UUID postId = UUID.randomUUID();
        UUID authorId = UUID.randomUUID();
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà A").build();
        Room room = Room.builder().id(UUID.randomUUID()).roomNumber("A1").property(property).images(new ArrayList<>()).build();
        Post post = Post.builder().id(postId).room(room).title("Old").slug("old-slug").build();
        User author = User.builder().id(authorId).fullName("Admin A").build();
        UpdatePostRequest req = new UpdatePostRequest();
        req.setTitle("Phòng Mới");
        when(postRepository.findById(postId)).thenReturn(Optional.of(post));
        when(userRepository.findById(authorId)).thenReturn(Optional.of(author));
        when(postRepository.existsBySlugAndIdNot("phong-moi", postId)).thenReturn(false);
        when(postRepository.save(any(Post.class))).thenAnswer(inv -> inv.getArgument(0));

        AdminPostDetailResponse result = postService.updatePost(postId, req, authorId);

        assertThat(result.slug()).isEqualTo("phong-moi");
        Mockito.verify(postRepository).existsBySlugAndIdNot("phong-moi", postId);
        Mockito.verify(postRepository, Mockito.never()).existsBySlug(anyString());
    }

    @Test
    void updatePostLeavesCoverImageUrlNullWhenNotExplicitlyProvidedSoItResolvesLiveFromRoom() {
        UUID postId = UUID.randomUUID();
        UUID authorId = UUID.randomUUID();
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà A").build();
        Room room = Room.builder().id(UUID.randomUUID()).roomNumber("A1").property(property)
                .images(new ArrayList<>(List.of("http://img/room-current.jpg"))).build();
        // simulates a post whose cover was previously auto-derived and snapshotted by the old code
        Post post = Post.builder().id(postId).room(room).title("Old").slug("old-slug")
                .coverImageUrl("http://img/stale-snapshot.jpg").build();
        User author = User.builder().id(authorId).fullName("Admin A").build();
        UpdatePostRequest req = new UpdatePostRequest();
        req.setTitle("Phòng Mới");
        when(postRepository.findById(postId)).thenReturn(Optional.of(post));
        when(userRepository.findById(authorId)).thenReturn(Optional.of(author));
        when(postRepository.existsBySlugAndIdNot("phong-moi", postId)).thenReturn(false);
        ArgumentCaptor<Post> captor = ArgumentCaptor.forClass(Post.class);
        when(postRepository.save(captor.capture())).thenAnswer(inv -> inv.getArgument(0));

        AdminPostDetailResponse result = postService.updatePost(postId, req, authorId);

        assertThat(captor.getValue().getCoverImageUrl()).isNull();
        assertThat(result.coverImageUrl()).isEqualTo("http://img/room-current.jpg");
    }

    @Test
    void updatePostPersistsExplicitCoverImageUrlWhenProvided() {
        UUID postId = UUID.randomUUID();
        UUID authorId = UUID.randomUUID();
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà A").build();
        Room room = Room.builder().id(UUID.randomUUID()).roomNumber("A1").property(property).images(new ArrayList<>()).build();
        Post post = Post.builder().id(postId).room(room).title("Old").slug("old-slug").build();
        User author = User.builder().id(authorId).fullName("Admin A").build();
        UpdatePostRequest req = new UpdatePostRequest();
        req.setTitle("Phòng Mới");
        req.setCoverImageUrl("http://img/explicit.jpg");
        when(postRepository.findById(postId)).thenReturn(Optional.of(post));
        when(userRepository.findById(authorId)).thenReturn(Optional.of(author));
        when(postRepository.existsBySlugAndIdNot("phong-moi", postId)).thenReturn(false);
        when(postRepository.save(any(Post.class))).thenAnswer(inv -> inv.getArgument(0));

        AdminPostDetailResponse result = postService.updatePost(postId, req, authorId);

        assertThat(result.coverImageUrl()).isEqualTo("http://img/explicit.jpg");
    }

    @Test
    void deletePostRemovesCommentsAndLikesBeforeThePost() {
        UUID postId = UUID.randomUUID();
        when(postRepository.existsById(postId)).thenReturn(true);

        postService.deletePost(postId);

        InOrder inOrder = Mockito.inOrder(postCommentRepository, postLikeRepository, postRepository);
        inOrder.verify(postCommentRepository).deleteAllByPostId(postId);
        inOrder.verify(postLikeRepository).deleteAllByPostId(postId);
        inOrder.verify(postRepository).deleteById(postId);
    }

    @Test
    void deletePostThrowsWhenMissing() {
        UUID postId = UUID.randomUUID();
        when(postRepository.existsById(postId)).thenReturn(false);

        assertThatThrownBy(() -> postService.deletePost(postId))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void publishSetsPublishedAtOnlyOnFirstPublish() {
        UUID postId = UUID.randomUUID();
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà A").build();
        Room room = Room.builder().id(UUID.randomUUID()).roomNumber("A1").property(property).build();
        Post post = Post.builder().id(postId).room(room).published(false).build();
        when(postRepository.findById(postId)).thenReturn(Optional.of(post));
        when(postRepository.save(post)).thenReturn(post);

        AdminPostDetailResponse result = postService.publish(postId);

        assertThat(result.published()).isTrue();
        assertThat(result.publishedAt()).isNotNull();
    }

    @Test
    void publishPreservesExistingPublishedAtWhenAlreadyPublished() {
        UUID postId = UUID.randomUUID();
        LocalDateTime firstPublishedAt = LocalDateTime.now().minusDays(3);
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà A").build();
        Room room = Room.builder().id(UUID.randomUUID()).roomNumber("A1").property(property).build();
        Post post = Post.builder().id(postId).room(room).published(true).publishedAt(firstPublishedAt).build();
        when(postRepository.findById(postId)).thenReturn(Optional.of(post));
        when(postRepository.save(post)).thenReturn(post);

        AdminPostDetailResponse result = postService.publish(postId);

        assertThat(result.published()).isTrue();
        assertThat(result.publishedAt()).isEqualTo(firstPublishedAt);
    }

    @Test
    void unpublishClearsPublishedFlagButKeepsPublishedAt() {
        UUID postId = UUID.randomUUID();
        LocalDateTime firstPublishedAt = LocalDateTime.now().minusDays(3);
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà A").build();
        Room room = Room.builder().id(UUID.randomUUID()).roomNumber("A1").property(property).build();
        Post post = Post.builder().id(postId).room(room).published(true).publishedAt(firstPublishedAt).build();
        when(postRepository.findById(postId)).thenReturn(Optional.of(post));
        when(postRepository.save(post)).thenReturn(post);

        AdminPostDetailResponse result = postService.unpublish(postId);

        assertThat(result.published()).isFalse();
        assertThat(result.publishedAt()).isEqualTo(firstPublishedAt);
    }

    @Test
    void uploadCoverImageStoresReturnedUrlOnPost() {
        UUID postId = UUID.randomUUID();
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà A").build();
        Room room = Room.builder().id(UUID.randomUUID()).roomNumber("A1").property(property).build();
        Post post = Post.builder().id(postId).room(room).build();
        MultipartFile file = new MockMultipartFile("file", "cover.jpg", "image/jpeg", new byte[]{1, 2, 3});
        when(postRepository.findById(postId)).thenReturn(Optional.of(post));
        when(storageService.upload("blog/" + postId, file)).thenReturn("http://storage/blog/cover.jpg");
        when(postRepository.save(post)).thenReturn(post);

        AdminPostDetailResponse result = postService.uploadCoverImage(postId, file);

        assertThat(result.coverImageUrl()).isEqualTo("http://storage/blog/cover.jpg");
        Mockito.verify(storageService, Mockito.never()).delete(anyString());
    }

    @Test
    void uploadCoverImageDeletesPreviousObjectWhenReplacingAnExistingCoverImage() {
        UUID postId = UUID.randomUUID();
        Property property = Property.builder().id(UUID.randomUUID()).name("Nhà A").build();
        Room room = Room.builder().id(UUID.randomUUID()).roomNumber("A1").property(property).build();
        Post post = Post.builder().id(postId).room(room).coverImageUrl("http://storage/blog/old.jpg").build();
        MultipartFile file = new MockMultipartFile("file", "cover.jpg", "image/jpeg", new byte[]{1, 2, 3});
        when(postRepository.findById(postId)).thenReturn(Optional.of(post));
        when(storageService.upload("blog/" + postId, file)).thenReturn("http://storage/blog/new.jpg");
        when(postRepository.save(post)).thenReturn(post);

        AdminPostDetailResponse result = postService.uploadCoverImage(postId, file);

        assertThat(result.coverImageUrl()).isEqualTo("http://storage/blog/new.jpg");
        Mockito.verify(storageService).delete("http://storage/blog/old.jpg");
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
        Mockito.verify(postLikeRepository).save(any(PostLike.class));
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

        Mockito.verify(postLikeRepository, Mockito.never()).save(any(PostLike.class));
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
        Mockito.verify(postLikeRepository).deleteByPostIdAndUserId(postId, userId);
    }
}
