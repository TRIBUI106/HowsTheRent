package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.request.CreatePostRequest;
import chez1s.htrbackend.dto.request.UpdatePostRequest;
import chez1s.htrbackend.dto.response.AdminPostCommentResponse;
import chez1s.htrbackend.dto.response.AdminPostDetailResponse;
import chez1s.htrbackend.dto.response.AdminPostSummaryResponse;
import chez1s.htrbackend.dto.response.GeneratedDraftResponse;
import chez1s.htrbackend.service.PostService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AdminBlogControllerTest {

    @Mock PostService postService;

    private AdminBlogController controller;

    @BeforeEach
    void setup() {
        controller = new AdminBlogController(postService);
    }

    @Test
    void listAllCommentsDelegatesToService() {
        AdminPostCommentResponse comment = new AdminPostCommentResponse(UUID.randomUUID(), "Đẹp quá",
                UUID.randomUUID(), "Khách A", UUID.randomUUID(), "Bài viết A", "bai-viet-a", null);
        when(postService.listAllCommentsForAdmin()).thenReturn(List.of(comment));

        ResponseEntity<List<AdminPostCommentResponse>> result = controller.listAllComments();

        assertThat(result.getBody()).containsExactly(comment);
    }

    @Test
    void deleteCommentReturnsNoContent() {
        UUID commentId = UUID.randomUUID();

        ResponseEntity<Void> result = controller.deleteComment(commentId);

        assertThat(result.getStatusCode().value()).isEqualTo(204);
        Mockito.verify(postService).deleteComment(commentId);
    }

    @Test
    void listAllDelegatesToService() {
        AdminPostSummaryResponse row = new AdminPostSummaryResponse(
                UUID.randomUUID(), UUID.randomUUID(), "A1", UUID.randomUUID(), "Nhà A",
                "Bài viết A", "bai-viet-a", false, 0L, null);
        when(postService.listAllForAdmin()).thenReturn(List.of(row));

        ResponseEntity<List<AdminPostSummaryResponse>> result = controller.listAll();

        assertThat(result.getBody()).containsExactly(row);
    }

    @Test
    void createDelegatesToServiceWithAuthorFromAuthentication() {
        UUID roomId = UUID.randomUUID();
        UUID authorId = UUID.randomUUID();
        Authentication auth = new UsernamePasswordAuthenticationToken(authorId, null, List.of());
        CreatePostRequest req = new CreatePostRequest();
        req.setRoomId(roomId);
        req.setTitle("Bài viết A");
        AdminPostDetailResponse detail = new AdminPostDetailResponse(UUID.randomUUID(), roomId, "A1", UUID.randomUUID(), "Nhà A",
                "Bài viết A", "bai-viet-a", null, null, false, null, authorId, "Admin A", null, null);
        when(postService.createPost(roomId, req, authorId)).thenReturn(detail);

        ResponseEntity<AdminPostDetailResponse> result = controller.create(auth, req);

        assertThat(result.getStatusCode().value()).isEqualTo(201);
        assertThat(result.getBody()).isEqualTo(detail);
    }

    @Test
    void getDelegatesToService() {
        UUID postId = UUID.randomUUID();
        AdminPostDetailResponse detail = new AdminPostDetailResponse(postId, UUID.randomUUID(), "A1", UUID.randomUUID(), "Nhà A",
                "Bài viết A", "bai-viet-a", "<p>...</p>", null, false, null, null, null, null, null);
        when(postService.getForAdmin(postId)).thenReturn(detail);

        ResponseEntity<AdminPostDetailResponse> result = controller.get(postId);

        assertThat(result.getBody()).isEqualTo(detail);
    }

    @Test
    void updateDelegatesToServiceWithAuthorFromAuthentication() {
        UUID postId = UUID.randomUUID();
        UUID authorId = UUID.randomUUID();
        Authentication auth = new UsernamePasswordAuthenticationToken(authorId, null, List.of());
        UpdatePostRequest req = new UpdatePostRequest();
        req.setTitle("Bài viết A");
        AdminPostDetailResponse detail = new AdminPostDetailResponse(postId, UUID.randomUUID(), "A1", UUID.randomUUID(), "Nhà A",
                "Bài viết A", "bai-viet-a", null, null, false, null, authorId, "Admin A", null, null);
        when(postService.updatePost(postId, req, authorId)).thenReturn(detail);

        ResponseEntity<AdminPostDetailResponse> result = controller.update(auth, postId, req);

        assertThat(result.getBody()).isEqualTo(detail);
    }

    @Test
    void deleteReturnsNoContent() {
        UUID postId = UUID.randomUUID();

        ResponseEntity<Void> result = controller.delete(postId);

        assertThat(result.getStatusCode().value()).isEqualTo(204);
        Mockito.verify(postService).deletePost(postId);
    }

    @Test
    void uploadCoverImageDelegatesToService() {
        UUID postId = UUID.randomUUID();
        MultipartFile file = new MockMultipartFile("file", "cover.jpg", "image/jpeg", new byte[]{1, 2, 3});
        AdminPostDetailResponse detail = new AdminPostDetailResponse(postId, UUID.randomUUID(), "A1", UUID.randomUUID(), "Nhà A",
                "Bài viết A", "bai-viet-a", null, "http://storage/blog/cover.jpg", false, null, null, null, null, null);
        when(postService.uploadCoverImage(postId, file)).thenReturn(detail);

        ResponseEntity<AdminPostDetailResponse> result = controller.uploadCoverImage(postId, file);

        assertThat(result.getBody()).isEqualTo(detail);
    }

    @Test
    void publishDelegatesToService() {
        UUID postId = UUID.randomUUID();
        AdminPostDetailResponse detail = new AdminPostDetailResponse(postId, UUID.randomUUID(), "A1", UUID.randomUUID(), "Nhà A",
                "Bài viết A", "bai-viet-a", null, null, true, null, null, null, null, null);
        when(postService.publish(postId)).thenReturn(detail);

        ResponseEntity<AdminPostDetailResponse> result = controller.publish(postId);

        assertThat(result.getBody()).isEqualTo(detail);
    }

    @Test
    void unpublishDelegatesToService() {
        UUID postId = UUID.randomUUID();
        AdminPostDetailResponse detail = new AdminPostDetailResponse(postId, UUID.randomUUID(), "A1", UUID.randomUUID(), "Nhà A",
                "Bài viết A", "bai-viet-a", null, null, false, null, null, null, null, null);
        when(postService.unpublish(postId)).thenReturn(detail);

        ResponseEntity<AdminPostDetailResponse> result = controller.unpublish(postId);

        assertThat(result.getBody()).isEqualTo(detail);
    }

    @Test
    void generateDraftDelegatesToService() {
        UUID roomId = UUID.randomUUID();
        GeneratedDraftResponse draft = new GeneratedDraftResponse("Nhà trọ Xanh - Phòng A1", "<h2>...</h2>", null);
        when(postService.generateDraft(roomId)).thenReturn(draft);

        ResponseEntity<GeneratedDraftResponse> result = controller.generateDraft(roomId);

        assertThat(result.getBody()).isEqualTo(draft);
    }
}
