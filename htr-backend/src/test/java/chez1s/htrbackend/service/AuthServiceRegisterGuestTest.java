package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.domain.repository.UserRepository;
import chez1s.htrbackend.dto.request.RegisterGuestRequest;
import chez1s.htrbackend.dto.response.AuthResponse;
import chez1s.htrbackend.exception.BusinessException;
import chez1s.htrbackend.security.JwtTokenProvider;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceRegisterGuestTest {

    @Mock UserRepository userRepository;
    @Mock PasswordEncoder passwordEncoder;
    @Mock JwtTokenProvider tokenProvider;
    @Mock EmailService emailService;

    private AuthService authService() {
        return new AuthService(userRepository, passwordEncoder, tokenProvider, emailService);
    }

    @Test
    void createsAGuestUserAndReturnsTokens() {
        AuthService authService = authService();
        RegisterGuestRequest req = new RegisterGuestRequest();
        req.setFullName("Khách A");
        req.setEmail("guest@example.com");
        req.setPassword("Password1!");

        when(userRepository.existsByEmail("guest@example.com")).thenReturn(false);
        when(passwordEncoder.encode("Password1!")).thenReturn("hashed");
        when(userRepository.save(any(User.class))).thenAnswer(inv -> {
            User u = inv.getArgument(0);
            u.setId(java.util.UUID.randomUUID());
            return u;
        });
        when(tokenProvider.generateAccessToken(any(), any(), any(), anyLong())).thenReturn("access");
        when(tokenProvider.generateRefreshToken(any(), any(), any(), anyLong())).thenReturn("refresh");

        AuthResponse response = authService.registerGuest(req);

        assertThat(response.getAccessToken()).isEqualTo("access");
        assertThat(response.getRefreshToken()).isEqualTo("refresh");
        assertThat(response.getUser().getRole()).isEqualTo("GUEST");

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        org.mockito.Mockito.verify(userRepository).save(captor.capture());
        assertThat(captor.getValue().getRole()).isEqualTo(UserRole.GUEST);
        assertThat(captor.getValue().getPasswordHash()).isEqualTo("hashed");
    }

    @Test
    void rejectsDuplicateEmail() {
        AuthService authService = authService();
        RegisterGuestRequest req = new RegisterGuestRequest();
        req.setFullName("Khách B");
        req.setEmail("existing@example.com");
        req.setPassword("Password1!");

        when(userRepository.existsByEmail("existing@example.com")).thenReturn(true);

        assertThatThrownBy(() -> authService.registerGuest(req))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Email đã được sử dụng");
    }
}
