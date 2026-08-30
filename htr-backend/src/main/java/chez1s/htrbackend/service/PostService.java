package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Post;
import chez1s.htrbackend.domain.entity.PostComment;
import chez1s.htrbackend.domain.entity.PostLike;
import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.*;
import chez1s.htrbackend.dto.request.UpdatePostRequest;
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

import java.text.Normalizer;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

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
    public List<AdminPostSummaryResponse> listAllForAdmin() {
        Map<UUID, Post> postsByPropertyId = postRepository.findAll().stream()
                .collect(Collectors.toMap(post -> post.getProperty().getId(), post -> post));
        return propertyRepository.findAll().stream()
                .map(property -> {
                    Post post = postsByPropertyId.get(property.getId());
                    return new AdminPostSummaryResponse(
                            property.getId(),
                            property.getName(),
                            post != null ? post.getId() : null,
                            post != null ? post.getTitle() : null,
                            post != null ? post.getSlug() : null,
                            post != null && post.isPublished(),
                            post != null ? post.getUpdatedAt() : null
                    );
                })
                .toList();
    }

    @Transactional(readOnly = true)
    public GeneratedDraftResponse generateDraft(UUID propertyId) {
        Property property = propertyService.getById(propertyId);
        List<Room> rooms = roomRepository.findByPropertyId(propertyId);
        long emptyCount = rooms.stream().filter(room -> room.getStatus() == RoomStatus.EMPTY).count();

        StringBuilder html = new StringBuilder();
        html.append("<h2>").append(escapeHtml(property.getName())).append("</h2>");
        html.append("<p>").append(escapeHtml(property.getAddress())).append("</p>");
        if (property.getDescription() != null && !property.getDescription().isBlank()) {
            html.append("<p>").append(escapeHtml(property.getDescription())).append("</p>");
        }
        html.append("<p><strong>").append(emptyCount).append("/").append(rooms.size()).append(" phòng còn trống</strong></p>");
        html.append("<h3>Danh sách phòng</h3><ul>");
        for (Room room : rooms) {
            html.append("<li>Phòng ").append(escapeHtml(room.getRoomNumber()));
            if (room.getDirection() != null) {
                html.append(" — hướng ").append(directionLabel(room.getDirection()));
            }
            if (room.getDescription() != null && !room.getDescription().isBlank()) {
                html.append(": ").append(escapeHtml(room.getDescription()));
            }
            html.append("</li>");
        }
        html.append("</ul>");

        String coverImageUrl = rooms.stream()
                .flatMap(room -> room.getImages().stream())
                .findFirst()
                .orElse(null);

        return new GeneratedDraftResponse(property.getName() + " - Cho thuê phòng trọ", html.toString(), coverImageUrl);
    }

    @Transactional(readOnly = true)
    public AdminPostDetailResponse getForAdmin(UUID propertyId) {
        Post post = postRepository.findByPropertyId(propertyId)
                .orElseThrow(() -> new ResourceNotFoundException("Post for property", propertyId));
        return AdminPostDetailResponse.from(post);
    }

    @Transactional
    public AdminPostDetailResponse upsertPost(UUID propertyId, UpdatePostRequest req, UUID authorId) {
        Property property = propertyService.getById(propertyId);
        Post post = postRepository.findByPropertyId(propertyId).orElseGet(() -> {
            Post created = new Post();
            created.setProperty(property);
            return created;
        });
        User author = userRepository.findById(authorId)
                .orElseThrow(() -> new ResourceNotFoundException("User", authorId));

        post.setTitle(req.getTitle());
        post.setContent(req.getContent());
        post.setCoverImageUrl(req.getCoverImageUrl() != null ? req.getCoverImageUrl() : resolveDefaultCoverImage(propertyId));
        post.setAuthor(author);

        String desiredSlug = req.getSlug() != null && !req.getSlug().isBlank()
                ? slugify(req.getSlug())
                : slugify(req.getTitle());
        post.setSlug(uniqueSlug(desiredSlug, post.getId()));

        return AdminPostDetailResponse.from(postRepository.save(post));
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

    private String resolveDefaultCoverImage(UUID propertyId) {
        return roomRepository.findByPropertyId(propertyId).stream()
                .flatMap(room -> room.getImages().stream())
                .findFirst()
                .orElse(null);
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
