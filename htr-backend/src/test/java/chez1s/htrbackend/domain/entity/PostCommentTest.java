package chez1s.htrbackend.domain.entity;

import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class PostCommentTest {

    @Test
    void builderLinksCommentToPostAndAuthor() {
        Post post = Post.builder().id(UUID.randomUUID()).build();
        User user = User.builder().id(UUID.randomUUID()).fullName("Khách A").build();

        PostComment comment = PostComment.builder()
                .post(post)
                .user(user)
                .content("Phòng đẹp quá!")
                .build();

        assertThat(comment.getPost()).isSameAs(post);
        assertThat(comment.getUser()).isSameAs(user);
        assertThat(comment.getContent()).isEqualTo("Phòng đẹp quá!");
    }
}
