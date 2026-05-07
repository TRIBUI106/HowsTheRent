package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Notification;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.repository.NotificationRepository;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;

    public List<Notification> listByUser(UUID userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public void create(UUID userId, String title, String body, String type, UUID refId) {
        Notification n = Notification.builder()
                .user(User.builder().id(userId).build())
                .title(title)
                .body(body)
                .type(type)
                .refId(refId)
                .build();
        notificationRepository.save(n);
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
