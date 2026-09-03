package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.PasswordResetOtp;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.domain.repository.PasswordResetOtpRepository;
import chez1s.htrbackend.domain.repository.UserRepository;
import chez1s.htrbackend.exception.BusinessException;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import chez1s.htrbackend.security.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

// Regression coverage for moving password-reset OTPs from an in-memory ConcurrentHashMap (wiped
// on every process restart -- including a Render free-tier instance spinning down after ~15
// minutes idle, or any redeploy) to Postgres via PasswordResetOtpRepository. Uses a REAL
// BCryptPasswordEncoder (not mocked) so the hash/verify round trip is genuinely exercised, the
// same way the entity's otpHash is actually checked in production.
@ExtendWith(MockitoExtension.class)
class AuthServiceOtpTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private PasswordResetOtpRepository passwordResetOtpRepository;
    @Mock
    private JwtTokenProvider tokenProvider;
    @Mock
    private EmailService emailService;

    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    private AuthService authService;

    @BeforeEach
    void setUp() {
        authService = new AuthService(userRepository, passwordResetOtpRepository, passwordEncoder, tokenProvider, emailService);
        ReflectionTestUtils.setField(authService, "otpTtlMinutes", 10L);
    }

    private User userWith(String email) {
        return User.builder().id(UUID.randomUUID()).email(email).fullName("Nguyen Van A")
                .passwordHash("old-hash").role(UserRole.TENANT).active(true).build();
    }

    @Test
    void forgotPassword_persistsHashedOtpAndSendsEmail() {
        User user = userWith("tenant@test.com");
        when(userRepository.findByEmail("tenant@test.com")).thenReturn(Optional.of(user));

        authService.forgotPassword("tenant@test.com");

        verify(passwordResetOtpRepository).deleteByEmail("tenant@test.com");
        ArgumentCaptor<PasswordResetOtp> captor = ArgumentCaptor.forClass(PasswordResetOtp.class);
        verify(passwordResetOtpRepository).save(captor.capture());
        PasswordResetOtp saved = captor.getValue();
        assertThat(saved.getEmail()).isEqualTo("tenant@test.com");
        assertThat(saved.getOtpHash()).isNotBlank();
        // The OTP itself is never persisted or logged in plaintext -- only its hash.
        assertThat(saved.getOtpHash()).doesNotContain("000000", "111111");
        assertThat(saved.getExpiresAt()).isAfter(LocalDateTime.now());

        verify(emailService).sendPasswordResetOtp(eq("Nguyen Van A"), eq("tenant@test.com"), anyString());
    }

    @Test
    void forgotPassword_missingEmail_throwsAndSendsNothing() {
        when(userRepository.findByEmail("missing@test.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.forgotPassword("missing@test.com"))
                .isInstanceOf(ResourceNotFoundException.class);

        verify(passwordResetOtpRepository, never()).save(any());
        verify(emailService, never()).sendPasswordResetOtp(anyString(), anyString(), anyString());
    }

    @Test
    void resetPassword_correctOtpWithinTtl_updatesPasswordAndDeletesOtp() {
        String rawOtp = "482913";
        PasswordResetOtp stored = PasswordResetOtp.builder()
                .email("tenant@test.com")
                .otpHash(passwordEncoder.encode(rawOtp))
                .expiresAt(LocalDateTime.now().plusMinutes(5))
                .build();
        when(passwordResetOtpRepository.findByEmail("tenant@test.com")).thenReturn(Optional.of(stored));
        User user = userWith("tenant@test.com");
        when(userRepository.findByEmail("tenant@test.com")).thenReturn(Optional.of(user));

        authService.resetPassword("tenant@test.com", rawOtp, "NewPass123!");

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(userCaptor.capture());
        assertThat(passwordEncoder.matches("NewPass123!", userCaptor.getValue().getPasswordHash())).isTrue();
        verify(passwordResetOtpRepository).deleteByEmail("tenant@test.com");
    }

    @Test
    void resetPassword_wrongOtp_throwsAndLeavesPasswordUnchanged() {
        PasswordResetOtp stored = PasswordResetOtp.builder()
                .email("tenant@test.com")
                .otpHash(passwordEncoder.encode("482913"))
                .expiresAt(LocalDateTime.now().plusMinutes(5))
                .build();
        when(passwordResetOtpRepository.findByEmail("tenant@test.com")).thenReturn(Optional.of(stored));

        assertThatThrownBy(() -> authService.resetPassword("tenant@test.com", "000000", "NewPass123!"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("không hợp lệ");

        verify(userRepository, never()).save(any());
        verify(passwordResetOtpRepository, never()).deleteByEmail(anyString());
    }

    // The concrete bug this whole change fixes: an OTP whose TTL genuinely hasn't elapsed, but
    // whose row no longer exists because the process restarted (previously: the in-memory map was
    // wiped). Simulated here directly via an expired stored row, since the repository swap is what
    // makes "stored == null" now mean "really doesn't exist" instead of "we lost it on restart".
    @Test
    void resetPassword_expiredOtp_throwsAndCleansUpRow() {
        PasswordResetOtp stored = PasswordResetOtp.builder()
                .email("tenant@test.com")
                .otpHash(passwordEncoder.encode("482913"))
                .expiresAt(LocalDateTime.now().minusMinutes(1))
                .build();
        when(passwordResetOtpRepository.findByEmail("tenant@test.com")).thenReturn(Optional.of(stored));

        assertThatThrownBy(() -> authService.resetPassword("tenant@test.com", "482913", "NewPass123!"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("hết hạn");

        verify(passwordResetOtpRepository).deleteByEmail("tenant@test.com");
        verify(userRepository, never()).save(any());
    }

    @Test
    void resetPassword_noOtpEverRequested_throwsBusinessException() {
        when(passwordResetOtpRepository.findByEmail("tenant@test.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.resetPassword("tenant@test.com", "482913", "NewPass123!"))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("không hợp lệ");

        verify(userRepository, never()).save(any());
    }

    // A second forgotPassword call for the same email must invalidate the first OTP -- same
    // single-active-OTP-per-email semantics the old map's put() gave for free.
    @Test
    void forgotPassword_calledTwice_deletesPriorOtpBeforeInsertingNewOne() {
        User user = userWith("tenant@test.com");
        when(userRepository.findByEmail("tenant@test.com")).thenReturn(Optional.of(user));

        authService.forgotPassword("tenant@test.com");
        authService.forgotPassword("tenant@test.com");

        verify(passwordResetOtpRepository, times(2)).deleteByEmail("tenant@test.com");
        verify(passwordResetOtpRepository, times(2)).save(any());
    }
}
