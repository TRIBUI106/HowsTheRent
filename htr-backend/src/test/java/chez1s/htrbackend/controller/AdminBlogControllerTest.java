package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.response.AdminPostSummaryResponse;
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
}
