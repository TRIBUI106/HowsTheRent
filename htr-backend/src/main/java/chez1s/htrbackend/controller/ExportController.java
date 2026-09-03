package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Contract;
import chez1s.htrbackend.domain.entity.Invoice;
import chez1s.htrbackend.domain.enums.ContractStatus;
import chez1s.htrbackend.domain.enums.InvoiceStatus;
import chez1s.htrbackend.security.ActorContext;
import chez1s.htrbackend.security.OwnerScopeResolver;
import chez1s.htrbackend.service.ContractService;
import chez1s.htrbackend.service.InvoiceService;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.XSSFCellStyle;
import org.apache.poi.xssf.usermodel.XSSFColor;
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

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

// Renders both exports as an actual formatted document (branded title, colored header, zebra
// striping, real numeric/date cells with proper formats, color-coded status chips) rather than a
// raw data dump — matches the same accent blue used on the invoice PDF (InvoicePdfService) for a
// consistent look across every exported document.
@RestController
@RequestMapping("/api/export")
@RequiredArgsConstructor
public class ExportController {

    private final InvoiceService invoiceService;
    private final ContractService contractService;
    private final OwnerScopeResolver ownerScopeResolver;

    private static final DateTimeFormatter DTF = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    private static final byte[] ACCENT_RGB = rgb(0x2F, 0x6F, 0xED);
    private static final byte[] ACCENT_TEXT_RGB = rgb(0x1F, 0x4E, 0xC2);
    private static final byte[] ZEBRA_RGB = rgb(0xF3, 0xF6, 0xFC);
    private static final byte[] BORDER_RGB = rgb(0xD9, 0xDF, 0xEA);
    private static final byte[] MUTED_TEXT_RGB = rgb(0x6B, 0x72, 0x80);
    private static final byte[] SUCCESS_RGB = rgb(0x16, 0xA3, 0x4A);
    private static final byte[] PENDING_RGB = rgb(0x25, 0x63, 0xEB);
    private static final byte[] ERROR_RGB = rgb(0xDC, 0x26, 0x26);
    private static final byte[] NEUTRAL_RGB = rgb(0x6B, 0x72, 0x80);

    private static byte[] rgb(int r, int g, int b) {
        return new byte[]{(byte) r, (byte) g, (byte) b};
    }

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

        try (XSSFWorkbook workbook = new XSSFWorkbook()) {
            Sheet sheet = workbook.createSheet("Hóa đơn");
            String[] headers = {"Mã hóa đơn", "Tháng", "Phòng", "Tài sản", "Tổng tiền", "Trạng thái", "Hạn thanh toán", "Ngày thanh toán"};
            int headerRow = writeTitleBlock(workbook, sheet, "DANH SÁCH HÓA ĐƠN", invoices.size() + " hóa đơn", headers.length);
            writeHeaderRow(workbook, sheet, headerRow, headers);

            CellStyle idStyle = bodyCellStyle(workbook, false, HorizontalAlignment.LEFT);
            CellStyle idStyleAlt = bodyCellStyle(workbook, true, HorizontalAlignment.LEFT);
            CellStyle textStyle = bodyCellStyle(workbook, false, HorizontalAlignment.LEFT);
            CellStyle textStyleAlt = bodyCellStyle(workbook, true, HorizontalAlignment.LEFT);
            CellStyle currencyStyle = currencyCellStyle(workbook, false);
            CellStyle currencyStyleAlt = currencyCellStyle(workbook, true);
            CellStyle dateStyle = dateCellStyle(workbook, false, false);
            CellStyle dateStyleAlt = dateCellStyle(workbook, true, false);
            CellStyle dateTimeStyle = dateCellStyle(workbook, false, true);
            CellStyle dateTimeStyleAlt = dateCellStyle(workbook, true, true);

            int rowNum = headerRow + 1;
            for (Invoice invoice : invoices) {
                boolean zebra = (rowNum - headerRow) % 2 == 0;
                Row row = sheet.createRow(rowNum++);

                setText(row, 0, invoice.getId().toString().substring(0, 8).toUpperCase(), zebra ? idStyleAlt : idStyle);
                setText(row, 1, invoice.getInvoiceMonth().format(DateTimeFormatter.ofPattern("MM/yyyy")), zebra ? textStyleAlt : textStyle);
                setText(row, 2, invoice.getRoom().getRoomNumber(), zebra ? textStyleAlt : textStyle);
                setText(row, 3, invoice.getRoom().getProperty().getName(), zebra ? textStyleAlt : textStyle);
                setNumber(row, 4, invoice.getTotalAmount().doubleValue(), zebra ? currencyStyleAlt : currencyStyle);
                setStatusChip(workbook, row, 5, invoiceStatusLabel(invoice.getStatus()), invoiceStatusColor(invoice.getStatus()));
                setDate(row, 6, invoice.getDueDate(), zebra ? dateStyleAlt : dateStyle);
                setDateTime(row, 7, invoice.getPaidAt(), zebra ? dateTimeStyleAlt : dateTimeStyle);
            }
            finalizeSheet(sheet, headerRow, headers.length);
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

        try (XSSFWorkbook workbook = new XSSFWorkbook()) {
            Sheet sheet = workbook.createSheet("Hợp đồng");
            String[] headers = {"Mã hợp đồng", "Phòng", "Tài sản", "Khách thuê", "Email khách", "Ngày vào", "Ngày ra", "Tiền đặt cọc", "Trạng thái", "Ghi chú / điều khoản", "Tệp hợp đồng"};
            int headerRow = writeTitleBlock(workbook, sheet, "DANH SÁCH HỢP ĐỒNG", contracts.size() + " hợp đồng", headers.length);
            writeHeaderRow(workbook, sheet, headerRow, headers);

            CellStyle textStyle = bodyCellStyle(workbook, false, HorizontalAlignment.LEFT);
            CellStyle textStyleAlt = bodyCellStyle(workbook, true, HorizontalAlignment.LEFT);
            CellStyle currencyStyle = currencyCellStyle(workbook, false);
            CellStyle currencyStyleAlt = currencyCellStyle(workbook, true);
            CellStyle dateStyle = dateCellStyle(workbook, false, false);
            CellStyle dateStyleAlt = dateCellStyle(workbook, true, false);

            int rowNum = headerRow + 1;
            for (Contract contract : contracts) {
                boolean zebra = (rowNum - headerRow) % 2 == 0;
                Row row = sheet.createRow(rowNum++);

                setText(row, 0, contract.getId().toString().substring(0, 8).toUpperCase(), zebra ? textStyleAlt : textStyle);
                setText(row, 1, contract.getRoom().getRoomNumber(), zebra ? textStyleAlt : textStyle);
                setText(row, 2, contract.getRoom().getProperty().getName(), zebra ? textStyleAlt : textStyle);
                setText(row, 3, contract.getTenant().getFullName(), zebra ? textStyleAlt : textStyle);
                setText(row, 4, contract.getTenant().getEmail() != null ? contract.getTenant().getEmail() : "", zebra ? textStyleAlt : textStyle);
                setDate(row, 5, contract.getMoveInDate(), zebra ? dateStyleAlt : dateStyle);
                setDate(row, 6, contract.getMoveOutDate(), zebra ? dateStyleAlt : dateStyle);
                setNumber(row, 7, contract.getDepositAmount() != null ? contract.getDepositAmount().doubleValue() : 0D, zebra ? currencyStyleAlt : currencyStyle);
                setStatusChip(workbook, row, 8, contractStatusLabel(contract.getStatus()), contractStatusColor(contract.getStatus()));
                setText(row, 9, contract.getNotes() != null ? contract.getNotes() : "", zebra ? textStyleAlt : textStyle);
                setText(row, 10, contract.getFileUrl() != null ? contract.getFileUrl() : "", zebra ? textStyleAlt : textStyle);
            }
            finalizeSheet(sheet, headerRow, headers.length);
            sheet.setColumnWidth(9, 40 * 256);
            sheet.setColumnWidth(10, 40 * 256);
            return attachment("hopdong.xlsx", write(workbook));
        } catch (Exception exception) {
            throw new RuntimeException("Export failed", exception);
        }
    }

    // ---- status labels/colors (mirrors the Vietnamese labels used across the web app) ----

    private String invoiceStatusLabel(InvoiceStatus status) {
        return switch (status) {
            case PENDING -> "Chờ thanh toán";
            case PAID -> "Đã thanh toán";
            case OVERDUE -> "Quá hạn";
        };
    }

    private byte[] invoiceStatusColor(InvoiceStatus status) {
        return switch (status) {
            case PENDING -> PENDING_RGB;
            case PAID -> SUCCESS_RGB;
            case OVERDUE -> ERROR_RGB;
        };
    }

    private String contractStatusLabel(ContractStatus status) {
        return switch (status) {
            case ACTIVE -> "Đang hiệu lực";
            case EXPIRED -> "Hết hạn";
            case TERMINATED -> "Đã chấm dứt";
        };
    }

    private byte[] contractStatusColor(ContractStatus status) {
        return switch (status) {
            case ACTIVE -> SUCCESS_RGB;
            case EXPIRED, TERMINATED -> NEUTRAL_RGB;
        };
    }

    // ---- cell writers ----

    private void setText(Row row, int col, String value, CellStyle style) {
        Cell cell = row.createCell(col);
        cell.setCellValue(value);
        cell.setCellStyle(style);
    }

    private void setNumber(Row row, int col, double value, CellStyle style) {
        Cell cell = row.createCell(col);
        cell.setCellValue(value);
        cell.setCellStyle(style);
    }

    private void setDate(Row row, int col, java.time.LocalDate value, CellStyle style) {
        Cell cell = row.createCell(col);
        if (value != null) {
            cell.setCellValue(value);
        }
        cell.setCellStyle(style);
    }

    private void setDateTime(Row row, int col, LocalDateTime value, CellStyle style) {
        Cell cell = row.createCell(col);
        if (value != null) {
            cell.setCellValue(value);
        }
        cell.setCellStyle(style);
    }

    private void setStatusChip(Workbook workbook, Row row, int col, String label, byte[] color) {
        Cell cell = row.createCell(col);
        cell.setCellValue(label);
        cell.setCellStyle(statusChipStyle(workbook, color));
    }

    // ---- layout ----

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

    // Title (row 0) + subtitle with record count and export timestamp (row 1), each merged
    // across every column — turns the sheet into an actual document instead of a bare table.
    // Returns the row index the header row should be written at (row 2).
    private int writeTitleBlock(Workbook workbook, Sheet sheet, String title, String recordSummary, int columnCount) {
        Row titleRow = sheet.createRow(0);
        titleRow.setHeightInPoints(26);
        Cell titleCell = titleRow.createCell(0);
        titleCell.setCellValue(title);
        titleCell.setCellStyle(titleStyle(workbook));
        sheet.addMergedRegion(new CellRangeAddress(0, 0, 0, columnCount - 1));

        Row subtitleRow = sheet.createRow(1);
        subtitleRow.setHeightInPoints(18);
        Cell subtitleCell = subtitleRow.createCell(0);
        subtitleCell.setCellValue(recordSummary + " · Xuất lúc " + LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
        subtitleCell.setCellStyle(subtitleStyle(workbook));
        sheet.addMergedRegion(new CellRangeAddress(1, 1, 0, columnCount - 1));

        return 2;
    }

    private void writeHeaderRow(Workbook workbook, Sheet sheet, int headerRowIndex, String[] headers) {
        Row header = sheet.createRow(headerRowIndex);
        header.setHeightInPoints(20);
        CellStyle style = headerCellStyle(workbook);
        for (int i = 0; i < headers.length; i++) {
            Cell cell = header.createCell(i);
            cell.setCellValue(headers[i]);
            cell.setCellStyle(style);
        }
    }

    private void finalizeSheet(Sheet sheet, int headerRowIndex, int columnCount) {
        sheet.createFreezePane(0, headerRowIndex + 1);
        int lastRow = Math.max(sheet.getLastRowNum(), headerRowIndex);
        sheet.setAutoFilter(new CellRangeAddress(headerRowIndex, lastRow, 0, columnCount - 1));
        for (int i = 0; i < columnCount; i++) {
            sheet.autoSizeColumn(i);
            // autoSizeColumn measures the unstyled text width only, which regularly under-sizes
            // a bold/larger header — give every column a floor so headers never get clipped.
            if (sheet.getColumnWidth(i) < 14 * 256) {
                sheet.setColumnWidth(i, 14 * 256);
            }
        }
    }

    // ---- styles ----

    private Font boldFont(Workbook workbook, short size, byte[] rgb) {
        Font font = workbook.createFont();
        font.setBold(true);
        font.setFontHeightInPoints(size);
        if (workbook instanceof XSSFWorkbook && font instanceof org.apache.poi.xssf.usermodel.XSSFFont xssfFont) {
            xssfFont.setColor(new XSSFColor(rgb, null));
        }
        return font;
    }

    private CellStyle titleStyle(Workbook workbook) {
        CellStyle style = workbook.createCellStyle();
        style.setFont(boldFont(workbook, (short) 16, ACCENT_TEXT_RGB));
        style.setVerticalAlignment(VerticalAlignment.CENTER);
        return style;
    }

    private CellStyle subtitleStyle(Workbook workbook) {
        CellStyle style = workbook.createCellStyle();
        Font font = workbook.createFont();
        font.setFontHeightInPoints((short) 10);
        font.setItalic(true);
        if (style instanceof XSSFCellStyle && font instanceof org.apache.poi.xssf.usermodel.XSSFFont xssfFont) {
            xssfFont.setColor(new XSSFColor(MUTED_TEXT_RGB, null));
        }
        style.setFont(font);
        style.setVerticalAlignment(VerticalAlignment.CENTER);
        return style;
    }

    private CellStyle headerCellStyle(Workbook workbook) {
        XSSFCellStyle style = (XSSFCellStyle) workbook.createCellStyle();
        style.setFont(boldFont(workbook, (short) 10, rgb(0xFF, 0xFF, 0xFF)));
        style.setFillForegroundColor(new XSSFColor(ACCENT_RGB, null));
        style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        style.setAlignment(HorizontalAlignment.CENTER);
        style.setVerticalAlignment(VerticalAlignment.CENTER);
        style.setWrapText(true);
        addBorder(style, ACCENT_RGB);
        return style;
    }

    private CellStyle bodyCellStyle(Workbook workbook, boolean zebra, HorizontalAlignment alignment) {
        XSSFCellStyle style = (XSSFCellStyle) workbook.createCellStyle();
        style.setAlignment(alignment);
        style.setVerticalAlignment(VerticalAlignment.CENTER);
        style.setWrapText(true);
        if (zebra) {
            style.setFillForegroundColor(new XSSFColor(ZEBRA_RGB, null));
            style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        }
        addBorder(style, BORDER_RGB);
        return style;
    }

    private CellStyle currencyCellStyle(Workbook workbook, boolean zebra) {
        XSSFCellStyle style = (XSSFCellStyle) bodyCellStyle(workbook, zebra, HorizontalAlignment.RIGHT);
        style.setDataFormat(workbook.createDataFormat().getFormat("#,##0\" ₫\""));
        Font font = workbook.createFont();
        font.setBold(true);
        style.setFont(font);
        return style;
    }

    private CellStyle dateCellStyle(Workbook workbook, boolean zebra, boolean withTime) {
        XSSFCellStyle style = (XSSFCellStyle) bodyCellStyle(workbook, zebra, HorizontalAlignment.CENTER);
        style.setDataFormat(workbook.createDataFormat().getFormat(withTime ? "dd/mm/yyyy hh:mm" : "dd/mm/yyyy"));
        return style;
    }

    private CellStyle statusChipStyle(Workbook workbook, byte[] color) {
        XSSFCellStyle style = (XSSFCellStyle) workbook.createCellStyle();
        style.setFont(boldFont(workbook, (short) 10, rgb(0xFF, 0xFF, 0xFF)));
        style.setFillForegroundColor(new XSSFColor(color, null));
        style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        style.setAlignment(HorizontalAlignment.CENTER);
        style.setVerticalAlignment(VerticalAlignment.CENTER);
        addBorder(style, BORDER_RGB);
        return style;
    }

    private void addBorder(XSSFCellStyle style, byte[] color) {
        style.setBorderTop(BorderStyle.THIN);
        style.setBorderBottom(BorderStyle.THIN);
        style.setBorderLeft(BorderStyle.THIN);
        style.setBorderRight(BorderStyle.THIN);
        XSSFColor xssfColor = new XSSFColor(color, null);
        style.setTopBorderColor(xssfColor);
        style.setBottomBorderColor(xssfColor);
        style.setLeftBorderColor(xssfColor);
        style.setRightBorderColor(xssfColor);
    }

    private byte[] write(Workbook workbook) throws Exception {
        java.io.ByteArrayOutputStream output = new java.io.ByteArrayOutputStream();
        workbook.write(output);
        return output.toByteArray();
    }
}
