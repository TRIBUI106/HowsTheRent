package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.UserRole;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class UserResponseTest {

    @Test
    void from_includesActiveFlag() {
        User user = User.builder()
                .fullName("Nguyễn Văn A")
                .email("a@example.com")
                .phone("0900000000")
                .role(UserRole.TENANT)
                .avatarUrl("avatar.png")
                .active(true)
                .build();

        UserResponse response = UserResponse.from(user);

        assertThat(response.isActive()).isTrue();
    }
}
