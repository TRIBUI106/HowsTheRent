package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.User;
import lombok.AllArgsConstructor;
import lombok.Data;

import java.util.UUID;

@Data
@AllArgsConstructor
public class UserResponse {
    private UUID id;
    private String fullName;
    private String email;
    private String phone;
    private String role;
    private String avatarUrl;
    private boolean active;

    public static UserResponse from(User u) {
        return new UserResponse(u.getId(), u.getFullName(), u.getEmail(),
                u.getPhone(), u.getRole().name(), u.getAvatarUrl(), u.isActive());
    }
}
