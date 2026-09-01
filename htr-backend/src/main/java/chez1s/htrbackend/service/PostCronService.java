package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Post;
import chez1s.htrbackend.domain.repository.PostRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class PostCronService {

    private final PostRepository postRepository;

    @Scheduled(fixedDelay = 60000) // 1 minute
    @Transactional
    public void publishScheduledPosts() {
        LocalDateTime now = LocalDateTime.now();
        List<Post> duePosts = postRepository.findByPublishedFalseAndPublishAtLessThanEqual(now);

        for (Post post : duePosts) {
            log.info("Auto-publishing scheduled post {} (was due at {})", post.getSlug(), post.getPublishAt());
            post.setPublished(true);
            post.setPublishedAt(now);
            postRepository.save(post);
        }
    }
}
