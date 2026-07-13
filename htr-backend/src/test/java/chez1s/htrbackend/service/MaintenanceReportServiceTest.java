package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.*;
import chez1s.htrbackend.domain.enums.MaintenanceCategory;
import chez1s.htrbackend.domain.enums.MaintenancePriority;
import chez1s.htrbackend.domain.enums.MaintenanceStatus;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.domain.repository.MaintenanceRequestRepository;
import chez1s.htrbackend.domain.repository.MaintenanceReviewRepository;
import chez1s.htrbackend.domain.repository.UserRepository;
import chez1s.htrbackend.dto.request.CreateMaintenanceReviewRequest;
import chez1s.htrbackend.dto.response.MaintenanceReportResponse;
import chez1s.htrbackend.dto.response.MaintenanceReviewResponse;
import chez1s.htrbackend.exception.BusinessException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MaintenanceReportServiceTest {

    @Mock
    private MaintenanceRequestRepository maintenanceRepository;
    @Mock
    private MaintenanceReviewRepository reviewRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private NotificationService notificationService;

    @InjectMocks
    private MaintenanceReportService reportService;

    private UUID tenantId;
    private UUID techId;
    private UUID requestId;
    private User tenant;
    private User tech;
    private MaintenanceRequest request;

    @BeforeEach
    void setup() {
        tenantId = UUID.randomUUID();
        techId = UUID.randomUUID();
        requestId = UUID.randomUUID();

        tenant = User.builder().id(tenantId).fullName("Tenant").role(UserRole.TENANT).build();
        tech = User.builder().id(techId).fullName("Tech").role(UserRole.TECHNICIAN).specialties("ELECTRIC,PLUMBING").build();
        request = MaintenanceRequest.builder()
                .id(requestId)
                .tenant(tenant)
                .assignedTo(tech)
                .status(MaintenanceStatus.COMPLETED)
                .priority(MaintenancePriority.HIGH)
                .category(MaintenanceCategory.ELECTRIC)
                .isOverdueSla(false)
                .build();
    }

    @Test
    void getSummary_AdminOwner_ReturnsStatistics() {
        UUID adminId = UUID.randomUUID();
        when(userRepository.findById(adminId)).thenReturn(Optional.of(User.builder().id(adminId).role(UserRole.ADMIN).build()));
        when(maintenanceRepository.findAll()).thenReturn(List.of(request));
        when(userRepository.findByRoleAndActiveTrue(UserRole.TECHNICIAN)).thenReturn(List.of(tech));
        when(maintenanceRepository.findByAssignedToIdOrderByCreatedAtDesc(techId)).thenReturn(List.of(request));
        when(reviewRepository.findByTechnicianId(techId)).thenReturn(List.of());

        MaintenanceReportResponse summary = reportService.getSummary(adminId);

        assertEquals(1, summary.getTotalTickets());
        assertEquals(1, summary.getCompletedTickets());
        assertEquals(1, summary.getTechnicianPerformance().size());
        assertEquals("ELECTRIC,PLUMBING", summary.getTechnicianPerformance().get(0).getSpecialties());
    }

    @Test
    void getSummary_LandlordOwner_ReturnsStatistics() {
        UUID landlordId = UUID.randomUUID();
        when(userRepository.findById(landlordId)).thenReturn(Optional.of(User.builder().id(landlordId).role(UserRole.TENANT).build()));
        when(maintenanceRepository.findByRoomPropertyOwnerId(eq(landlordId), any(Pageable.class))).thenReturn(new PageImpl<>(List.of(request)));
        when(userRepository.findByRoleAndActiveTrue(UserRole.TECHNICIAN)).thenReturn(List.of(tech));
        when(maintenanceRepository.findByAssignedToIdOrderByCreatedAtDesc(techId)).thenReturn(List.of(request));
        when(reviewRepository.findByTechnicianId(techId)).thenReturn(List.of());

        MaintenanceReportResponse summary = reportService.getSummary(landlordId);

        assertEquals(1, summary.getTotalTickets());
        assertEquals(1, summary.getCompletedTickets());
    }

    @Test
    void createReview_ValidCompletedTicket_ReturnsReview() {
        CreateMaintenanceReviewRequest req = new CreateMaintenanceReviewRequest(5, "Very good work");

        when(userRepository.findById(tenantId)).thenReturn(Optional.of(tenant));
        when(maintenanceRepository.findById(requestId)).thenReturn(Optional.of(request));
        when(reviewRepository.findByMaintenanceRequestId(requestId)).thenReturn(Optional.empty());
        when(reviewRepository.save(any(MaintenanceReview.class))).thenAnswer(i -> {
            MaintenanceReview r = i.getArgument(0);
            r.setId(UUID.randomUUID());
            return r;
        });

        MaintenanceReviewResponse res = reportService.createReview(tenantId, requestId, req);

        assertNotNull(res.getId());
        assertEquals(5, res.getRatingStars());
        assertEquals("Very good work", res.getComment());
    }

    @Test
    void createReview_TicketNotDoneOrCompleted_ThrowsBusinessException() {
        request.setStatus(MaintenanceStatus.IN_PROGRESS);
        when(maintenanceRepository.findById(requestId)).thenReturn(Optional.of(request));

        CreateMaintenanceReviewRequest req = new CreateMaintenanceReviewRequest(5, "Good");

        assertThrows(BusinessException.class, () -> reportService.createReview(tenantId, requestId, req));
    }
}
