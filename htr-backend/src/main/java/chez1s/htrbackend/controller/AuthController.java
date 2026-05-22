package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.request.ForgotPasswordRequest;
import chez1s.htrbackend.dto.request.LoginRequest;
import chez1s.htrbackend.dto.request.RefreshRequest;
import chez1s.htrbackend.dto.request.ResetPasswordRequest;
import chez1s.htrbackend.dto.response.AuthResponse;
import chez1s.htrbackend.exception.BusinessException;
import chez1s.htrbackend.service.AuthService;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request, HttpServletResponse response) {
        AuthResponse auth = authService.login(request);
        setTokenCookies(response, auth.getAccessToken(), auth.getRefreshToken());
        return ResponseEntity.ok(new AuthResponse(null, null, auth.getUser()));
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
                .secure(false)
                .sameSite("Lax")
                .path(path)
                .maxAge(maxAgeSeconds)
                .build();
    }

    private void setTokenCookies(HttpServletResponse response, String accessToken, String refreshToken) {
        response.addHeader(HttpHeaders.SET_COOKIE, buildCookie("accessToken", accessToken, 15 * 60, "/").toString());
        response.addHeader(HttpHeaders.SET_COOKIE, buildCookie("refreshToken", refreshToken, 7 * 24 * 60 * 60, "/api/auth/refresh").toString());
    }

    private void clearTokenCookies(HttpServletResponse response) {
        response.addHeader(HttpHeaders.SET_COOKIE, buildCookie("accessToken", "", 0, "/").toString());
        response.addHeader(HttpHeaders.SET_COOKIE, buildCookie("refreshToken", "", 0, "/api/auth/refresh").toString());
    }
}
