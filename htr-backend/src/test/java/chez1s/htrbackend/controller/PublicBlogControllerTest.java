package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.request.CreatePostCommentRequest;
import chez1s.htrbackend.dto.response.BlogPostDetailResponse;
import chez1s.htrbackend.dto.response.BlogPostSummaryResponse;
import chez1s.htrbackend.dto.response.LikeStatusResponse;
import chez1s.htrbackend.dto.response.PostCommentResponse;
import chez1s.htrbackend.service.PostService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PublicBlogControllerTest {

    @Mock PostService postService;

    private PublicBlogController controller;

    @BeforeEach
    void setup() {
        controller = new PublicBlogController(postService);
    }

    @Test
    void listReturnsAllPublishedPosts() {
        BlogPostSummaryResponse summary = new BlogPostSummaryResponse(
                UUID.randomUUID(), "phong-tro-dep", "Phòng trọ đẹp", null,
                UUID.randomUUID(), "A1", "EMPTY",
                UUID.randomUUID(), "Nhà trọ Xanh", "12 Lê Lợi", null, List.of());
        when(postService.listPublished()).thenReturn(List.of(summary));

        ResponseEntity<List<BlogPostSummaryResponse>> result = controller.list();

        assertThat(result.getBody()).containsExactly(summary);
    }

    @Test
    void getBySlugPassesNullViewerIdForAnAnonymousRequest() {
        BlogPostDetailResponse detail = new BlogPostDetailResponse(
                UUID.randomUUID(), "phong-tro-dep", "Phòng trọ đẹp", "<p>Nội dung</p>", null,
                UUID.randomUUID(), "A1", "EMPTY", null, null, null, List.of(),
                UUID.randomUUID(), "Nhà trọ Xanh", "12 Lê Lợi", null, 0L, false, List.of());
        when(postService.getPublishedBySlug("phong-tro-dep", null)).thenReturn(detail);

        ResponseEntity<BlogPostDetailResponse> result = controller.getBySlug(null, "phong-tro-dep");

        assertThat(result.getBody()).isEqualTo(detail);
    }

    @Test
    void getBySlugPassesViewerIdForAnAuthenticatedRequest() {
        UUID userId = UUID.randomUUID();
        Authentication auth = new UsernamePasswordAuthenticationToken(userId, null, List.of());
        BlogPostDetailResponse detail = new BlogPostDetailResponse(
                UUID.randomUUID(), "phong-tro-dep", "Phòng trọ đẹp", "<p>Nội dung</p>", null,
                UUID.randomUUID(), "A1", "EMPTY", null, null, null, List.of(),
                UUID.randomUUID(), "Nhà trọ Xanh", "12 Lê Lợi", null, 1L, true, List.of());
        when(postService.getPublishedBySlug("phong-tro-dep", userId)).thenReturn(detail);

        ResponseEntity<BlogPostDetailResponse> result = controller.getBySlug(auth, "phong-tro-dep");

        assertThat(result.getBody()).isEqualTo(detail);
    }

    @Test
    void listCommentsDelegatesToService() {
        PostCommentResponse comment = new PostCommentResponse(UUID.randomUUID(), "Đẹp quá", UUID.randomUUID(), "Khách A", null);
        when(postService.listComments("phong-tro-dep")).thenReturn(List.of(comment));

        ResponseEntity<List<PostCommentResponse>> result = controller.listComments("phong-tro-dep");

        assertThat(result.getBody()).containsExactly(comment);
    }

    @Test
    void addCommentReturns201WithCreatedComment() {
        UUID userId = UUID.randomUUID();
        Authentication auth = new UsernamePasswordAuthenticationToken(userId, null, List.of());
        CreatePostCommentRequest req = new CreatePostCommentRequest();
        req.setContent("Rất hài lòng");
        PostCommentResponse created = new PostCommentResponse(UUID.randomUUID(), "Rất hài lòng", userId, "Khách A", null);
        when(postService.addComment("phong-tro-dep", userId, "Rất hài lòng")).thenReturn(created);

        ResponseEntity<PostCommentResponse> result = controller.addComment(auth, "phong-tro-dep", req);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(result.getBody()).isEqualTo(created);
    }

    @Test
    void likeDelegatesToService() {
        UUID userId = UUID.randomUUID();
        Authentication auth = new UsernamePasswordAuthenticationToken(userId, null, List.of());
        LikeStatusResponse status = new LikeStatusResponse(true, 1L);
        when(postService.like("phong-tro-dep", userId)).thenReturn(status);

        ResponseEntity<LikeStatusResponse> result = controller.like(auth, "phong-tro-dep");

        assertThat(result.getBody()).isEqualTo(status);
    }

    @Test
    void unlikeDelegatesToService() {
        UUID userId = UUID.randomUUID();
        Authentication auth = new UsernamePasswordAuthenticationToken(userId, null, List.of());
        LikeStatusResponse status = new LikeStatusResponse(false, 0L);
        when(postService.unlike("phong-tro-dep", userId)).thenReturn(status);

        ResponseEntity<LikeStatusResponse> result = controller.unlike(auth, "phong-tro-dep");

        assertThat(result.getBody()).isEqualTo(status);
    }
}
