package chez1s.htrbackend.security;

import chez1s.htrbackend.domain.repository.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private static final String ACCESS_TOKEN_COOKIE = "accessToken";
    private static final String LEGACY_CAPITALIZED_ACCESS_TOKEN_COOKIE = "AccessToken";

    private final JwtTokenProvider tokenProvider;
    private final UserRepository userRepository;

    // Long-lived SSE connections (see NotificationController#stream) use an
    // infinite-timeout emitter. When a write to a dead client connection fails,
    // Spring/Tomcat re-enters the full filter chain via an ASYNC/ERROR dispatch
    // to resolve the error. OncePerRequestFilter skips re-running on those
    // dispatch types by default, so without this override the SecurityContext
    // is never re-populated on that redispatch and AuthorizationFilter denies
    // the request even though the original session/cookie was valid — surfacing
    // as "AuthorizationDeniedException ... response is already committed" in
    // logs. Re-authenticating from the request's own cookies/header on every
    // dispatch type fixes this at the source.
    @Override
    protected boolean shouldNotFilterAsyncDispatch() {
        return false;
    }

    @Override
    protected boolean shouldNotFilterErrorDispatch() {
        return false;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String token = extractValidTokenFromCookie(request);
        if (token == null) {
            token = extractFromHeader(request);
            if (token != null && !tokenProvider.validateToken(token)) {
                token = null;
            }
        }

        if (token != null) {
            UUID userId = tokenProvider.getUserId(token);
            String tokenRole = tokenProvider.getRole(token);
            long tokenAuthVersion = tokenProvider.getAuthVersion(token);
            userRepository.findById(userId)
                    .filter(user -> user.isActive()
                            && user.getRole().name().equals(tokenRole)
                            && user.getAuthVersion() == tokenAuthVersion)
                    .ifPresent(user -> {
                        ActorContext actor = new ActorContext(user.getId(), user.getRole(), user.getAuthVersion());
                        var auth = new UsernamePasswordAuthenticationToken(
                                user.getId(), null,
                                List.of(new SimpleGrantedAuthority("ROLE_" + user.getRole().name()))
                        );
                        auth.setDetails(actor);
                        SecurityContextHolder.getContext().setAuthentication(auth);
                    });
        }

        filterChain.doFilter(request, response);
    }

    private String extractValidTokenFromCookie(HttpServletRequest request) {
        Cookie[] cookies = request.getCookies();
        if (cookies == null) {
            return null;
        }

        for (Cookie cookie : cookies) {
            if (ACCESS_TOKEN_COOKIE.equals(cookie.getName()) && tokenProvider.validateToken(cookie.getValue())) {
                return cookie.getValue();
            }
        }

        for (Cookie cookie : cookies) {
            if (LEGACY_CAPITALIZED_ACCESS_TOKEN_COOKIE.equals(cookie.getName()) && tokenProvider.validateToken(cookie.getValue())) {
                return cookie.getValue();
            }
        }

        return null;
    }

    private String extractFromHeader(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            return header.substring(7);
        }
        return null;
    }
}
