package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.PasswordResetOtp;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.domain.repository.PasswordResetOtpRepository;
import chez1s.htrbackend.domain.repository.UserRepository;
import chez1s.htrbackend.dto.request.LoginRequest;
import chez1s.htrbackend.dto.request.RefreshRequest;
import chez1s.htrbackend.dto.request.RegisterGuestRequest;
import chez1s.htrbackend.dto.response.AuthResponse;
import chez1s.htrbackend.dto.response.UserResponse;
import chez1s.htrbackend.exception.BusinessException;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import chez1s.htrbackend.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Locale;

@Service
@RequiredArgsConstructor
public class AuthService {

    private static final SecureRandom OTP_RANDOM = new SecureRandom();

    private final UserRepository userRepository;
    private final PasswordResetOtpRepository passwordResetOtpRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final EmailService emailService;

    @Value("${app.otp.ttl-minutes:10}")
    private long otpTtlMinutes;

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BusinessException("Invalid email or password"));
        if (!user.isActive()) {
            throw new BusinessException("Account is deactivated");
        }
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new BusinessException("Invalid email or password");
        }
        String accessToken = tokenProvider.generateAccessToken(user.getId(), user.getEmail(), user.getRole().name(), user.getAuthVersion());
        String refreshToken = tokenProvider.generateRefreshToken(user.getId(), user.getEmail(), user.getRole().name(), user.getAuthVersion());
        return new AuthResponse(accessToken, refreshToken, UserResponse.from(user));
    }

    public AuthResponse refresh(RefreshRequest request) {
        if (!tokenProvider.validateToken(request.getRefreshToken())) {
            throw new BusinessException("Invalid or expired refresh token");
        }
        var userId = tokenProvider.getUserId(request.getRefreshToken());
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException("User not found"));
        if (!user.isActive()
                || !user.getRole().name().equals(tokenProvider.getRole(request.getRefreshToken()))
                || user.getAuthVersion() != tokenProvider.getAuthVersion(request.getRefreshToken())) {
            throw new BusinessException("Invalid or expired refresh token");
        }
        String accessToken = tokenProvider.generateAccessToken(user.getId(), user.getEmail(), user.getRole().name(), user.getAuthVersion());
        String refreshToken = tokenProvider.generateRefreshToken(user.getId(), user.getEmail(), user.getRole().name(), user.getAuthVersion());
        return new AuthResponse(accessToken, refreshToken, UserResponse.from(user));
    }

    @Transactional
    public void forgotPassword(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Email không tồn tại"));

        String key = normalizeEmail(email);
        String otp = String.format("%06d", OTP_RANDOM.nextInt(1_000_000));
        // Only one active OTP per email at a time, same as the map's put() semantics it replaces —
        // requesting a new OTP invalidates any earlier one still outstanding for that address.
        passwordResetOtpRepository.deleteByEmail(key);
        passwordResetOtpRepository.save(PasswordResetOtp.builder()
                .email(key)
                .otpHash(passwordEncoder.encode(otp))
                .expiresAt(LocalDateTime.now().plusMinutes(otpTtlMinutes))
                .build());

        emailService.sendPasswordResetOtp(user.getFullName(), email, otp);
    }

    @Transactional
    public void resetPassword(String email, String otp, String newPassword) {
        String key = normalizeEmail(email);
        PasswordResetOtp stored = passwordResetOtpRepository.findByEmail(key).orElse(null);

        if (stored == null || stored.getExpiresAt().isBefore(LocalDateTime.now())) {
            passwordResetOtpRepository.deleteByEmail(key);
            throw new BusinessException("OTP không hợp lệ hoặc đã hết hạn");
        }
        if (!passwordEncoder.matches(otp, stored.getOtpHash())) {
            throw new BusinessException("OTP không hợp lệ hoặc đã hết hạn");
        }

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Email không tồn tại"));

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);
        passwordResetOtpRepository.deleteByEmail(key);
    }

    public AuthResponse registerGuest(RegisterGuestRequest request) {
        String email = normalizeEmail(request.getEmail());
        if (userRepository.existsByEmail(email)) {
            throw new BusinessException("Email đã được sử dụng");
        }
        User user = User.builder()
                .fullName(request.getFullName())
                .email(email)
                .phone(request.getPhone())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(UserRole.GUEST)
                .active(true)
                .build();
        user = userRepository.save(user);
        String accessToken = tokenProvider.generateAccessToken(user.getId(), user.getEmail(), user.getRole().name(), user.getAuthVersion());
        String refreshToken = tokenProvider.generateRefreshToken(user.getId(), user.getEmail(), user.getRole().name(), user.getAuthVersion());
        return new AuthResponse(accessToken, refreshToken, UserResponse.from(user));
    }

    public void changePassword(java.util.UUID userId, String currentPassword, String newPassword) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));
        if (!passwordEncoder.matches(currentPassword, user.getPasswordHash())) {
            throw new BusinessException("Mật khẩu hiện tại không đúng");
        }
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }
}
