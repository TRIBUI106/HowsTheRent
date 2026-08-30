package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.request.CreatePostCommentRequest;
import chez1s.htrbackend.dto.response.BlogPostDetailResponse;
import chez1s.htrbackend.dto.response.BlogPostSummaryResponse;
import chez1s.htrbackend.dto.response.LikeStatusResponse;
import chez1s.htrbackend.dto.response.PostCommentResponse;
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
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/public/blog")
@RequiredArgsConstructor
public class PublicBlogController {

    private final PostService postService;

    @GetMapping("/posts")
    public ResponseEntity<List<BlogPostSummaryResponse>> list() {
        return ResponseEntity.ok(postService.listPublished());
    }

    @GetMapping("/posts/{slug}")
    public ResponseEntity<BlogPostDetailResponse> getBySlug(@PathVariable String slug) {
        return ResponseEntity.ok(postService.getPublishedBySlug(slug));
    }

    @GetMapping("/posts/{slug}/comments")
    public ResponseEntity<List<PostCommentResponse>> listComments(@PathVariable String slug) {
        return ResponseEntity.ok(postService.listComments(slug));
    }

    @PostMapping("/posts/{slug}/comments")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<PostCommentResponse> addComment(Authentication auth, @PathVariable String slug,
                                                           @Valid @RequestBody CreatePostCommentRequest req) {
        UUID userId = (UUID) auth.getPrincipal();
        PostCommentResponse comment = postService.addComment(slug, userId, req.getContent());
        return ResponseEntity.status(HttpStatus.CREATED).body(comment);
    }

    @PostMapping("/posts/{slug}/like")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<LikeStatusResponse> like(Authentication auth, @PathVariable String slug) {
        return ResponseEntity.ok(postService.like(slug, (UUID) auth.getPrincipal()));
    }

    @DeleteMapping("/posts/{slug}/like")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<LikeStatusResponse> unlike(Authentication auth, @PathVariable String slug) {
        return ResponseEntity.ok(postService.unlike(slug, (UUID) auth.getPrincipal()));
    }
}
