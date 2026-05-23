package chez1s.htrbackend.security;

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

    @Test
    void authenticatesUsingValidAccessTokenWhenEarlierDuplicateCookieIsInvalid() throws Exception {
        JwtTokenProvider tokenProvider = mock(JwtTokenProvider.class);
        JwtAuthFilter filter = new JwtAuthFilter(tokenProvider);
        UUID userId = UUID.randomUUID();

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
}
