package chez1s.htrbackend.controller;

import chez1s.htrbackend.controller.UserController.CreateUserRequest;
import chez1s.htrbackend.controller.UserController.UpdateUserRequest;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.domain.repository.MaintenanceRequestRepository;
import chez1s.htrbackend.domain.repository.UserRepository;
import chez1s.htrbackend.exception.BusinessException;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import chez1s.htrbackend.service.AuthService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

// Regression coverage for the 409 reported against POST/PUT /api/users: existsByEmail was the
// only pre-insert uniqueness check, so a duplicate phone number silently fell through to the raw
// DB unique-constraint violation (generic 409, no usable message) instead of a clean 400.
@ExtendWith(MockitoExtension.class)
class UserControllerTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private MaintenanceRequestRepository maintenanceRepository;
    @Mock
    private PasswordEncoder passwordEncoder;
    @Mock
    private AuthService authService;

    private UserController controller;
    private UUID userId;

    @BeforeEach
    void setup() {
        controller = new UserController(userRepository, maintenanceRepository, passwordEncoder, authService);
        userId = UUID.randomUUID();
        lenient().when(passwordEncoder.encode(anyString())).thenReturn("hashed");
    }

    private CreateUserRequest createRequest(String email, String phone) {
        CreateUserRequest req = new CreateUserRequest();
        req.setFullName("Nguyễn Văn A");
        req.setEmail(email);
        req.setPhone(phone);
        req.setPassword("Test1234!");
        req.setRole(UserRole.TENANT);
        return req;
    }

    @Test
    void create_DuplicatePhone_ThrowsBusinessExceptionInsteadOfHittingTheDbConstraint() {
        when(userRepository.existsByEmail("new@example.com")).thenReturn(false);
        when(userRepository.existsByPhone("0900000001")).thenReturn(true);

        assertThatThrownBy(() -> controller.create(createRequest("new@example.com", "0900000001")))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("điện thoại");

        verify(userRepository, never()).save(any());
    }

    @Test
    void create_DuplicateEmail_StillThrowsBeforeCheckingPhone() {
        when(userRepository.existsByEmail("dup@example.com")).thenReturn(true);

        assertThatThrownBy(() -> controller.create(createRequest("dup@example.com", "0900000002")))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Email");

        verify(userRepository, never()).existsByPhone(anyString());
        verify(userRepository, never()).save(any());
    }

    @Test
    void create_BlankPhone_SkipsThePhoneUniquenessCheck() {
        when(userRepository.existsByEmail("new@example.com")).thenReturn(false);
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        controller.create(createRequest("new@example.com", ""));

        verify(userRepository, never()).existsByPhone(anyString());
        verify(userRepository).save(any(User.class));
    }

    @Test
    void update_PhoneAlreadyUsedByAnotherUser_ThrowsBusinessException() {
        User existing = User.builder().id(userId).fullName("Cũ").phone("0900000003").role(UserRole.TENANT).build();
        when(userRepository.findById(userId)).thenReturn(java.util.Optional.of(existing));
        when(userRepository.existsByPhoneAndIdNot("0900000009", userId)).thenReturn(true);

        UpdateUserRequest req = new UpdateUserRequest();
        req.setFullName("Cập nhật");
        req.setPhone("0900000009");

        assertThatThrownBy(() -> controller.update(userId, req))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("điện thoại");

        verify(userRepository, never()).save(any());
    }

    @Test
    void update_UnknownUser_ThrowsResourceNotFound() {
        when(userRepository.findById(userId)).thenReturn(java.util.Optional.empty());

        UpdateUserRequest req = new UpdateUserRequest();
        req.setFullName("Ai đó");

        assertThatThrownBy(() -> controller.update(userId, req))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void update_SamePhoneAsOwnRecord_DoesNotConflictWithItself() {
        User existing = User.builder().id(userId).fullName("Cũ").phone("0900000003").role(UserRole.TENANT).build();
        when(userRepository.findById(userId)).thenReturn(java.util.Optional.of(existing));
        when(userRepository.existsByPhoneAndIdNot("0900000003", userId)).thenReturn(false);
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        UpdateUserRequest req = new UpdateUserRequest();
        req.setFullName("Cập nhật");
        req.setPhone("0900000003");

        ResponseEntity<?> response = controller.update(userId, req);

        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
        verify(userRepository).save(existing);
    }
}
