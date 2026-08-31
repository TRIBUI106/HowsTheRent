package chez1s.htrbackend.domain.entity;

import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class PostTest {

    @Test
    void builderProducesAnUnpublishedDraftByDefault() {
        Property property = Property.builder().id(UUID.randomUUID()).build();

        Post post = Post.builder()
                .property(property)
                .title("Nhà trọ Xanh")
                .slug("nha-tro-xanh")
                .content("<p>Xin chào</p>")
                .build();

        assertThat(post.isPublished()).isFalse();
        assertThat(post.getPublishedAt()).isNull();
        assertThat(post.getProperty()).isSameAs(property);
    }
}
