package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.response.BlogPostDetailResponse;
import chez1s.htrbackend.dto.response.BlogPostSummaryResponse;
import chez1s.htrbackend.dto.response.PostCommentResponse;
import chez1s.htrbackend.service.PostService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;

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
                UUID.randomUUID(), "Nhà trọ Xanh", "12 Lê Lợi", 1L, 4L, null);
        when(postService.listPublished()).thenReturn(List.of(summary));

        ResponseEntity<List<BlogPostSummaryResponse>> result = controller.list();

        assertThat(result.getBody()).containsExactly(summary);
    }

    @Test
    void getBySlugDelegatesToService() {
        BlogPostDetailResponse detail = new BlogPostDetailResponse(
                UUID.randomUUID(), "phong-tro-dep", "Phòng trọ đẹp", "<p>Nội dung</p>", null,
                UUID.randomUUID(), "Nhà trọ Xanh", "12 Lê Lợi", null, 0L);
        when(postService.getPublishedBySlug("phong-tro-dep")).thenReturn(detail);

        ResponseEntity<BlogPostDetailResponse> result = controller.getBySlug("phong-tro-dep");

        assertThat(result.getBody()).isEqualTo(detail);
    }

    @Test
    void listCommentsDelegatesToService() {
        PostCommentResponse comment = new PostCommentResponse(UUID.randomUUID(), "Đẹp quá", UUID.randomUUID(), "Khách A", null);
        when(postService.listComments("phong-tro-dep")).thenReturn(List.of(comment));

        ResponseEntity<List<PostCommentResponse>> result = controller.listComments("phong-tro-dep");

        assertThat(result.getBody()).containsExactly(comment);
    }
}
