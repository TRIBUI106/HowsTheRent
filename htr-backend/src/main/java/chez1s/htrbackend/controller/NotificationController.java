package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.response.NotificationResponse;
import chez1s.htrbackend.dto.response.PageResponse;
import chez1s.htrbackend.security.JwtTokenProvider;
import chez1s.htrbackend.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;
    private final JwtTokenProvider jwtTokenProvider;

    @GetMapping
    public ResponseEntity<PageResponse<NotificationResponse>> list(
            @RequestHeader("Authorization") String authHeader,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        UUID userId = jwtTokenProvider.getUserId(authHeader.replace("Bearer ", ""));
        return ResponseEntity.ok(notificationService.listByUser(userId, pageable));
    }

    @PostMapping("/{id}/read")
    public ResponseEntity<Map<String, String>> markAsRead(@PathVariable UUID id) {
        notificationService.markAsRead(id);
        return ResponseEntity.ok(Map.of("message", "Marked as read"));
    }

    @PostMapping("/read-all")
    public ResponseEntity<Map<String, String>> markAllAsRead(@RequestHeader("Authorization") String authHeader) {
        UUID userId = jwtTokenProvider.getUserId(authHeader.replace("Bearer ", ""));
        notificationService.markAllAsRead(userId);
        return ResponseEntity.ok(Map.of("message", "All marked as read"));
    }
}
