package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.repository.UserRepository;
import chez1s.htrbackend.dto.request.LoginRequest;
import chez1s.htrbackend.dto.request.RefreshRequest;
import chez1s.htrbackend.dto.response.AuthResponse;
import chez1s.htrbackend.dto.response.UserResponse;
import chez1s.htrbackend.exception.BusinessException;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import chez1s.htrbackend.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
@RequiredArgsConstructor
public class AuthService {

    private static final Duration PASSWORD_RESET_OTP_TTL = Duration.ofMinutes(15);
    private static final SecureRandom OTP_RANDOM = new SecureRandom();
    private static final Map<String, OtpEntry> PASSWORD_RESET_OTPS = new ConcurrentHashMap<>();

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final EmailService emailService;

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BusinessException("Invalid email or password"));
        if (!user.isActive()) {
            throw new BusinessException("Account is deactivated");
        }
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new BusinessException("Invalid email or password");
        }
        String accessToken = tokenProvider.generateAccessToken(user.getId(), user.getEmail(), user.getRole().name());
        String refreshToken = tokenProvider.generateRefreshToken(user.getId(), user.getEmail(), user.getRole().name());
        return new AuthResponse(accessToken, refreshToken, UserResponse.from(user));
    }

    public AuthResponse refresh(RefreshRequest request) {
        if (!tokenProvider.validateToken(request.getRefreshToken())) {
            throw new BusinessException("Invalid or expired refresh token");
        }
        var userId = tokenProvider.getUserId(request.getRefreshToken());
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("User not found"));
        String accessToken = tokenProvider.generateAccessToken(user.getId(), user.getEmail(), user.getRole().name());
        String refreshToken = tokenProvider.generateRefreshToken(user.getId(), user.getEmail(), user.getRole().name());
        return new AuthResponse(accessToken, refreshToken, UserResponse.from(user));
    }

    public void forgotPassword(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Email không tồn tại"));

        String otp = String.format("%06d", OTP_RANDOM.nextInt(1_000_000));
        PASSWORD_RESET_OTPS.put(normalizeEmail(email), new OtpEntry(otp, Instant.now().plus(PASSWORD_RESET_OTP_TTL)));

        emailService.sendPasswordResetOtp(user.getFullName(), email, otp);
    }

    public void resetPassword(String email, String otp, String newPassword) {
        String key = normalizeEmail(email);
        OtpEntry stored = PASSWORD_RESET_OTPS.get(key);

        if (stored == null || stored.expiresAt().isBefore(Instant.now()) || !stored.otp().equals(otp)) {
            PASSWORD_RESET_OTPS.remove(key);
            throw new BusinessException("OTP không hợp lệ hoặc đã hết hạn");
        }

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Email không tồn tại"));

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);
        PASSWORD_RESET_OTPS.remove(key);
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private record OtpEntry(String otp, Instant expiresAt) {
    }
}
