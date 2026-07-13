package chez1s.htrbackend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MaintenanceReportResponse {
    private long totalTickets;
    private long completedTickets;
    private long openTickets;
    private long inProgressTickets;
    private long overdueSlaTickets;
    private double avgResolutionHours;
    private Map<String, Long> byCategory;
    private Map<String, Long> byPriority;
    private Map<String, Long> byStatus;
    private List<TechnicianPerformanceDto> technicianPerformance;
}
