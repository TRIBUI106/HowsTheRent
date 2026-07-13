package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.*;
import chez1s.htrbackend.domain.repository.*;
import chez1s.htrbackend.dto.response.RoomNoteResponse;
import chez1s.htrbackend.dto.response.RoomTimelineResponse;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class RoomTimelineService {

    private final ContractRepository contractRepository;
    private final InvoiceRepository invoiceRepository;
    private final MaintenanceRequestRepository maintenanceRequestRepository;
    private final MeterReadingRepository meterReadingRepository;
    private final RoomNoteRepository roomNoteRepository;
    private final RoomService roomService;
    private final UserRepository userRepository;

    public List<RoomTimelineResponse> getTimeline(UUID roomId) {
        List<RoomTimelineResponse> entries = new ArrayList<>();

        for (Contract c : contractRepository.findByRoomId(roomId)) {
            entries.add(contractMoveInEntry(c));
            if (c.getMoveOutDate() != null) {
                entries.add(contractMoveOutEntry(c));
            }
        }

        for (Invoice inv : invoiceRepository.findByRoomIdOrderByInvoiceMonthDesc(roomId)) {
            entries.add(invoiceEntry(inv));
        }

        for (MaintenanceRequest mr : maintenanceRequestRepository.findByRoomIdOrderByCreatedAtDesc(roomId)) {
            entries.add(maintenanceEntry(mr));
        }

        for (MeterReading mr : meterReadingRepository.findByRoomIdOrderByReadingMonthDesc(roomId)) {
            entries.add(meterReadingEntry(mr));
        }

        for (RoomNote note : roomNoteRepository.findByRoomIdOrderByCreatedAtDesc(roomId)) {
            entries.add(noteEntry(note));
        }

        entries.sort(Comparator.comparing(RoomTimelineResponse::date).reversed());
        return entries;
    }

    @Transactional
    public RoomNoteResponse addNote(UUID roomId, UUID authorId, String content) {
        Room room = roomService.getById(roomId);
        User author = userRepository.findById(authorId)
                .orElseThrow(() -> new ResourceNotFoundException("User", authorId));
        RoomNote note = RoomNote.builder()
                .room(room)
                .author(author)
                .content(content)
                .build();
        return RoomNoteResponse.from(roomNoteRepository.save(note));
    }

    @Transactional
    public void deleteNote(UUID noteId) {
        if (!roomNoteRepository.existsById(noteId)) {
            throw new ResourceNotFoundException("RoomNote", noteId);
        }
        roomNoteRepository.deleteById(noteId);
    }

    private RoomTimelineResponse contractMoveInEntry(Contract c) {
        Map<String, Object> meta = new LinkedHashMap<>();
        meta.put("contractId", c.getId());
        meta.put("contractStatus", c.getStatus().name());
        meta.put("tenantId", c.getTenant().getId());
        meta.put("tenantName", c.getTenant().getFullName());
        meta.put("tenantEmail", c.getTenant().getEmail());
        meta.put("depositAmount", c.getDepositAmount());
        return new RoomTimelineResponse(
                "CONTRACT_MOVE_IN",
                c.getMoveInDate().atStartOfDay(),
                c.getTenant().getFullName() + " vào ở",
                "Hợp đồng bắt đầu từ " + c.getMoveInDate(),
                meta
        );
    }

    private RoomTimelineResponse contractMoveOutEntry(Contract c) {
        Map<String, Object> meta = new LinkedHashMap<>();
        meta.put("contractId", c.getId());
        meta.put("contractStatus", c.getStatus().name());
        meta.put("tenantId", c.getTenant().getId());
        meta.put("tenantName", c.getTenant().getFullName());
        meta.put("tenantEmail", c.getTenant().getEmail());
        String reason = c.getStatus().name().equals("TERMINATED") ? "Chấm dứt hợp đồng" : "Hết hạn hợp đồng";
        return new RoomTimelineResponse(
                "CONTRACT_MOVE_OUT",
                c.getMoveOutDate().atStartOfDay(),
                c.getTenant().getFullName() + " rời phòng",
                reason + " ngày " + c.getMoveOutDate(),
                meta
        );
    }

    private RoomTimelineResponse invoiceEntry(Invoice inv) {
        Map<String, Object> meta = new LinkedHashMap<>();
        meta.put("invoiceId", inv.getId());
        meta.put("invoiceStatus", inv.getStatus().name());
        meta.put("totalAmount", inv.getTotalAmount());
        meta.put("tenantName", inv.getContract().getTenant().getFullName());
        String monthStr = inv.getInvoiceMonth().getYear() + "/" + String.format("%02d", inv.getInvoiceMonth().getMonthValue());
        String statusVi = switch (inv.getStatus()) {
            case PAID -> "Đã thanh toán";
            case PENDING -> "Chờ thanh toán";
            case OVERDUE -> "Quá hạn";
        };
        return new RoomTimelineResponse(
                "INVOICE",
                inv.getInvoiceMonth().atStartOfDay(),
                "Hoá đơn tháng " + monthStr,
                inv.getTotalAmount() + " VNĐ - " + statusVi,
                meta
        );
    }

    private RoomTimelineResponse maintenanceEntry(MaintenanceRequest mr) {
        Map<String, Object> meta = new LinkedHashMap<>();
        meta.put("maintenanceId", mr.getId());
        meta.put("maintenanceStatus", mr.getStatus().name());
        meta.put("tenantName", mr.getTenant().getFullName());
        if (mr.getAssignedTo() != null) meta.put("assignedTo", mr.getAssignedTo().getFullName());
        String statusVi = switch (mr.getStatus()) {
            case OPEN -> "Mới";
            case ASSIGNED -> "Đã phân công";
            case IN_PROGRESS -> "Đang xử lý";
            case PENDING_PAYMENT -> "Chờ thanh toán vật tư";
            case PENDING_REVIEW -> "Chờ nghiệm thu";
            case COMPLETED, DONE -> "Đã xong";
            case CANCELLED -> "Đã hủy";
        };
        return new RoomTimelineResponse(
                "MAINTENANCE",
                mr.getCreatedAt(),
                "Sửa chữa: " + mr.getTitle(),
                statusVi + (mr.getDescription() != null ? " — " + mr.getDescription() : ""),
                meta
        );
    }

    private RoomTimelineResponse meterReadingEntry(MeterReading mr) {
        Map<String, Object> meta = new LinkedHashMap<>();
        meta.put("meterReadingId", mr.getId());
        meta.put("elecOld", mr.getElecOld());
        meta.put("elecNew", mr.getElecNew());
        meta.put("elecUsed", mr.getElecNew() - mr.getElecOld());
        if (mr.getWaterNew() != null && mr.getWaterOld() != null) {
            meta.put("waterOld", mr.getWaterOld());
            meta.put("waterNew", mr.getWaterNew());
            meta.put("waterUsed", mr.getWaterNew() - mr.getWaterOld());
        }
        meta.put("recordedBy", mr.getRecordedBy().getFullName());
        String monthStr = mr.getReadingMonth().getYear() + "/" + String.format("%02d", mr.getReadingMonth().getMonthValue());
        long elecUsed = mr.getElecNew() - mr.getElecOld();
        String desc = "Điện: " + elecUsed + " kWh";
        if (mr.getWaterNew() != null && mr.getWaterOld() != null) {
            desc += " — Nước: " + (mr.getWaterNew() - mr.getWaterOld()) + " m³";
        }
        return new RoomTimelineResponse(
                "METER_READING",
                mr.getRecordedAt(),
                "Ghi số tháng " + monthStr,
                desc,
                meta
        );
    }

    private RoomTimelineResponse noteEntry(RoomNote note) {
        Map<String, Object> meta = new LinkedHashMap<>();
        meta.put("noteId", note.getId());
        meta.put("authorName", note.getAuthor().getFullName());
        meta.put("authorEmail", note.getAuthor().getEmail());
        return new RoomTimelineResponse(
                "NOTE",
                note.getCreatedAt(),
                "Ghi chú của " + note.getAuthor().getFullName(),
                note.getContent(),
                meta
        );
    }
}
