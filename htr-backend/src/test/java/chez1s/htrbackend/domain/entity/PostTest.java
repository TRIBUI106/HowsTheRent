package chez1s.htrbackend.domain.entity;

import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
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

    @Test
    void effectiveCoverImageUrlPrefersExplicitlySetValueOverRoomImages() {
        Property property = Property.builder().id(UUID.randomUUID()).build();
        Room room = Room.builder().id(UUID.randomUUID()).roomNumber("A1").property(property)
                .images(new ArrayList<>(List.of("http://img/room-1.jpg"))).build();
        Post post = Post.builder().room(room).title("T").slug("t")
                .coverImageUrl("http://img/explicit-cover.jpg").build();

        assertThat(post.getEffectiveCoverImageUrl()).isEqualTo("http://img/explicit-cover.jpg");
    }

    @Test
    void effectiveCoverImageUrlFallsBackToRoomsCurrentFirstImageWhenNotExplicitlySet() {
        Property property = Property.builder().id(UUID.randomUUID()).build();
        Room room = Room.builder().id(UUID.randomUUID()).roomNumber("A1").property(property)
                .images(new ArrayList<>(List.of("http://img/room-current.jpg"))).build();
        Post post = Post.builder().room(room).title("T").slug("t").build();

        assertThat(post.getEffectiveCoverImageUrl()).isEqualTo("http://img/room-current.jpg");
    }

    @Test
    void effectiveCoverImageUrlIsNullWhenNeitherExplicitNorRoomImageExists() {
        Property property = Property.builder().id(UUID.randomUUID()).build();
        Room room = Room.builder().id(UUID.randomUUID()).roomNumber("A1").property(property).build();
        Post post = Post.builder().room(room).title("T").slug("t").build();

        assertThat(post.getEffectiveCoverImageUrl()).isNull();
    }

    @Test
    void effectiveCoverImageUrlReflectsRoomImageChangesSinceItIsNeverSnapshotted() {
        Property property = Property.builder().id(UUID.randomUUID()).build();
        Room room = Room.builder().id(UUID.randomUUID()).roomNumber("A1").property(property)
                .images(new ArrayList<>(List.of("http://img/old.jpg"))).build();
        Post post = Post.builder().room(room).title("T").slug("t").build();

        assertThat(post.getEffectiveCoverImageUrl()).isEqualTo("http://img/old.jpg");

        room.getImages().clear();
        room.getImages().add("http://img/new.jpg");

        assertThat(post.getEffectiveCoverImageUrl()).isEqualTo("http://img/new.jpg");
    }
}
