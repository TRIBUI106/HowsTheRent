package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.request.ForgotPasswordRequest;
import chez1s.htrbackend.dto.request.LoginRequest;
import chez1s.htrbackend.dto.request.RefreshRequest;
import chez1s.htrbackend.dto.request.RegisterGuestRequest;
import chez1s.htrbackend.dto.request.ResetPasswordRequest;
import chez1s.htrbackend.dto.response.AuthResponse;
import chez1s.htrbackend.exception.BusinessException;
import chez1s.htrbackend.service.AuthService;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private static final String ACCESS_TOKEN_COOKIE = "accessToken";
    private static final String REFRESH_TOKEN_COOKIE = "refreshToken";
    private static final String ROOT_PATH = "/";
    private static final String REFRESH_TOKEN_PATH = "/api/auth/refresh";
    private static final long ACCESS_TOKEN_MAX_AGE_SECONDS = 30 * 60;
    private static final long REFRESH_TOKEN_MAX_AGE_SECONDS = 30L * 24 * 60 * 60;
    private static final List<String> LEGACY_ACCESS_TOKEN_PATHS = List.of(
            "/api",
            "/api/",
            "/api/maintenance",
            "/api/maintenance/"
    );
    private static final List<String> LEGACY_CAPITALIZED_ACCESS_TOKEN_PATHS = List.of(
            ROOT_PATH,
            "/api",
            "/api/",
            "/api/maintenance",
            "/api/maintenance/"
    );

    private final AuthService authService;

    @Value("${app.cookie.secure:false}")
    private boolean secureCookies;

    @Value("${app.cookie.same-site:Lax}")
    private String cookieSameSite;

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request, HttpServletResponse response) {
        AuthResponse auth = authService.login(request);
        setTokenCookies(response, auth.getAccessToken(), auth.getRefreshToken());
        return ResponseEntity.ok(new AuthResponse(null, null, auth.getUser()));
    }

    @PostMapping("/register-guest")
    public ResponseEntity<AuthResponse> registerGuest(@Valid @RequestBody RegisterGuestRequest request,
                                                       HttpServletResponse response) {
        AuthResponse authResponse = authService.registerGuest(request);
        setTokenCookies(response, authResponse.getAccessToken(), authResponse.getRefreshToken());
        return ResponseEntity.status(HttpStatus.CREATED).body(authResponse);
    }

    @PostMapping("/refresh")
    public ResponseEntity<Map<String, String>> refresh(
            @CookieValue(value = "refreshToken", required = false) String refreshToken,
            HttpServletResponse response) {
        if (refreshToken == null || refreshToken.isBlank()) {
            throw new BusinessException("Missing refresh token");
        }

        RefreshRequest request = new RefreshRequest();
        request.setRefreshToken(refreshToken);
        AuthResponse auth = authService.refresh(request);
        setTokenCookies(response, auth.getAccessToken(), auth.getRefreshToken());
        return ResponseEntity.ok(Map.of("message", "Token refreshed"));
    }

    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logout(HttpServletResponse response) {
        clearTokenCookies(response);
        return ResponseEntity.ok(Map.of("message", "Logged out successfully"));
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<Map<String, String>> forgotPassword(@Valid @RequestBody ForgotPasswordRequest req) {
        authService.forgotPassword(req.email());
        return ResponseEntity.ok(Map.of("message", "OTP đã được gửi về email của bạn"));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<Map<String, String>> resetPassword(@Valid @RequestBody ResetPasswordRequest req) {
        authService.resetPassword(req.email(), req.otp(), req.newPassword());
        return ResponseEntity.ok(Map.of("message", "Mật khẩu đã được cập nhật"));
    }

    private ResponseCookie buildCookie(String name, String value, long maxAgeSeconds, String path) {
        return ResponseCookie.from(name, value)
                .httpOnly(true)
                .secure(secureCookies)
                .sameSite(cookieSameSite)
                .path(path)
                .maxAge(maxAgeSeconds)
                .build();
    }

    private void setTokenCookies(HttpServletResponse response, String accessToken, String refreshToken) {
        clearLegacyAccessTokenCookies(response);
        response.addHeader(HttpHeaders.SET_COOKIE, buildCookie(ACCESS_TOKEN_COOKIE, accessToken, ACCESS_TOKEN_MAX_AGE_SECONDS, ROOT_PATH).toString());
        response.addHeader(HttpHeaders.SET_COOKIE, buildCookie(REFRESH_TOKEN_COOKIE, refreshToken, REFRESH_TOKEN_MAX_AGE_SECONDS, REFRESH_TOKEN_PATH).toString());
    }

    private void clearTokenCookies(HttpServletResponse response) {
        response.addHeader(HttpHeaders.SET_COOKIE, buildCookie(ACCESS_TOKEN_COOKIE, "", 0, ROOT_PATH).toString());
        clearLegacyAccessTokenCookies(response);
        response.addHeader(HttpHeaders.SET_COOKIE, buildCookie(REFRESH_TOKEN_COOKIE, "", 0, REFRESH_TOKEN_PATH).toString());
    }

    private void clearLegacyAccessTokenCookies(HttpServletResponse response) {
        for (String path : LEGACY_ACCESS_TOKEN_PATHS) {
            response.addHeader(HttpHeaders.SET_COOKIE, buildCookie(ACCESS_TOKEN_COOKIE, "", 0, path).toString());
        }
        for (String path : LEGACY_CAPITALIZED_ACCESS_TOKEN_PATHS) {
            response.addHeader(HttpHeaders.SET_COOKIE, buildCookie("AccessToken", "", 0, path).toString());
        }
    }
}
