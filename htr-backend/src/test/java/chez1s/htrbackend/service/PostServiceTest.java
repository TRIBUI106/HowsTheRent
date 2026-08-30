package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Post;
import chez1s.htrbackend.domain.entity.PostComment;
import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.*;
import chez1s.htrbackend.dto.response.BlogPostDetailResponse;
import chez1s.htrbackend.dto.response.BlogPostSummaryResponse;
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
}
