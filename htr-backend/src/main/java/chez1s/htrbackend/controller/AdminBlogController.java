package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.request.CreatePostRequest;
import chez1s.htrbackend.dto.request.UpdatePostRequest;
import chez1s.htrbackend.dto.response.AdminPostCommentResponse;
import chez1s.htrbackend.dto.response.AdminPostDetailResponse;
import chez1s.htrbackend.dto.response.AdminPostSummaryResponse;
import chez1s.htrbackend.dto.response.GeneratedDraftResponse;
import chez1s.htrbackend.service.PostService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/blog")
@PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN')")
@RequiredArgsConstructor
public class AdminBlogController {

    private final PostService postService;

    @GetMapping("/comments")
    public ResponseEntity<List<AdminPostCommentResponse>> listAllComments() {
        return ResponseEntity.ok(postService.listAllCommentsForAdmin());
    }

    @DeleteMapping("/comments/{id}")
    public ResponseEntity<Void> deleteComment(@PathVariable UUID id) {
        postService.deleteComment(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/posts")
    public ResponseEntity<List<AdminPostSummaryResponse>> listAll() {
        return ResponseEntity.ok(postService.listAllForAdmin());
    }

    @PostMapping("/posts")
    public ResponseEntity<AdminPostDetailResponse> create(Authentication auth,
                                                           @Valid @RequestBody CreatePostRequest req) {
        UUID authorId = (UUID) auth.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED).body(postService.createPost(req.getRoomId(), req, authorId));
    }

    @GetMapping("/posts/{postId}")
    public ResponseEntity<AdminPostDetailResponse> get(@PathVariable UUID postId) {
        return ResponseEntity.ok(postService.getForAdmin(postId));
    }

    @PutMapping("/posts/{postId}")
    public ResponseEntity<AdminPostDetailResponse> update(Authentication auth, @PathVariable UUID postId,
                                                           @Valid @RequestBody UpdatePostRequest req) {
        UUID authorId = (UUID) auth.getPrincipal();
        return ResponseEntity.ok(postService.updatePost(postId, req, authorId));
    }

    @DeleteMapping("/posts/{postId}")
    public ResponseEntity<Void> delete(@PathVariable UUID postId) {
        postService.deletePost(postId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/posts/{postId}/cover-image")
    public ResponseEntity<AdminPostDetailResponse> uploadCoverImage(@PathVariable UUID postId,
                                                                     @RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(postService.uploadCoverImage(postId, file));
    }

    @PostMapping("/posts/{postId}/publish")
    public ResponseEntity<AdminPostDetailResponse> publish(@PathVariable UUID postId) {
        return ResponseEntity.ok(postService.publish(postId));
    }

    @PostMapping("/posts/{postId}/unpublish")
    public ResponseEntity<AdminPostDetailResponse> unpublish(@PathVariable UUID postId) {
        return ResponseEntity.ok(postService.unpublish(postId));
    }

    @PostMapping("/rooms/{roomId}/draft")
    public ResponseEntity<GeneratedDraftResponse> generateDraft(@PathVariable UUID roomId) {
        return ResponseEntity.ok(postService.generateDraft(roomId));
    }
}
