package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Notification;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.repository.NotificationRepository;
import chez1s.htrbackend.dto.response.NotificationResponse;
import chez1s.htrbackend.dto.response.PageResponse;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final Map<UUID, CopyOnWriteArrayList<SseEmitter>> emitters = new ConcurrentHashMap<>();

    public SseEmitter subscribe(UUID userId) {
        SseEmitter emitter = new SseEmitter(0L);
        emitters.computeIfAbsent(userId, ignored -> new CopyOnWriteArrayList<>()).add(emitter);
        Runnable cleanup = () -> removeEmitter(userId, emitter);
        emitter.onCompletion(cleanup);
        emitter.onTimeout(cleanup);
        emitter.onError(ignored -> cleanup.run());
        try {
            emitter.send(SseEmitter.event().name("connected").data("ok"));
        } catch (IOException ex) {
            cleanup.run();
        }
        return emitter;
    }

    public List<Notification> listByUser(UUID userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public PageResponse<NotificationResponse> listByUser(UUID userId, Pageable pageable) {
        return PageResponse.from(notificationRepository.findByUserId(userId, pageable).map(NotificationResponse::from));
    }

    public void create(UUID userId, String title, String body, String type, UUID refId) {
        Notification n = Notification.builder()
                .user(User.builder().id(userId).build())
                .title(title)
                .body(body)
                .type(type)
                .refId(refId)
                .build();
        n = notificationRepository.save(n);
        publish(userId, NotificationResponse.from(n));
    }

    private void publish(UUID userId, NotificationResponse notification) {
        publishEvent(userId, "notification", notification);
    }

    public void publishEvent(UUID userId, String eventName, Object data) {
        if (userId == null) return;
        List<SseEmitter> userEmitters = emitters.getOrDefault(userId, new CopyOnWriteArrayList<>());
        for (SseEmitter emitter : userEmitters) {
            try {
                emitter.send(SseEmitter.event().name(eventName).data(data));
            } catch (IOException | IllegalStateException ex) {
                removeEmitter(userId, emitter);
            }
        }
    }

    private void removeEmitter(UUID userId, SseEmitter emitter) {
        List<SseEmitter> userEmitters = emitters.get(userId);
        if (userEmitters == null) return;
        userEmitters.remove(emitter);
        if (userEmitters.isEmpty()) emitters.remove(userId);
    }

    @Transactional
    public void markAsRead(UUID id) {
        Notification n = notificationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Notification", id));
        n.setRead(true);
        notificationRepository.save(n);
    }

    @Transactional
    public void markAllAsRead(UUID userId) {
        notificationRepository.markAllAsRead(userId);
    }
}
