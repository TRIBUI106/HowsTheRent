package chez1s.htrbackend.domain.entity;

import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class PostTest {

    @Test
    void builderProducesAnUnpublishedDraftByDefault() {
        Property property = Property.builder().id(UUID.randomUUID()).build();
        Room room = Room.builder().id(UUID.randomUUID()).roomNumber("A1").property(property).build();

        Post post = Post.builder()
                .room(room)
                .title("Nhà trọ Xanh")
                .slug("nha-tro-xanh")
                .content("<p>Xin chào</p>")
                .build();

        assertThat(post.isPublished()).isFalse();
        assertThat(post.getPublishedAt()).isNull();
        assertThat(post.getRoom()).isSameAs(room);
    }
}
