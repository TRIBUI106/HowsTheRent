package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class RoomNoteRequest {
    @NotBlank
    private String content;
}
