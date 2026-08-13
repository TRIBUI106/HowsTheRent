package chez1s.htrbackend.security;

import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.domain.repository.UserRepository;

import jakarta.servlet.FilterChain;
import jakarta.servlet.http.Cookie;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class JwtAuthFilterTest {

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    private JwtAuthFilter filter(JwtTokenProvider tokenProvider, UUID userId, UserRole role) {
        UserRepository userRepository = mock(UserRepository.class);
        User user = User.builder().id(userId).role(role).active(true).authVersion(0).build();
        when(userRepository.findById(userId)).thenReturn(java.util.Optional.of(user));
        return new JwtAuthFilter(tokenProvider, userRepository);
    }

    @Test
    void authenticatesUsingValidAccessTokenWhenEarlierDuplicateCookieIsInvalid() throws Exception {
        JwtTokenProvider tokenProvider = mock(JwtTokenProvider.class);
        UUID userId = UUID.randomUUID();
        JwtAuthFilter filter = filter(tokenProvider, userId, UserRole.ADMIN);

        when(tokenProvider.validateToken("old-token")).thenReturn(false);
        when(tokenProvider.validateToken("new-token")).thenReturn(true);
        when(tokenProvider.getUserId("new-token")).thenReturn(userId);
        when(tokenProvider.getRole("new-token")).thenReturn("ADMIN");

        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setCookies(new Cookie("accessToken", "old-token"), new Cookie("accessToken", "new-token"));
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = (_request, _response) -> { };

        filter.doFilter(request, response, chain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNotNull();
        assertThat(SecurityContextHolder.getContext().getAuthentication().getPrincipal()).isEqualTo(userId);
    }

    @Test
    void authenticatesTenantFromRootAccessTokenWhenStaleMaintenanceCookieArrivesFirst() throws Exception {
        JwtTokenProvider tokenProvider = mock(JwtTokenProvider.class);
        UUID tenantId = UUID.randomUUID();
        JwtAuthFilter filter = filter(tokenProvider, tenantId, UserRole.TENANT);

        when(tokenProvider.validateToken("stale-maintenance-token")).thenReturn(false);
        when(tokenProvider.validateToken("current-root-token")).thenReturn(true);
        when(tokenProvider.getUserId("current-root-token")).thenReturn(tenantId);
        when(tokenProvider.getRole("current-root-token")).thenReturn("TENANT");

        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/maintenance/mine");
        request.setCookies(
                new Cookie("accessToken", "stale-maintenance-token"),
                new Cookie("accessToken", "current-root-token")
        );
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = (_request, _response) -> { };

        filter.doFilter(request, response, chain);

        var auth = SecurityContextHolder.getContext().getAuthentication();
        assertThat(auth).isNotNull();
        assertThat(auth.getPrincipal()).isEqualTo(tenantId);
        assertThat(auth.getAuthorities())
                .extracting("authority")
                .containsExactly("ROLE_TENANT");
    }

    @Test
    void authenticatesUsingLegacyCapitalizedAccessTokenCookie() throws Exception {
        JwtTokenProvider tokenProvider = mock(JwtTokenProvider.class);
        UUID technicianId = UUID.randomUUID();
        JwtAuthFilter filter = filter(tokenProvider, technicianId, UserRole.TECHNICIAN);

        when(tokenProvider.validateToken("legacy-capitalized-token")).thenReturn(true);
        when(tokenProvider.getUserId("legacy-capitalized-token")).thenReturn(technicianId);
        when(tokenProvider.getRole("legacy-capitalized-token")).thenReturn("TECHNICIAN");

        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/notes");
        request.setCookies(new Cookie("AccessToken", "legacy-capitalized-token"));
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = (_request, _response) -> { };

        filter.doFilter(request, response, chain);

        var auth = SecurityContextHolder.getContext().getAuthentication();
        assertThat(auth).isNotNull();
        assertThat(auth.getPrincipal()).isEqualTo(technicianId);
        assertThat(auth.getAuthorities())
                .extracting("authority")
                .containsExactly("ROLE_TECHNICIAN");
    }

    @Test
    void prefersCanonicalAccessTokenOverLegacyCapitalizedCookie() throws Exception {
        JwtTokenProvider tokenProvider = mock(JwtTokenProvider.class);
        UUID legacyTenantId = UUID.randomUUID();
        UUID currentTechnicianId = UUID.randomUUID();
        JwtAuthFilter filter = filter(tokenProvider, currentTechnicianId, UserRole.TECHNICIAN);

        when(tokenProvider.validateToken("legacy-tenant-token")).thenReturn(true);
        when(tokenProvider.validateToken("current-technician-token")).thenReturn(true);
        when(tokenProvider.getUserId("legacy-tenant-token")).thenReturn(legacyTenantId);
        when(tokenProvider.getRole("legacy-tenant-token")).thenReturn("TENANT");
        when(tokenProvider.getUserId("current-technician-token")).thenReturn(currentTechnicianId);
        when(tokenProvider.getRole("current-technician-token")).thenReturn("TECHNICIAN");

        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/api/maintenance/8721cde2-53f1-478e-842d-63cef0d8e17a/notes");
        request.setCookies(
                new Cookie("AccessToken", "legacy-tenant-token"),
                new Cookie("accessToken", "current-technician-token")
        );
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = (_request, _response) -> { };

        filter.doFilter(request, response, chain);

        var auth = SecurityContextHolder.getContext().getAuthentication();
        assertThat(auth).isNotNull();
        assertThat(auth.getPrincipal()).isEqualTo(currentTechnicianId);
        assertThat(auth.getAuthorities())
                .extracting("authority")
                .containsExactly("ROLE_TECHNICIAN");
    }

    @Test
    void storesActorContextWhilePreservingUuidPrincipal() throws Exception {
        JwtTokenProvider tokenProvider = mock(JwtTokenProvider.class);
        UUID userId = UUID.randomUUID();
        JwtAuthFilter filter = filter(tokenProvider, userId, UserRole.LANDLORD_ADMIN);

        when(tokenProvider.validateToken("token")).thenReturn(true);
        when(tokenProvider.getUserId("token")).thenReturn(userId);
        when(tokenProvider.getRole("token")).thenReturn("LANDLORD_ADMIN");

        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setCookies(new Cookie("accessToken", "token"));
        filter.doFilter(request, new MockHttpServletResponse(), (_request, _response) -> { });

        var auth = SecurityContextHolder.getContext().getAuthentication();
        assertThat(auth.getPrincipal()).isEqualTo(userId);
        assertThat(auth.getDetails()).isEqualTo(new ActorContext(userId, UserRole.LANDLORD_ADMIN, 0));
    }

    @Test
    void rejectsInactivePersistedUser() throws Exception {
        assertPersistedUserMismatchIsRejected(false, UserRole.ADMIN, 0, "ADMIN", 0);
    }

    @Test
    void rejectsPersistedRoleMismatch() throws Exception {
        assertPersistedUserMismatchIsRejected(true, UserRole.LANDLORD_ADMIN, 0, "PLATFORM_ADMIN", 0);
    }

    @Test
    void rejectsPersistedAuthVersionMismatch() throws Exception {
        assertPersistedUserMismatchIsRejected(true, UserRole.PLATFORM_ADMIN, 2, "PLATFORM_ADMIN", 1);
    }

    private void assertPersistedUserMismatchIsRejected(
            boolean active,
            UserRole persistedRole,
            long persistedVersion,
            String tokenRole,
            long tokenVersion
    ) throws Exception {
        JwtTokenProvider tokenProvider = mock(JwtTokenProvider.class);
        UserRepository userRepository = mock(UserRepository.class);
        UUID userId = UUID.randomUUID();
        User user = User.builder()
                .id(userId)
                .role(persistedRole)
                .active(active)
                .authVersion(persistedVersion)
                .build();
        when(userRepository.findById(userId)).thenReturn(java.util.Optional.of(user));
        when(tokenProvider.validateToken("token")).thenReturn(true);
        when(tokenProvider.getUserId("token")).thenReturn(userId);
        when(tokenProvider.getRole("token")).thenReturn(tokenRole);
        when(tokenProvider.getAuthVersion("token")).thenReturn(tokenVersion);

        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setCookies(new Cookie("accessToken", "token"));
        new JwtAuthFilter(tokenProvider, userRepository)
                .doFilter(request, new MockHttpServletResponse(), (_request, _response) -> { });

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
    }
}
