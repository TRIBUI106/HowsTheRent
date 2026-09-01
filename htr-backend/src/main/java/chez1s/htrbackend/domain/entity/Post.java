package chez1s.htrbackend.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "posts")
public class Post extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(nullable = false, unique = true, length = 220)
    private String slug;

    @Column(columnDefinition = "TEXT")
    private String content;

    @Column(name = "cover_image_url")
    private String coverImageUrl;

    @Column(nullable = false)
    @Builder.Default
    private boolean published = false;

    @Column(name = "published_at")
    private LocalDateTime publishedAt;

    @Column(name = "publish_at")
    private LocalDateTime publishAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id")
    private User author;

    @ElementCollection
    @CollectionTable(name = "post_tags", joinColumns = @JoinColumn(name = "post_id"))
    @Column(name = "tag")
    @Builder.Default
    private List<String> tags = new ArrayList<>();

    /**
     * The cover image actually shown for this post: an explicitly-set
     * {@link #coverImageUrl} wins, otherwise it falls back to the room's
     * current first image. Unlike {@link #coverImageUrl}, this is never
     * persisted, so it stays in sync when the room's photos change after
     * the post was created — the stale-snapshot bug this replaces.
     */
    public String getEffectiveCoverImageUrl() {
        return coverImageUrl != null ? coverImageUrl : room.getImages().stream().findFirst().orElse(null);
    }
}
