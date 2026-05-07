package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Notification;
import chez1s.htrbackend.security.JwtTokenProvider;
import chez1s.htrbackend.service.NotificationService;
import lombok.RequiredArgsConstructor;
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
    public ResponseEntity<List<Notification>> list(@RequestHeader("Authorization") String authHeader) {
        UUID userId = jwtTokenProvider.getUserId(authHeader.replace("Bearer ", ""));
        return ResponseEntity.ok(notificationService.listByUser(userId));
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
