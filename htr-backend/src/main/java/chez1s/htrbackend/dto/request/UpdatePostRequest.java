package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class UpdatePostRequest {

    @NotBlank
    private String title;

    /** Nullable — auto-generated (slugified) from the title when blank. Editable afterward. */
    private String slug;

    private String content;

    private String coverImageUrl;

    /** Nullable — when set, the post auto-publishes at this time instead of staying a draft. */
    private LocalDateTime publishAt;
}
