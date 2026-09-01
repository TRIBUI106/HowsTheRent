package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Post;
import chez1s.htrbackend.domain.repository.PostRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PostCronServiceTest {

    @Mock PostRepository postRepository;

    @InjectMocks PostCronService postCronService;

    @Test
    void publishScheduledPostsPublishesAllDuePosts() {
        UUID postId = UUID.randomUUID();
        LocalDateTime publishAt = LocalDateTime.now().minusMinutes(5);
        Post post = Post.builder().id(postId).slug("phong-tro-dep").published(false).publishAt(publishAt).build();
        when(postRepository.findByPublishedFalseAndPublishAtLessThanEqual(any(LocalDateTime.class)))
                .thenReturn(List.of(post));
        when(postRepository.save(any(Post.class))).thenAnswer(inv -> inv.getArgument(0));

        postCronService.publishScheduledPosts();

        ArgumentCaptor<Post> captor = ArgumentCaptor.forClass(Post.class);
        Mockito.verify(postRepository).save(captor.capture());
        assertThat(captor.getValue().isPublished()).isTrue();
        assertThat(captor.getValue().getPublishedAt()).isNotNull();
    }

    @Test
    void publishScheduledPostsDoesNothingWhenNoneAreDue() {
        when(postRepository.findByPublishedFalseAndPublishAtLessThanEqual(any(LocalDateTime.class)))
                .thenReturn(List.of());

        postCronService.publishScheduledPosts();

        Mockito.verify(postRepository, Mockito.never()).save(any(Post.class));
    }
}
