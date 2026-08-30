package chez1s.htrbackend.domain.entity;

import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class PostLikeTest {

    @Test
    void builderLinksLikeToPostAndUser() {
        Post post = Post.builder().id(UUID.randomUUID()).build();
        User user = User.builder().id(UUID.randomUUID()).build();

        PostLike like = PostLike.builder()
                .post(post)
                .user(user)
                .build();

        assertThat(like.getPost()).isSameAs(post);
        assertThat(like.getUser()).isSameAs(user);
    }
}
