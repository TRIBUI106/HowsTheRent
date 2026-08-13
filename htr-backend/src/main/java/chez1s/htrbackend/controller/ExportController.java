package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Contract;
import chez1s.htrbackend.domain.entity.Invoice;
import chez1s.htrbackend.security.ActorContext;
import chez1s.htrbackend.security.OwnerScopeResolver;
import chez1s.htrbackend.service.ContractService;
import chez1s.htrbackend.service.InvoiceService;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.format.DateTimeFormatter;
import java.util.List;

@RestController
@RequestMapping("/api/export")
@RequiredArgsConstructor
public class ExportController {

    private final InvoiceService invoiceService;
    private final ContractService contractService;
    private final OwnerScopeResolver ownerScopeResolver;

    private static final DateTimeFormatter DTF = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    @GetMapping("/invoices")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<byte[]> exportInvoices(Authentication authentication) {
        ActorContext actor = ActorContext.require(authentication);
        List<Invoice> invoices = actor.isPlatformAdmin()
                ? invoiceService.listAll()
                : invoiceService.listAllByOwner(ownerScopeResolver.requireOwnerId(actor));
        if (invoices.isEmpty()) {
            return noData();
        }

        try (Workbook workbook = new XSSFWorkbook()) {
            Sheet sheet = workbook.createSheet("Hoa don");
            CellStyle headerStyle = createHeaderStyle(workbook);
            CellStyle bodyStyle = createBodyStyle(workbook);
            String[] headers = {"Ma hoa don", "Thang", "Phong", "Tai san", "Tong tien", "Trang thai", "Han thanh toan", "Thanh toan luc"};
            createHeader(sheet, headers, headerStyle);
            int rowNum = 1;
            for (Invoice invoice : invoices) {
                Row row = sheet.createRow(rowNum++);
                row.createCell(0).setCellValue(invoice.getId().toString());
                row.createCell(1).setCellValue(invoice.getInvoiceMonth().toString());
                row.createCell(2).setCellValue(invoice.getRoom().getRoomNumber());
                row.createCell(3).setCellValue(invoice.getRoom().getProperty().getName());
                row.createCell(4).setCellValue(invoice.getTotalAmount().doubleValue());
                row.createCell(5).setCellValue(invoice.getStatus().name());
                row.createCell(6).setCellValue(invoice.getDueDate() != null ? invoice.getDueDate().format(DTF) : "");
                row.createCell(7).setCellValue(invoice.getPaidAt() != null ? invoice.getPaidAt().format(DTF) : "");
                applyRowStyle(row, headers.length, bodyStyle);
            }
            finalizeSheet(sheet, rowNum, headers.length);
            return attachment("hoadon.xlsx", write(workbook));
        } catch (Exception exception) {
            throw new RuntimeException("Export failed", exception);
        }
    }

    @GetMapping("/contracts")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<byte[]> exportContracts(Authentication authentication) {
        ActorContext actor = ActorContext.require(authentication);
        List<Contract> contracts = actor.isPlatformAdmin()
                ? contractService.listAll()
                : contractService.listByOwner(ownerScopeResolver.requireOwnerId(actor));
        if (contracts.isEmpty()) {
            return noData();
        }

        try (Workbook workbook = new XSSFWorkbook()) {
            Sheet sheet = workbook.createSheet("Hop dong");
            CellStyle headerStyle = createHeaderStyle(workbook);
            CellStyle bodyStyle = createBodyStyle(workbook);
            String[] headers = {"Ma hop dong", "Phong", "Tai san", "Khach thue", "Email khach", "Ngay vao", "Ngay ra", "Tien dat coc", "Trang thai", "Ghi chu / dieu khoan", "Tep hop dong"};
            createHeader(sheet, headers, headerStyle);
            int rowNum = 1;
            for (Contract contract : contracts) {
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
            return attachment("hopdong.xlsx", write(workbook));
        } catch (Exception exception) {
            throw new RuntimeException("Export failed", exception);
        }
    }

    private ResponseEntity<byte[]> noData() {
        return ResponseEntity.status(HttpStatus.NO_CONTENT)
                .header("X-Export-Result", "NO_DATA")
                .build();
    }

    private ResponseEntity<byte[]> attachment(String filename, byte[] bytes) {
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=" + filename)
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(bytes);
    }

    private void createHeader(Sheet sheet, String[] headers, CellStyle style) {
        Row header = sheet.createRow(0);
        for (int i = 0; i < headers.length; i++) {
            Cell cell = header.createCell(i);
            cell.setCellValue(headers[i]);
            cell.setCellStyle(style);
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

    private CellStyle createHeaderStyle(Workbook workbook) {
        CellStyle style = workbook.createCellStyle();
        Font font = workbook.createFont();
        font.setBold(true);
        style.setFont(font);
        style.setFillForegroundColor(IndexedColors.GREY_25_PERCENT.getIndex());
        style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        return style;
    }

    private CellStyle createBodyStyle(Workbook workbook) {
        CellStyle style = workbook.createCellStyle();
        style.setWrapText(true);
        style.setVerticalAlignment(VerticalAlignment.TOP);
        return style;
    }

    private byte[] write(Workbook workbook) throws Exception {
        java.io.ByteArrayOutputStream output = new java.io.ByteArrayOutputStream();
        workbook.write(output);
        return output.toByteArray();
    }
}
