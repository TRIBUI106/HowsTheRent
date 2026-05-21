package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.repository.ContractRepository;
import chez1s.htrbackend.domain.repository.InvoiceRepository;
import chez1s.htrbackend.service.PropertyService;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.format.DateTimeFormatter;
import java.util.UUID;

@RestController
@RequestMapping("/api/export")
@RequiredArgsConstructor
public class ExportController {

    private final InvoiceRepository invoiceRepository;
    private final ContractRepository contractRepository;
    private final PropertyService propertyService;

    private static final DateTimeFormatter DTF = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    @GetMapping("/invoices")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<byte[]> exportInvoices(Authentication auth) {
        UUID ownerId = (UUID) auth.getPrincipal();
        var properties = propertyService.listByOwner(ownerId);
        var propertyIds = properties.stream().map(p -> p.getId()).toList();

        try (Workbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("Hoa don");
            CellStyle headerStyle = createHeaderStyle(wb);
            Row header = sheet.createRow(0);
            String[] headers = {"Ma HD", "Thang", "Phong", "Toa nha", "Tong tien", "Trang thai", "Han", "Thanh toan luc"};
            for (int i = 0; i < headers.length; i++) {
                Cell cell = header.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
            }
            int rowNum = 1;
            for (var inv : invoiceRepository.findAll()) {
                if (!propertyIds.contains(inv.getContract().getRoom().getProperty().getId())) continue;
                Row row = sheet.createRow(rowNum++);
                row.createCell(0).setCellValue(inv.getId().toString());
                row.createCell(1).setCellValue(inv.getInvoiceMonth().toString());
                row.createCell(2).setCellValue(inv.getContract().getRoom().getRoomNumber());
                row.createCell(3).setCellValue(inv.getContract().getRoom().getProperty().getName());
                row.createCell(4).setCellValue(inv.getTotalAmount().doubleValue());
                row.createCell(5).setCellValue(inv.getStatus().name());
                row.createCell(6).setCellValue(inv.getDueDate() != null ? inv.getDueDate().format(DTF) : "");
                row.createCell(7).setCellValue(inv.getPaidAt() != null ? inv.getPaidAt().format(DTF) : "");
            }
            for (int i = 0; i < headers.length; i++) sheet.autoSizeColumn(i);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=hoadon.xlsx")
                    .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                    .body(write(wb));
        } catch (Exception e) {
            throw new RuntimeException("Export failed", e);
        }
    }

    @GetMapping("/contracts")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<byte[]> exportContracts(Authentication auth) {
        UUID ownerId = (UUID) auth.getPrincipal();
        var properties = propertyService.listByOwner(ownerId);
        var propertyIds = properties.stream().map(p -> p.getId()).toList();

        try (Workbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("Hop dong");
            CellStyle headerStyle = createHeaderStyle(wb);
            Row header = sheet.createRow(0);
            String[] headers = {"Ma HD", "Phong", "Toa nha", "Khach thue", "Ngay vao", "Ngay ra", "Tien dat coc", "Trang thai"};
            for (int i = 0; i < headers.length; i++) {
                Cell cell = header.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
            }
            int rowNum = 1;
            for (var c : contractRepository.findAll()) {
                if (!propertyIds.contains(c.getRoom().getProperty().getId())) continue;
                Row row = sheet.createRow(rowNum++);
                row.createCell(0).setCellValue(c.getId().toString());
                row.createCell(1).setCellValue(c.getRoom().getRoomNumber());
                row.createCell(2).setCellValue(c.getRoom().getProperty().getName());
                row.createCell(3).setCellValue(c.getTenant().getFullName());
                row.createCell(4).setCellValue(c.getMoveInDate() != null ? c.getMoveInDate().format(DTF) : "");
                row.createCell(5).setCellValue(c.getMoveOutDate() != null ? c.getMoveOutDate().format(DTF) : "");
                row.createCell(6).setCellValue(c.getDepositAmount().doubleValue());
                row.createCell(7).setCellValue(c.getStatus().name());
            }
            for (int i = 0; i < headers.length; i++) sheet.autoSizeColumn(i);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=hopdong.xlsx")
                    .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                    .body(write(wb));
        } catch (Exception e) {
            throw new RuntimeException("Export failed", e);
        }
    }

    private CellStyle createHeaderStyle(Workbook wb) {
        CellStyle style = wb.createCellStyle();
        Font font = wb.createFont();
        font.setBold(true);
        style.setFont(font);
        style.setFillForegroundColor(IndexedColors.GREY_25_PERCENT.getIndex());
        style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        return style;
    }

    private byte[] write(Workbook wb) throws Exception {
        java.io.ByteArrayOutputStream baos = new java.io.ByteArrayOutputStream();
        wb.write(baos);
        return baos.toByteArray();
    }
}
