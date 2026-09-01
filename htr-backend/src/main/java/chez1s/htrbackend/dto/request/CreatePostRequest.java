package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
public class CreatePostRequest {

    @NotNull
    private UUID roomId;

    @NotBlank
    private String title;

    /** Nullable — auto-generated (slugified) from the title when blank. */
    private String slug;

    private String content;

    private String coverImageUrl;

    /** Nullable — when set, the post auto-publishes at this time instead of staying a draft. */
    private LocalDateTime publishAt;
}
