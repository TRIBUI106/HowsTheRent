package chez1s.htrbackend.controller;

import chez1s.htrbackend.config.SecurityConfig;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.domain.repository.PostRepository;
import chez1s.htrbackend.domain.repository.RoomRepository;
import chez1s.htrbackend.domain.repository.UserRepository;
import chez1s.htrbackend.dto.response.AdminPostSummaryResponse;
import chez1s.htrbackend.security.JwtAuthFilter;
import chez1s.htrbackend.security.JwtTokenProvider;
import chez1s.htrbackend.service.AuditService;
import chez1s.htrbackend.service.PostService;
import chez1s.htrbackend.service.PropertyService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.cors.CorsConfigurationSource;

import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Exercises the REAL Spring Security filter chain (SecurityConfig + JwtAuthFilter)
 * for the public/admin blog endpoints, rather than instantiating controllers
 * directly (every other controller test in this feature does that, which is
 * exactly how the /sitemap.xml 401 bug slipped through review — no test ever
 * asked Spring Security what it would actually do with these requests).
 */
@WebMvcTest(controllers = {
        PublicBlogController.class,
        AdminBlogController.class,
        SitemapController.class,
        PublicPropertyController.class,
})
@Import({SecurityConfig.class, JwtAuthFilter.class})
class PublicAndAdminBlogSecurityBoundaryTest {

    @Autowired MockMvc mockMvc;

    @MockitoBean PostService postService;
    @MockitoBean PostRepository postRepository;
    @MockitoBean PropertyService propertyService;
    @MockitoBean RoomRepository roomRepository;
    @MockitoBean JwtTokenProvider tokenProvider;
    @MockitoBean UserRepository userRepository;
    @MockitoBean CorsConfigurationSource corsConfigurationSource;
    @MockitoBean AuditService auditService;

    private static Authentication authenticatedAs(UserRole role) {
        return new UsernamePasswordAuthenticationToken(
                UUID.randomUUID(), null, List.of(new SimpleGrantedAuthority("ROLE_" + role.name())));
    }

    // --- Public GET endpoints: reachable with no authentication at all ---

    @Test
    void publicBlogListIsReachableAnonymously() throws Exception {
        when(postService.listPublished()).thenReturn(List.of());

        mockMvc.perform(get("/api/public/blog/posts"))
                .andExpect(status().isOk());
    }

    @Test
    void sitemapIsReachableAnonymously() throws Exception {
        when(postRepository.findByPublishedTrueOrderByPublishedAtDesc()).thenReturn(List.of());

        // Regression guard for the exact bug the final whole-branch review found:
        // /sitemap.xml is mapped outside /api/**, so it needs its own permitAll
        // rule in SecurityConfig — this test fails loudly if that rule is ever
        // removed again.
        mockMvc.perform(get("/sitemap.xml"))
                .andExpect(status().isOk());
    }

    @Test
    void publicVacancyIsReachableAnonymously() throws Exception {
        UUID propertyId = UUID.randomUUID();
        when(roomRepository.countByPropertyIdAndStatus(any(), any())).thenReturn(0L);

        mockMvc.perform(get("/api/public/properties/{id}/vacancy", propertyId))
                .andExpect(status().isOk());
    }

    // --- Write endpoints under /api/public/blog/...: require authentication ---

    @Test
    void addCommentIsRejectedAnonymously() throws Exception {
        mockMvc.perform(post("/api/public/blog/posts/some-slug/comments")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"Hay quá\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void addCommentIsAllowedForAnyAuthenticatedRoleIncludingGuest() throws Exception {
        when(postService.addComment(any(), any(), any())).thenReturn(
                new chez1s.htrbackend.dto.response.PostCommentResponse(UUID.randomUUID(), "Hay quá", UUID.randomUUID(), "Khách A", null));

        mockMvc.perform(post("/api/public/blog/posts/some-slug/comments")
                        .with(authentication(authenticatedAs(UserRole.GUEST)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"Hay quá\"}"))
                .andExpect(status().isCreated());
    }

    @Test
    void likeIsRejectedAnonymously() throws Exception {
        mockMvc.perform(post("/api/public/blog/posts/some-slug/like"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void unlikeIsRejectedAnonymously() throws Exception {
        mockMvc.perform(delete("/api/public/blog/posts/some-slug/like"))
                .andExpect(status().isUnauthorized());
    }

    // --- Admin endpoints: require ADMIN/PLATFORM_ADMIN, exclude everyone else ---

    @Test
    void adminBlogListIsRejectedAnonymously() throws Exception {
        mockMvc.perform(get("/api/admin/blog/posts"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void adminBlogListIsRejectedForTenant() throws Exception {
        mockMvc.perform(get("/api/admin/blog/posts").with(authentication(authenticatedAs(UserRole.TENANT))))
                .andExpect(status().isForbidden());
    }

    @Test
    void adminBlogListIsRejectedForLandlordAdmin() throws Exception {
        // The spec deliberately scopes blog admin to ADMIN/PLATFORM_ADMIN only,
        // excluding LANDLORD_ADMIN even though LANDLORD_ADMIN can manage
        // properties/rooms elsewhere in the app.
        mockMvc.perform(get("/api/admin/blog/posts").with(authentication(authenticatedAs(UserRole.LANDLORD_ADMIN))))
                .andExpect(status().isForbidden());
    }

    @Test
    void adminBlogListIsAllowedForAdmin() throws Exception {
        when(postService.listAllForAdmin()).thenReturn(List.of());

        mockMvc.perform(get("/api/admin/blog/posts").with(authentication(authenticatedAs(UserRole.ADMIN))))
                .andExpect(status().isOk());
    }

    @Test
    void adminBlogListIsAllowedForPlatformAdmin() throws Exception {
        when(postService.listAllForAdmin()).thenReturn(List.<AdminPostSummaryResponse>of());

        mockMvc.perform(get("/api/admin/blog/posts").with(authentication(authenticatedAs(UserRole.PLATFORM_ADMIN))))
                .andExpect(status().isOk());
    }
}
