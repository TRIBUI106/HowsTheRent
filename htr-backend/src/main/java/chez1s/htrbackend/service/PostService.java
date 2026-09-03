package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Post;
import chez1s.htrbackend.domain.entity.PostComment;
import chez1s.htrbackend.domain.entity.PostLike;
import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.*;
import chez1s.htrbackend.dto.request.CreatePostRequest;
import chez1s.htrbackend.dto.request.UpdatePostRequest;
import chez1s.htrbackend.dto.response.AdminPostCommentResponse;
import chez1s.htrbackend.dto.response.AdminPostDetailResponse;
import chez1s.htrbackend.dto.response.AdminPostSummaryResponse;
import chez1s.htrbackend.dto.response.BlogPostDetailResponse;
import chez1s.htrbackend.dto.response.BlogPostSummaryResponse;
import chez1s.htrbackend.dto.response.GeneratedDraftResponse;
import chez1s.htrbackend.dto.response.LikeStatusResponse;
import chez1s.htrbackend.dto.response.PostCommentResponse;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.text.Normalizer;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PostService {

    private final PostRepository postRepository;
    private final PostCommentRepository postCommentRepository;
    private final PostLikeRepository postLikeRepository;
    private final RoomRepository roomRepository;
    private final UserRepository userRepository;
    private final StorageService storageService;

    @Transactional(readOnly = true)
    public List<BlogPostSummaryResponse> listPublished() {
        return postRepository.findByPublishedTrueOrderByPublishedAtDesc().stream()
                .map(this::toSummary)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AdminPostCommentResponse> listAllCommentsForAdmin() {
        return postCommentRepository.findAllByOrderByCreatedAtDesc().stream()
                .map(AdminPostCommentResponse::from)
                .toList();
    }

    @Transactional
    public void deleteComment(UUID commentId) {
        if (!postCommentRepository.existsById(commentId)) {
            throw new ResourceNotFoundException("PostComment", commentId);
        }
        postCommentRepository.deleteById(commentId);
    }

    @Transactional(readOnly = true)
    public List<AdminPostSummaryResponse> listAllForAdmin() {
        return postRepository.findAllByOrderByUpdatedAtDesc().stream()
                .map(post -> {
                    Room room = post.getRoom();
                    Property property = room.getProperty();
                    return new AdminPostSummaryResponse(
                            post.getId(), room.getId(), room.getRoomNumber(),
                            property.getId(), property.getName(),
                            post.getTitle(), post.getSlug(), post.isPublished(),
                            postLikeRepository.countByPostId(post.getId()), post.getUpdatedAt(),
                            post.getPublishAt()
                    );
                })
                .toList();
    }

    @Transactional(readOnly = true)
    public GeneratedDraftResponse generateDraft(UUID roomId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResourceNotFoundException("Room", roomId));
        Property property = room.getProperty();

        StringBuilder html = new StringBuilder();
        html.append("<h2>").append(escapeHtml(property.getName()))
                .append(" — Phòng ").append(escapeHtml(room.getRoomNumber())).append("</h2>");
        html.append("<p>").append(escapeHtml(property.getAddress())).append("</p>");
        html.append("<p><strong>").append(roomStatusSentence(room.getStatus())).append("</strong></p>");
        html.append("<ul>");
        if (room.getAreaM2() != null) {
            html.append("<li>Diện tích: ").append(room.getAreaM2()).append(" m²</li>");
        }
        if (room.getMaxPeople() != null) {
            html.append("<li>Sức chứa: ").append(room.getMaxPeople()).append(" người</li>");
        }
        if (room.getDirection() != null) {
            html.append("<li>Hướng: ").append(directionLabel(room.getDirection())).append("</li>");
        }
        html.append("</ul>");
        if (room.getDescription() != null && !room.getDescription().isBlank()) {
            html.append("<p>").append(escapeHtml(room.getDescription())).append("</p>");
        }

        String coverImageUrl = resolveDefaultCoverImage(room);

        return new GeneratedDraftResponse(
                property.getName() + " - Phòng " + room.getRoomNumber(),
                html.toString(),
                coverImageUrl
        );
    }

    @Transactional(readOnly = true)
    public AdminPostDetailResponse getForAdmin(UUID postId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new ResourceNotFoundException("Post", postId));
        return AdminPostDetailResponse.from(post);
    }

    @Transactional
    public AdminPostDetailResponse createPost(UUID roomId, CreatePostRequest req, UUID authorId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResourceNotFoundException("Room", roomId));
        User author = userRepository.findById(authorId)
                .orElseThrow(() -> new ResourceNotFoundException("User", authorId));

        Post post = new Post();
        post.setRoom(room);
        post.setTitle(req.getTitle());
        post.setContent(req.getContent());
        post.setCoverImageUrl(req.getCoverImageUrl());
        post.setAuthor(author);
        post.setPublishAt(req.getPublishAt());
        post.setTags(req.getTags() != null ? req.getTags() : new ArrayList<>());

        String desiredSlug = req.getSlug() != null && !req.getSlug().isBlank()
                ? slugify(req.getSlug())
                : slugify(req.getTitle());
        post.setSlug(uniqueSlug(desiredSlug, null));

        return AdminPostDetailResponse.from(postRepository.save(post));
    }

    @Transactional
    public AdminPostDetailResponse updatePost(UUID postId, UpdatePostRequest req, UUID authorId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new ResourceNotFoundException("Post", postId));
        User author = userRepository.findById(authorId)
                .orElseThrow(() -> new ResourceNotFoundException("User", authorId));

        post.setTitle(req.getTitle());
        post.setContent(req.getContent());
        post.setCoverImageUrl(req.getCoverImageUrl());
        post.setAuthor(author);
        post.setPublishAt(req.getPublishAt());
        post.setTags(req.getTags() != null ? req.getTags() : new ArrayList<>());

        String desiredSlug = req.getSlug() != null && !req.getSlug().isBlank()
                ? slugify(req.getSlug())
                : slugify(req.getTitle());
        post.setSlug(uniqueSlug(desiredSlug, postId));

        return AdminPostDetailResponse.from(postRepository.save(post));
    }

    @Transactional
    public void deletePost(UUID postId) {
        if (!postRepository.existsById(postId)) {
            throw new ResourceNotFoundException("Post", postId);
        }
        postCommentRepository.deleteAllByPostId(postId);
        postLikeRepository.deleteAllByPostId(postId);
        postRepository.deleteById(postId);
    }

    @Transactional
    public AdminPostDetailResponse publish(UUID postId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new ResourceNotFoundException("Post", postId));
        if (!post.isPublished()) {
            post.setPublished(true);
            post.setPublishedAt(LocalDateTime.now());
        }
        return AdminPostDetailResponse.from(postRepository.save(post));
    }

    @Transactional
    public AdminPostDetailResponse unpublish(UUID postId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new ResourceNotFoundException("Post", postId));
        post.setPublished(false);
        return AdminPostDetailResponse.from(postRepository.save(post));
    }

    @Transactional
    public AdminPostDetailResponse uploadCoverImage(UUID postId, MultipartFile file) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new ResourceNotFoundException("Post", postId));
        String previousCoverImageUrl = post.getCoverImageUrl();
        post.setCoverImageUrl(storageService.upload("blog/" + postId, file));
        if (previousCoverImageUrl != null) {
            storageService.delete(previousCoverImageUrl);
        }
        return AdminPostDetailResponse.from(postRepository.save(post));
    }

    @Transactional(readOnly = true)
    public BlogPostDetailResponse getPublishedBySlug(String slug, UUID viewerId) {
        Post post = postRepository.findBySlugAndPublishedTrue(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Post", slug));
        return toDetail(post, viewerId);
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

    private String escapeHtml(String input) {
        return input == null ? "" : input
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }

    private String directionLabel(chez1s.htrbackend.domain.enums.RoomDirection direction) {
        return switch (direction) {
            case NORTH -> "Bắc";
            case SOUTH -> "Nam";
            case EAST -> "Đông";
            case WEST -> "Tây";
            case NORTHEAST -> "Đông Bắc";
            case NORTHWEST -> "Tây Bắc";
            case SOUTHEAST -> "Đông Nam";
            case SOUTHWEST -> "Tây Nam";
        };
    }

    private String roomStatusSentence(RoomStatus status) {
        return switch (status) {
            case EMPTY -> "Còn trống";
            case RENTED -> "Đã cho thuê";
            case MAINTENANCE -> "Đang bảo trì";
        };
    }

    private String resolveDefaultCoverImage(Room room) {
        return room.getImages().stream().findFirst().orElse(null);
    }

    private String uniqueSlug(String base, UUID excludingPostId) {
        String candidate = base;
        int suffix = 2;
        while (excludingPostId == null
                ? postRepository.existsBySlug(candidate)
                : postRepository.existsBySlugAndIdNot(candidate, excludingPostId)) {
            candidate = base + "-" + suffix;
            suffix++;
        }
        return candidate;
    }

    private String slugify(String input) {
        String withoutDiacritics = Normalizer.normalize(input, Normalizer.Form.NFD)
                .replaceAll("\\p{InCombiningDiacriticalMarks}+", "")
                .replace('đ', 'd').replace('Đ', 'D');
        return withoutDiacritics.toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9\\s-]", "")
                .trim()
                .replaceAll("\\s+", "-")
                .replaceAll("-+", "-");
    }

    private BlogPostSummaryResponse toSummary(Post post) {
        Room room = post.getRoom();
        Property property = room.getProperty();
        return new BlogPostSummaryResponse(
                post.getId(), post.getSlug(), post.getTitle(), post.getEffectiveCoverImageUrl(),
                room.getId(), room.getRoomNumber(), room.getStatus().name(),
                property.getId(), property.getName(), property.getAddress(),
                post.getPublishedAt(), post.getTags()
        );
    }

    private BlogPostDetailResponse toDetail(Post post, UUID viewerId) {
        Room room = post.getRoom();
        Property property = room.getProperty();
        long likeCount = postLikeRepository.countByPostId(post.getId());
        boolean liked = viewerId != null && postLikeRepository.existsByPostIdAndUserId(post.getId(), viewerId);
        // post.getTags() is deliberately copied (not passed straight through) while this method's
        // caller (getPublishedBySlug) still has its @Transactional(readOnly = true) session open.
        // PostRepository.findBySlugAndPublishedTrue() can't join-fetch tags via @EntityGraph
        // alongside room.images (Hibernate refuses to fetch two bag collections in one query — see
        // the comment on that repository method), so tags stays an uninitialized lazy collection
        // reference straight out of the repository call. Copying it here forces Hibernate to load
        // it now, inside the session, instead of leaving a lazy proxy sitting in the response DTO
        // that would throw LazyInitializationException once Jackson tries to serialize it later.
        List<String> tags = new ArrayList<>(post.getTags());
        return new BlogPostDetailResponse(
                post.getId(), post.getSlug(), post.getTitle(), post.getContent(), post.getEffectiveCoverImageUrl(),
                room.getId(), room.getRoomNumber(), room.getStatus().name(),
                room.getDirection() != null ? room.getDirection().name() : null,
                room.getAreaM2(), room.getMaxPeople(), room.getImages(),
                property.getId(), property.getName(), property.getAddress(),
                post.getPublishedAt(), likeCount, liked, tags
        );
    }
}
