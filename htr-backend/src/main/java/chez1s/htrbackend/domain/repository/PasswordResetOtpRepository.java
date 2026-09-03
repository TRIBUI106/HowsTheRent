package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.PasswordResetOtp;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PasswordResetOtpRepository extends JpaRepository<PasswordResetOtp, java.util.UUID> {
    Optional<PasswordResetOtp> findByEmail(String email);

    void deleteByEmail(String email);
}
