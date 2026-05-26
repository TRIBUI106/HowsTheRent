package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.request.RoomNoteRequest;
import chez1s.htrbackend.dto.response.RoomNoteResponse;
import chez1s.htrbackend.dto.response.RoomTimelineResponse;
import chez1s.htrbackend.service.RoomTimelineService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/rooms/{roomId}")
@RequiredArgsConstructor
public class RoomTimelineController {

    private final RoomTimelineService roomTimelineService;

    @GetMapping("/timeline")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<RoomTimelineResponse>> getTimeline(@PathVariable UUID roomId) {
        return ResponseEntity.ok(roomTimelineService.getTimeline(roomId));
    }

    @PostMapping("/notes")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<RoomNoteResponse> addNote(@PathVariable UUID roomId,
                                                    @Valid @RequestBody RoomNoteRequest req,
                                                    Authentication auth) {
        UUID authorId = (UUID) auth.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(roomTimelineService.addNote(roomId, authorId, req.getContent()));
    }

    @DeleteMapping("/notes/{noteId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteNote(@PathVariable UUID roomId,
                                           @PathVariable UUID noteId) {
        roomTimelineService.deleteNote(noteId);
        return ResponseEntity.noContent().build();
    }
}
