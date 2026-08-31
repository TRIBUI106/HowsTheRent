package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Post;
import chez1s.htrbackend.domain.repository.PostRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SitemapControllerTest {

    @Mock PostRepository postRepository;

    private SitemapController controller;

    @BeforeEach
    void setup() {
        controller = new SitemapController(postRepository);
        ReflectionTestUtils.setField(controller, "publicBaseUrl", "https://example.com");
    }

    @Test
    void sitemapListsOnlyPublishedPostUrls() {
        Post post = Post.builder().slug("phong-tro-dep").build();
        when(postRepository.findByPublishedTrueOrderByPublishedAtDesc()).thenReturn(List.of(post));

        String xml = controller.sitemap();

        assertThat(xml).contains("<loc>https://example.com/blog/phong-tro-dep</loc>");
        assertThat(xml).startsWith("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
    }
}
