package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.request.UpdatePostRequest;
import chez1s.htrbackend.dto.response.AdminPostDetailResponse;
import chez1s.htrbackend.dto.response.AdminPostSummaryResponse;
import chez1s.htrbackend.service.PostService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;

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
    void listAllDelegatesToService() {
        AdminPostSummaryResponse row = new AdminPostSummaryResponse(UUID.randomUUID(), "Nhà A", null, null, null, false, null);
        when(postService.listAllForAdmin()).thenReturn(List.of(row));

        ResponseEntity<List<AdminPostSummaryResponse>> result = controller.listAll();

        assertThat(result.getBody()).containsExactly(row);
    }

    @Test
    void getByPropertyIdDelegatesToService() {
        UUID propertyId = UUID.randomUUID();
        AdminPostDetailResponse detail = new AdminPostDetailResponse(UUID.randomUUID(), propertyId, "Nhà A",
                "Bài viết A", "bai-viet-a", "<p>...</p>", null, false, null, null, null, null, null);
        when(postService.getForAdmin(propertyId)).thenReturn(detail);

        ResponseEntity<AdminPostDetailResponse> result = controller.getByPropertyId(propertyId);

        assertThat(result.getBody()).isEqualTo(detail);
    }

    @Test
    void updateDelegatesToServiceWithAuthorFromAuthentication() {
        UUID propertyId = UUID.randomUUID();
        UUID authorId = UUID.randomUUID();
        Authentication auth = new UsernamePasswordAuthenticationToken(authorId, null, List.of());
        UpdatePostRequest req = new UpdatePostRequest();
        req.setTitle("Bài viết A");
        AdminPostDetailResponse detail = new AdminPostDetailResponse(UUID.randomUUID(), propertyId, "Nhà A",
                "Bài viết A", "bai-viet-a", null, null, false, null, authorId, "Admin A", null, null);
        when(postService.upsertPost(propertyId, req, authorId)).thenReturn(detail);

        ResponseEntity<AdminPostDetailResponse> result = controller.update(auth, propertyId, req);

        assertThat(result.getBody()).isEqualTo(detail);
    }
}
