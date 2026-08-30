package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.response.BlogPostDetailResponse;
import chez1s.htrbackend.dto.response.BlogPostSummaryResponse;
import chez1s.htrbackend.dto.response.PostCommentResponse;
import chez1s.htrbackend.service.PostService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

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
}
