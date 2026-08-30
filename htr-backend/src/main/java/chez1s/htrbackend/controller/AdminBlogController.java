package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.response.AdminPostSummaryResponse;
import chez1s.htrbackend.service.PostService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/admin/blog")
@PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN')")
@RequiredArgsConstructor
public class AdminBlogController {

    private final PostService postService;

    @GetMapping("/posts")
    public ResponseEntity<List<AdminPostSummaryResponse>> listAll() {
        return ResponseEntity.ok(postService.listAllForAdmin());
    }
}
