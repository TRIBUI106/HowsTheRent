package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.repository.ContractRepository;
import chez1s.htrbackend.domain.repository.InvoiceRepository;
import chez1s.htrbackend.service.PropertyService;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.VerticalAlignment;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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
            CellStyle bodyStyle = createBodyStyle(wb);
            Row header = sheet.createRow(0);
            String[] headers = {
                    "Ma hoa don", "Thang", "Phong", "Tai san",
                    "Tong tien", "Trang thai", "Han thanh toan", "Thanh toan luc"
            };

            for (int i = 0; i < headers.length; i++) {
                Cell cell = header.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
            }

            int rowNum = 1;
            for (var invoice : invoiceRepository.findAll()) {
                if (!propertyIds.contains(invoice.getContract().getRoom().getProperty().getId())) {
                    continue;
                }

                Row row = sheet.createRow(rowNum++);
                row.createCell(0).setCellValue(invoice.getId().toString());
                row.createCell(1).setCellValue(invoice.getInvoiceMonth().toString());
                row.createCell(2).setCellValue(invoice.getContract().getRoom().getRoomNumber());
                row.createCell(3).setCellValue(invoice.getContract().getRoom().getProperty().getName());
                row.createCell(4).setCellValue(invoice.getTotalAmount().doubleValue());
                row.createCell(5).setCellValue(invoice.getStatus().name());
                row.createCell(6).setCellValue(invoice.getDueDate() != null ? invoice.getDueDate().format(DTF) : "");
                row.createCell(7).setCellValue(invoice.getPaidAt() != null ? invoice.getPaidAt().format(DTF) : "");
                applyRowStyle(row, headers.length, bodyStyle);
            }

            finalizeSheet(sheet, rowNum, headers.length);
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
            CellStyle bodyStyle = createBodyStyle(wb);
            Row header = sheet.createRow(0);
            String[] headers = {
                    "Ma hop dong", "Phong", "Tai san", "Khach thue", "Email khach",
                    "Ngay vao", "Ngay ra", "Tien dat coc", "Trang thai",
                    "Ghi chu / dieu khoan", "Tep hop dong"
            };

            for (int i = 0; i < headers.length; i++) {
                Cell cell = header.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
            }

            int rowNum = 1;
            for (var contract : contractRepository.findAll()) {
                if (!propertyIds.contains(contract.getRoom().getProperty().getId())) {
                    continue;
                }

                Row row = sheet.createRow(rowNum++);
                row.createCell(0).setCellValue(contract.getId().toString());
                row.createCell(1).setCellValue(contract.getRoom().getRoomNumber());
                row.createCell(2).setCellValue(contract.getRoom().getProperty().getName());
                row.createCell(3).setCellValue(contract.getTenant().getFullName());
                row.createCell(4).setCellValue(contract.getTenant().getEmail() != null ? contract.getTenant().getEmail() : "");
                row.createCell(5).setCellValue(contract.getMoveInDate() != null ? contract.getMoveInDate().format(DTF) : "");
                row.createCell(6).setCellValue(contract.getMoveOutDate() != null ? contract.getMoveOutDate().format(DTF) : "");
                row.createCell(7).setCellValue(contract.getDepositAmount() != null ? contract.getDepositAmount().doubleValue() : 0D);
                row.createCell(8).setCellValue(contract.getStatus().name());
                row.createCell(9).setCellValue(contract.getNotes() != null ? contract.getNotes() : "");
                row.createCell(10).setCellValue(contract.getFileUrl() != null ? contract.getFileUrl() : "");
                applyRowStyle(row, headers.length, bodyStyle);
            }

            finalizeSheet(sheet, rowNum, headers.length);
            sheet.setColumnWidth(9, 40 * 256);
            sheet.setColumnWidth(10, 40 * 256);

            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=hopdong.xlsx")
                    .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                    .body(write(wb));
        } catch (Exception e) {
            throw new RuntimeException("Export failed", e);
        }
    }

    private void applyRowStyle(Row row, int columnCount, CellStyle style) {
        for (int col = 0; col < columnCount; col++) {
            row.getCell(col).setCellStyle(style);
        }
    }

    private void finalizeSheet(Sheet sheet, int rowCount, int columnCount) {
        sheet.createFreezePane(0, 1);
        sheet.setAutoFilter(new CellRangeAddress(0, Math.max(rowCount - 1, 0), 0, columnCount - 1));
        for (int i = 0; i < columnCount; i++) {
            sheet.autoSizeColumn(i);
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

    private CellStyle createBodyStyle(Workbook wb) {
        CellStyle style = wb.createCellStyle();
        style.setWrapText(true);
        style.setVerticalAlignment(VerticalAlignment.TOP);
        return style;
    }

    private byte[] write(Workbook wb) throws Exception {
        java.io.ByteArrayOutputStream baos = new java.io.ByteArrayOutputStream();
        wb.write(baos);
        return baos.toByteArray();
    }
}
