package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.request.UpdatePostRequest;
import chez1s.htrbackend.dto.response.AdminPostDetailResponse;
import chez1s.htrbackend.dto.response.AdminPostSummaryResponse;
import chez1s.htrbackend.dto.response.GeneratedDraftResponse;
import chez1s.htrbackend.service.PostService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

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

    @PostMapping("/posts/{propertyId}/draft")
    public ResponseEntity<GeneratedDraftResponse> generateDraft(@PathVariable UUID propertyId) {
        return ResponseEntity.ok(postService.generateDraft(propertyId));
    }

    @GetMapping("/posts/{propertyId}")
    public ResponseEntity<AdminPostDetailResponse> getByPropertyId(@PathVariable UUID propertyId) {
        return ResponseEntity.ok(postService.getForAdmin(propertyId));
    }

    @PutMapping("/posts/{propertyId}")
    public ResponseEntity<AdminPostDetailResponse> update(Authentication auth, @PathVariable UUID propertyId,
                                                           @Valid @RequestBody UpdatePostRequest req) {
        UUID authorId = (UUID) auth.getPrincipal();
        return ResponseEntity.ok(postService.upsertPost(propertyId, req, authorId));
    }
}
