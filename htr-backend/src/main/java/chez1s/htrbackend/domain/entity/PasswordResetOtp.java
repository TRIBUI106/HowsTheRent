package chez1s.htrbackend.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "password_reset_otps", uniqueConstraints = @UniqueConstraint(columnNames = "email"))
public class PasswordResetOtp extends BaseEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String email;

    // Hashed the same way as User.passwordHash (via the shared PasswordEncoder bean) rather than
    // stored in plaintext, even though a 6-digit OTP is short-lived and single-use.
    @Column(name = "otp_hash", nullable = false)
    private String otpHash;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;
}
