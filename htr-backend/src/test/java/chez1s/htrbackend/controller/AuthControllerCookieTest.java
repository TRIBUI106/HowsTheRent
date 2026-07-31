package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.request.LoginRequest;
import chez1s.htrbackend.dto.request.RefreshRequest;
import chez1s.htrbackend.dto.response.AuthResponse;
import chez1s.htrbackend.dto.response.UserResponse;
import chez1s.htrbackend.service.AuthService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Collection;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class AuthControllerCookieTest {

    private static final String ACCESS_TOKEN = "new-access-token";
    private static final String REFRESH_TOKEN = "new-refresh-token";
    private static final String[] LEGACY_ACCESS_TOKEN_PATHS = {
            "/api",
            "/api/",
            "/api/maintenance",
            "/api/maintenance/"
    };
    private static final String[] LEGACY_CAPITALIZED_ACCESS_TOKEN_PATHS = {
            "/",
            "/api",
            "/api/",
            "/api/maintenance",
            "/api/maintenance/"
    };

    private AuthService authService;
    private AuthController controller;

    @BeforeEach
    void setup() {
        authService = mock(AuthService.class);
        controller = new AuthController(authService);
        ReflectionTestUtils.setField(controller, "secureCookies", true);
        ReflectionTestUtils.setField(controller, "cookieSameSite", "Lax");
    }

    @Test
    void loginExpiresLegacyAccessTokenCookiesAndSetsRootAccessToken() {
        when(authService.login(any(LoginRequest.class))).thenReturn(authResponse());
        MockHttpServletResponse response = new MockHttpServletResponse();

        controller.login(new LoginRequest(), response);

        Collection<String> cookies = response.getHeaders(HttpHeaders.SET_COOKIE);
        assertThat(cookies).anySatisfy(cookie -> assertActiveCookie(cookie, "accessToken", ACCESS_TOKEN, "/"));
        assertThat(cookies).anySatisfy(cookie -> assertActiveCookie(cookie, "refreshToken", REFRESH_TOKEN, "/api/auth/refresh"));
        assertLegacyAccessTokenCookiesExpired(cookies);
        assertLegacyCapitalizedAccessTokenCookiesExpired(cookies);
    }

    @Test
    void refreshExpiresLegacyAccessTokenCookiesAndSetsRootAccessToken() {
        when(authService.refresh(any(RefreshRequest.class))).thenReturn(authResponse());
        MockHttpServletResponse response = new MockHttpServletResponse();

        controller.refresh("old-refresh-token", response);

        Collection<String> cookies = response.getHeaders(HttpHeaders.SET_COOKIE);
        assertThat(cookies).anySatisfy(cookie -> assertActiveCookie(cookie, "accessToken", ACCESS_TOKEN, "/"));
        assertThat(cookies).anySatisfy(cookie -> assertActiveCookie(cookie, "refreshToken", REFRESH_TOKEN, "/api/auth/refresh"));
        assertLegacyAccessTokenCookiesExpired(cookies);
        assertLegacyCapitalizedAccessTokenCookiesExpired(cookies);
    }

    @Test
    void logoutExpiresRootAndLegacyAccessTokenCookies() {
        MockHttpServletResponse response = new MockHttpServletResponse();

        controller.logout(response);

        Collection<String> cookies = response.getHeaders(HttpHeaders.SET_COOKIE);
        assertThat(cookies).anySatisfy(cookie -> assertExpiredCookie(cookie, "accessToken", "/"));
        assertThat(cookies).anySatisfy(cookie -> assertExpiredCookie(cookie, "refreshToken", "/api/auth/refresh"));
        assertLegacyAccessTokenCookiesExpired(cookies);
        assertLegacyCapitalizedAccessTokenCookiesExpired(cookies);
    }

    private static AuthResponse authResponse() {
        UserResponse user = new UserResponse(
                UUID.randomUUID(),
                "Tenant User",
                "tenant@example.com",
                "0900000000",
                "TENANT",
                null,
                true
        );
        return new AuthResponse(ACCESS_TOKEN, REFRESH_TOKEN, user);
    }

    private static void assertLegacyAccessTokenCookiesExpired(Collection<String> cookies) {
        for (String path : LEGACY_ACCESS_TOKEN_PATHS) {
            assertThat(cookies).anySatisfy(cookie -> assertExpiredCookie(cookie, "accessToken", path));
        }
    }

    private static void assertLegacyCapitalizedAccessTokenCookiesExpired(Collection<String> cookies) {
        for (String path : LEGACY_CAPITALIZED_ACCESS_TOKEN_PATHS) {
            assertThat(cookies).anySatisfy(cookie -> assertExpiredCookie(cookie, "AccessToken", path));
        }
    }

    private static void assertActiveCookie(String cookie, String name, String value, String path) {
        assertThat(cookie).startsWith(name + "=" + value + ";");
        assertThat(cookie).contains("Path=" + path + ";");
        assertThat(cookie).contains("Max-Age=");
        assertThat(cookie).contains("Secure");
        assertThat(cookie).contains("HttpOnly");
        assertThat(cookie).contains("SameSite=Lax");
    }

    private static void assertExpiredCookie(String cookie, String name, String path) {
        assertThat(cookie).startsWith(name + "=;");
        assertThat(cookie).contains("Path=" + path + ";");
        assertThat(cookie).contains("Max-Age=0");
        assertThat(cookie).contains("Secure");
        assertThat(cookie).contains("HttpOnly");
        assertThat(cookie).contains("SameSite=Lax");
    }
}
