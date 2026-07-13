package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.MaintenanceRequest;
import chez1s.htrbackend.domain.entity.MaintenanceReview;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.MaintenanceStatus;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.domain.repository.MaintenanceRequestRepository;
import chez1s.htrbackend.domain.repository.MaintenanceReviewRepository;
import chez1s.htrbackend.domain.repository.UserRepository;
import chez1s.htrbackend.dto.request.CreateMaintenanceReviewRequest;
import chez1s.htrbackend.dto.response.MaintenanceReportResponse;
import chez1s.htrbackend.dto.response.MaintenanceReviewResponse;
import chez1s.htrbackend.dto.response.TechnicianPerformanceDto;
import chez1s.htrbackend.exception.BadRequestException;
import chez1s.htrbackend.exception.BusinessException;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MaintenanceReportService {

    private final MaintenanceRequestRepository maintenanceRepository;
    private final MaintenanceReviewRepository reviewRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public MaintenanceReportResponse getSummary(UUID ownerId) {
        boolean isAdmin = userRepository.findById(ownerId)
                .map(u -> u.getRole() == UserRole.ADMIN)
                .orElse(false);

        List<MaintenanceRequest> requests;
        if (isAdmin) {
            requests = maintenanceRepository.findAll();
        } else {
            requests = maintenanceRepository.findByRoomPropertyOwnerId(ownerId, org.springframework.data.domain.Pageable.unpaged()).getContent();
        }

        long total = requests.size();
        long completed = requests.stream().filter(r -> r.getStatus() == MaintenanceStatus.COMPLETED || r.getStatus() == MaintenanceStatus.DONE).count();
        long open = requests.stream().filter(r -> r.getStatus() == MaintenanceStatus.OPEN).count();
        long inProgress = requests.stream().filter(r -> r.getStatus() == MaintenanceStatus.ASSIGNED || r.getStatus() == MaintenanceStatus.IN_PROGRESS).count();
        long overdue = requests.stream().filter(r -> Boolean.TRUE.equals(r.getIsOverdueSla())).count();

        double totalHours = 0.0;
        long resolvedCount = 0;
        for (MaintenanceRequest r : requests) {
            if ((r.getStatus() == MaintenanceStatus.COMPLETED || r.getStatus() == MaintenanceStatus.DONE) && r.getResolvedAt() != null && r.getCreatedAt() != null) {
                double hours = (double) Duration.between(r.getCreatedAt(), r.getResolvedAt()).toMinutes() / 60.0;
                if (hours > 0) {
                    totalHours += hours;
                    resolvedCount++;
                }
            }
        }
        double avgHours = resolvedCount > 0 ? Math.round((totalHours / resolvedCount) * 10.0) / 10.0 : 0.0;

        Map<String, Long> byCategory = requests.stream()
                .collect(Collectors.groupingBy(r -> r.getCategory() != null ? r.getCategory().name() : "OTHER", Collectors.counting()));

        Map<String, Long> byPriority = requests.stream()
                .collect(Collectors.groupingBy(r -> r.getPriority() != null ? r.getPriority().name() : "NORMAL", Collectors.counting()));

        Map<String, Long> byStatus = requests.stream()
                .collect(Collectors.groupingBy(r -> r.getStatus().name(), Collectors.counting()));

        List<TechnicianPerformanceDto> techPerformances = listTechnicianPerformance();

        return MaintenanceReportResponse.builder()
                .totalTickets(total)
                .completedTickets(completed)
                .openTickets(open)
                .inProgressTickets(inProgress)
                .overdueSlaTickets(overdue)
                .avgResolutionHours(avgHours)
                .byCategory(byCategory)
                .byPriority(byPriority)
                .byStatus(byStatus)
                .technicianPerformance(techPerformances)
                .build();
    }

    public List<TechnicianPerformanceDto> listTechnicianPerformance() {
        List<User> technicians = userRepository.findByRoleAndActiveTrue(UserRole.TECHNICIAN);
        List<TechnicianPerformanceDto> result = new ArrayList<>();

        for (User tech : technicians) {
            List<MaintenanceRequest> assignedRequests = maintenanceRepository.findByAssignedToIdOrderByCreatedAtDesc(tech.getId());
            int assignedCount = assignedRequests.size();
            int activeCount = (int) assignedRequests.stream()
                    .filter(r -> r.getStatus() != MaintenanceStatus.DONE && r.getStatus() != MaintenanceStatus.COMPLETED && r.getStatus() != MaintenanceStatus.CANCELLED)
                    .count();
            int completedCount = (int) assignedRequests.stream()
                    .filter(r -> r.getStatus() == MaintenanceStatus.DONE || r.getStatus() == MaintenanceStatus.COMPLETED)
                    .count();
            int overdueCount = (int) assignedRequests.stream()
                    .filter(r -> Boolean.TRUE.equals(r.getIsOverdueSla()))
                    .count();

            List<MaintenanceReview> reviews = reviewRepository.findByTechnicianId(tech.getId());
            double avgStars = reviews.isEmpty() ? 5.0 : reviews.stream().mapToInt(MaintenanceReview::getRatingStars).average().orElse(5.0);
            avgStars = Math.round(avgStars * 10.0) / 10.0;

            result.add(TechnicianPerformanceDto.builder()
                    .technicianId(tech.getId())
                    .technicianName(tech.getFullName())
                    .specialties(tech.getSpecialties() != null ? tech.getSpecialties() : "ELECTRIC,PLUMBING,AIR_CONDITIONER,FURNITURE,OTHER")
                    .assignedCount(assignedCount)
                    .activeCount(activeCount)
                    .completedCount(completedCount)
                    .overdueSlaCount(overdueCount)
                    .avgRatingStars(avgStars)
                    .totalReviews(reviews.size())
                    .build());
        }
        return result;
    }

    @Transactional
    public MaintenanceReviewResponse createReview(UUID tenantId, UUID requestId, CreateMaintenanceReviewRequest req) {
        MaintenanceRequest mr = maintenanceRepository.findById(requestId)
                .orElseThrow(() -> new ResourceNotFoundException("MaintenanceRequest", requestId));

        if (mr.getStatus() != MaintenanceStatus.COMPLETED && mr.getStatus() != MaintenanceStatus.DONE) {
            throw new BusinessException("Chỉ có thể đánh giá khi phiếu bảo trì đã hoàn tất.");
        }

        if (mr.getAssignedTo() == null) {
            throw new BusinessException("Phiếu bảo trì chưa được phân công cho kỹ thuật viên nào.");
        }

        if (reviewRepository.findByMaintenanceRequestId(requestId).isPresent()) {
            throw new BusinessException("Phiếu bảo trì này đã được đánh giá rồi.");
        }

        User tenant = userRepository.findById(tenantId)
                .orElseThrow(() -> new ResourceNotFoundException("User", tenantId));

        MaintenanceReview review = MaintenanceReview.builder()
                .maintenanceRequest(mr)
                .technician(mr.getAssignedTo())
                .tenant(tenant)
                .ratingStars(req.getRatingStars())
                .comment(req.getComment())
                .build();

        review = reviewRepository.save(review);

        notificationService.create(
                mr.getAssignedTo().getId(),
                "Nhận đánh giá mới: " + req.getRatingStars() + " sao",
                "Khách thuê " + tenant.getFullName() + " đánh giá: " + (req.getComment() != null ? req.getComment() : ""),
                "REVIEW",
                review.getId()
        );

        return MaintenanceReviewResponse.from(review);
    }

    public List<MaintenanceReviewResponse> listReviewsByTechnician(UUID technicianId) {
        return reviewRepository.findByTechnicianId(technicianId).stream()
                .map(MaintenanceReviewResponse::from)
                .collect(Collectors.toList());
    }

    public List<MaintenanceReviewResponse> listAllReviews() {
        return reviewRepository.findAll().stream()
                .map(MaintenanceReviewResponse::from)
                .collect(Collectors.toList());
    }
}
