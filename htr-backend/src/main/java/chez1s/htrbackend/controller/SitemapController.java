package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Post;
import chez1s.htrbackend.domain.repository.PostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
public class SitemapController {

    private final PostRepository postRepository;

    @Value("${app.public-base-url:http://localhost:5173}")
    private String publicBaseUrl;

    @GetMapping(value = "/sitemap.xml", produces = MediaType.APPLICATION_XML_VALUE)
    @Transactional(readOnly = true)
    public String sitemap() {
        StringBuilder xml = new StringBuilder("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
        xml.append("<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">");
        for (Post post : postRepository.findByPublishedTrueOrderByPublishedAtDesc()) {
            xml.append("<url><loc>").append(publicBaseUrl).append("/blog/").append(post.getSlug()).append("</loc></url>");
        }
        xml.append("</urlset>");
        return xml.toString();
    }
}
