package chez1s.htrbackend.service;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;

import java.security.SecureRandom;

/**
 * Manual, local-only smoke test for the real SMTP configuration in the repo-root {@code .env}
 * (MAIL_HOST/MAIL_PORT/MAIL_USERNAME/MAIL_PASSWORD) — sends one real password-reset-OTP email via
 * EmailService, exactly the code path AuthService.forgotPassword() uses, with a genuine random
 * 6-digit code.
 *
 * Deliberately named without a "Test"/"Tests"/"TestCase" suffix so Maven Surefire's default
 * inclusion pattern never picks this up during a normal `mvn test` or CI run — a live outbound
 * email send has no place in the regular automated suite (needs real credentials, hits Gmail's
 * network, not idempotent). Run it explicitly and only when actually verifying SMTP delivery:
 *
 *   ./mvnw -Dtest=ManualEmailSmtpCheck test
 *
 * Sends to the same address configured as MAIL_USERNAME (a self-test) — this class never reads or
 * prints that value itself; Spring resolves it at runtime from the real .env via the existing
 * spring.config.import mechanism, the same way EmailService's own `fromEmail` field does.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.NONE)
class ManualEmailSmtpCheck {

    @Autowired
    private EmailService emailService;

    @Value("${spring.mail.username}")
    private String selfEmail;

    @Test
    void sendsARealPasswordResetOtpEmail() throws InterruptedException {
        String otp = String.format("%06d", new SecureRandom().nextInt(1_000_000));

        emailService.sendPasswordResetOtp("SMTP Test", selfEmail, otp);

        // sendPasswordResetOtp is @Async — give the executor time to actually hit smtp.gmail.com
        // and either log "Email sent to ... subject: ..." or "Failed to send email to ...: ..."
        // (both from EmailService itself) before this test method — and the Spring context that
        // backs the @Async executor — exits.
        Thread.sleep(8000);
    }
}
