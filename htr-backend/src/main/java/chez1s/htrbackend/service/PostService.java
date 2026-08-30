package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Post;
import chez1s.htrbackend.domain.entity.PostComment;
import chez1s.htrbackend.domain.entity.PostLike;
import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.*;
import chez1s.htrbackend.dto.response.BlogPostDetailResponse;
import chez1s.htrbackend.dto.response.BlogPostSummaryResponse;
import chez1s.htrbackend.dto.response.LikeStatusResponse;
import chez1s.htrbackend.dto.response.PostCommentResponse;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PostService {

    private final PostRepository postRepository;
    private final PostCommentRepository postCommentRepository;
    private final PostLikeRepository postLikeRepository;
    private final RoomRepository roomRepository;
    private final PropertyRepository propertyRepository;
    private final UserRepository userRepository;
    private final PropertyService propertyService;
    private final StorageService storageService;

    @Transactional(readOnly = true)
    public List<BlogPostSummaryResponse> listPublished() {
        return postRepository.findByPublishedTrueOrderByPublishedAtDesc().stream()
                .map(this::toSummary)
                .toList();
    }

    @Transactional(readOnly = true)
    public BlogPostDetailResponse getPublishedBySlug(String slug) {
        Post post = postRepository.findBySlugAndPublishedTrue(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Post", slug));
        return toDetail(post);
    }

    @Transactional(readOnly = true)
    public List<PostCommentResponse> listComments(String slug) {
        Post post = postRepository.findBySlugAndPublishedTrue(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Post", slug));
        return postCommentRepository.findByPostIdOrderByCreatedAtAsc(post.getId()).stream()
                .map(PostCommentResponse::from)
                .toList();
    }

    @Transactional
    public PostCommentResponse addComment(String slug, java.util.UUID userId, String content) {
        Post post = postRepository.findBySlugAndPublishedTrue(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Post", slug));
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));
        PostComment comment = PostComment.builder()
                .post(post)
                .user(user)
                .content(content)
                .build();
        return PostCommentResponse.from(postCommentRepository.save(comment));
    }

    @Transactional
    public LikeStatusResponse like(String slug, java.util.UUID userId) {
        Post post = postRepository.findBySlugAndPublishedTrue(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Post", slug));
        if (!postLikeRepository.existsByPostIdAndUserId(post.getId(), userId)) {
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new ResourceNotFoundException("User", userId));
            postLikeRepository.save(PostLike.builder().post(post).user(user).build());
        }
        return new LikeStatusResponse(true, postLikeRepository.countByPostId(post.getId()));
    }

    @Transactional
    public LikeStatusResponse unlike(String slug, java.util.UUID userId) {
        Post post = postRepository.findBySlugAndPublishedTrue(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Post", slug));
        postLikeRepository.deleteByPostIdAndUserId(post.getId(), userId);
        return new LikeStatusResponse(false, postLikeRepository.countByPostId(post.getId()));
    }

    private BlogPostSummaryResponse toSummary(Post post) {
        Property property = post.getProperty();
        long empty = roomRepository.countByPropertyIdAndStatus(property.getId(), RoomStatus.EMPTY);
        long rented = roomRepository.countByPropertyIdAndStatus(property.getId(), RoomStatus.RENTED);
        long maintenance = roomRepository.countByPropertyIdAndStatus(property.getId(), RoomStatus.MAINTENANCE);
        return new BlogPostSummaryResponse(
                post.getId(), post.getSlug(), post.getTitle(), post.getCoverImageUrl(),
                property.getId(), property.getName(), property.getAddress(),
                empty, empty + rented + maintenance, post.getPublishedAt()
        );
    }

    private BlogPostDetailResponse toDetail(Post post) {
        Property property = post.getProperty();
        long likeCount = postLikeRepository.countByPostId(post.getId());
        return new BlogPostDetailResponse(
                post.getId(), post.getSlug(), post.getTitle(), post.getContent(), post.getCoverImageUrl(),
                property.getId(), property.getName(), property.getAddress(), post.getPublishedAt(), likeCount
        );
    }
}
