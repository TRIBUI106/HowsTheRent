package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.User;
import lombok.AllArgsConstructor;
import lombok.Data;

import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserResponse {
    private UUID id;
    private String fullName;
    private String email;
    private String phone;
    private String role;
    private String avatarUrl;
    private boolean active;
    private String specialties;
    private Integer activeTicketCount;
    private Double avgRating;

    public UserResponse(UUID id, String fullName, String email, String phone, String role, String avatarUrl, boolean active) {
        this.id = id;
        this.fullName = fullName;
        this.email = email;
        this.phone = phone;
        this.role = role;
        this.avatarUrl = avatarUrl;
        this.active = active;
        this.specialties = null;
        this.activeTicketCount = 0;
        this.avgRating = 5.0;
    }

    public static UserResponse from(User u) {
        UserResponse res = new UserResponse(u.getId(), u.getFullName(), u.getEmail(),
                u.getPhone(), u.getRole().name(), u.getAvatarUrl(), u.isActive());
        res.setSpecialties(u.getSpecialties());
        return res;
    }
}
