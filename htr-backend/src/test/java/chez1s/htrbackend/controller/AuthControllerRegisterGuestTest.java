package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.request.RegisterGuestRequest;
import chez1s.htrbackend.dto.response.AuthResponse;
import chez1s.htrbackend.dto.response.UserResponse;
import chez1s.htrbackend.service.AuthService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class AuthControllerRegisterGuestTest {

    private AuthService authService;
    private AuthController controller;

    @BeforeEach
    void setup() {
        authService = mock(AuthService.class);
        controller = new AuthController(authService);
        ReflectionTestUtils.setField(controller, "secureCookies", true);
        ReflectionTestUtils.setField(controller, "cookieSameSite", "Lax");
    }

    @Test
    void registerGuestReturns201AndSetsAccessTokenCookieAtRootPath() {
        UserResponse user = new UserResponse(UUID.randomUUID(), "Khách A", "guest@example.com", null, "GUEST", null, true);
        when(authService.registerGuest(any(RegisterGuestRequest.class)))
                .thenReturn(new AuthResponse("access-token", "refresh-token", user));
        MockHttpServletResponse response = new MockHttpServletResponse();

        ResponseEntity<AuthResponse> result = controller.registerGuest(new RegisterGuestRequest(), response);

        assertThat(result.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(result.getBody().getUser().getRole()).isEqualTo("GUEST");
        assertThat(response.getHeaders(HttpHeaders.SET_COOKIE))
                .anySatisfy(cookie -> assertThat(cookie).startsWith("accessToken=access-token;").contains("Path=/;"));
    }
}
