package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Invoice;
import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.InvoiceStatus;
import chez1s.htrbackend.domain.enums.PaymentMethod;
import chez1s.htrbackend.exception.BusinessException;
import com.lowagie.text.*;
import com.lowagie.text.pdf.BaseFont;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

// Generates the invoice PDF (usable both as a pre-payment bill and, once PAID, as a receipt —
// same layout, the status/payment section just fills in differently). Called synchronously,
// right after the caller has already loaded and access-checked the Invoice entity (matching how
// PayOSService.createPaymentLink is already used from the same controller) — this service never
// re-fetches or holds onto the entity beyond the single call, so it never crosses a transaction
// boundary on its own.
@Service
public class InvoicePdfService {

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DecimalFormat MONEY_FMT = new DecimalFormat(
            "#,##0 ₫", DecimalFormatSymbols.getInstance(Locale.forLanguageTag("vi-VN")));

    private static final Color ACCENT = new Color(0x2F, 0x6F, 0xED);
    private static final Color MUTED = new Color(0x6B, 0x72, 0x80);
    private static final Color BORDER = new Color(0xE2, 0xE5, 0xEA);
    private static final Color TOTAL_ROW_BG = new Color(0xF3, 0xF6, 0xFC);

    private final BaseFont regularBase;
    private final BaseFont boldBase;

    public InvoicePdfService() {
        try {
            regularBase = loadFont("fonts/BeVietnamPro-Regular.ttf");
            boldBase = loadFont("fonts/BeVietnamPro-Bold.ttf");
        } catch (Exception e) {
            throw new IllegalStateException("Không thể tải font PDF (Be Vietnam Pro)", e);
        }
    }

    private BaseFont loadFont(String classpathPath) throws IOException, DocumentException {
        byte[] fontBytes = new ClassPathResource(classpathPath).getInputStream().readAllBytes();
        // IDENTITY_H: required for full Unicode glyph access (Vietnamese diacritics) with an
        // embedded TTF — WinAnsi encoding cannot represent them.
        return BaseFont.createFont(classpathPath, BaseFont.IDENTITY_H, BaseFont.EMBEDDED, true, fontBytes, null);
    }

    public byte[] generate(Invoice invoice) {
        User tenant = invoice.getContract().getTenant();
        Room room = invoice.getRoom();
        Property property = room.getProperty();

        Font title = new Font(boldBase, 18, Font.NORMAL, ACCENT);
        Font h2 = new Font(boldBase, 12, Font.NORMAL, Color.BLACK);
        Font label = new Font(regularBase, 9, Font.NORMAL, MUTED);
        Font body = new Font(regularBase, 10, Font.NORMAL, Color.BLACK);
        Font bodyBold = new Font(boldBase, 10, Font.NORMAL, Color.BLACK);
        Font small = new Font(regularBase, 8, Font.NORMAL, MUTED);

        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            Document document = new Document(PageSize.A4, 48, 48, 54, 48);
            PdfWriter.getInstance(document, out);
            document.open();

            document.add(new Paragraph("HowsTheRent", title));
            document.add(new Paragraph(
                    invoice.getStatus() == InvoiceStatus.PAID ? "Biên lai thanh toán" : "Hóa đơn tiền phòng",
                    h2));
            document.add(spacer(10));

            document.add(sectionTable(new String[][]{
                    {"Kỳ hóa đơn", invoice.getInvoiceMonth().format(DateTimeFormatter.ofPattern("MM/yyyy"))},
                    {"Trạng thái", statusLabel(invoice.getStatus())},
                    {"Hạn thanh toán", invoice.getDueDate().format(DATE_FMT)},
            }, label, body, bodyBold));

            if (invoice.getStatus() == InvoiceStatus.PAID) {
                document.add(sectionTable(new String[][]{
                        {"Ngày thanh toán", invoice.getPaidAt() != null ? invoice.getPaidAt().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")) : "—"},
                        {"Phương thức", paymentMethodLabel(invoice.getPaymentMethod())},
                }, label, body, bodyBold));
            }

            document.add(spacer(14));
            document.add(new Paragraph("Thông tin khách thuê", h2));
            document.add(spacer(6));
            document.add(sectionTable(new String[][]{
                    {"Họ tên", tenant.getFullName()},
                    {"Email", tenant.getEmail()},
                    {"Điện thoại", tenant.getPhone() != null && !tenant.getPhone().isBlank() ? tenant.getPhone() : "—"},
                    {"Phòng", room.getRoomNumber()},
                    {"Tòa nhà", property.getName()},
                    {"Địa chỉ", property.getAddress()},
            }, label, body, bodyBold));

            document.add(spacer(16));
            document.add(new Paragraph("Chi tiết khoản thu", h2));
            document.add(spacer(6));
            document.add(feeTable(invoice, body, bodyBold));

            document.add(spacer(24));
            document.add(new Paragraph(
                    "Chứng từ tạo tự động từ hệ thống HowsTheRent, không cần chữ ký để có giá trị đối chiếu nội bộ.",
                    small));

            document.close();
            return out.toByteArray();
        } catch (DocumentException e) {
            throw new BusinessException("Không thể tạo file PDF hóa đơn");
        }
    }

    private Paragraph spacer(float height) {
        Paragraph p = new Paragraph(" ");
        p.setSpacingAfter(0);
        p.setLeading(height);
        return p;
    }

    // Two-column "label : value" block, one row per entry — used for both the invoice-meta
    // header rows and the tenant-info block, since both are the same shape.
    private PdfPTable sectionTable(String[][] rows, Font label, Font body, Font bodyBold) {
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100);
        try {
            table.setWidths(new float[]{1f, 2.2f});
        } catch (DocumentException ignored) {
            // setWidths only throws if the array length mismatches the column count — it never
            // does here, so there is nothing to recover from.
        }
        table.setSpacingBefore(2);
        for (String[] row : rows) {
            PdfPCell labelCell = new PdfPCell(new Phrase(row[0], label));
            labelCell.setBorder(Rectangle.NO_BORDER);
            labelCell.setPaddingBottom(4);
            table.addCell(labelCell);

            PdfPCell valueCell = new PdfPCell(new Phrase(row[1], body));
            valueCell.setBorder(Rectangle.NO_BORDER);
            valueCell.setPaddingBottom(4);
            table.addCell(valueCell);
        }
        return table;
    }

    private PdfPTable feeTable(Invoice invoice, Font body, Font bodyBold) {
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100);
        try {
            table.setWidths(new float[]{2.5f, 1f});
        } catch (DocumentException ignored) {
            // See sectionTable — never actually thrown for a matching column count.
        }

        headerCell(table, "Khoản mục", body);
        headerCell(table, "Số tiền", body);

        addFeeRow(table, "Tiền phòng", invoice.getRentAmount(), body);
        addFeeRow(table, "Tiền điện", invoice.getElecAmount(), body);
        addFeeRow(table, "Tiền nước", invoice.getWaterAmount(), body);
        addFeeRow(table, "Phí gửi xe", invoice.getVehicleAmount(), body);
        addFeeRow(table, "Phí dịch vụ", invoice.getServiceAmount(), body);

        PdfPCell totalLabel = new PdfPCell(new Phrase("Tổng cộng", bodyBold));
        totalLabel.setBackgroundColor(TOTAL_ROW_BG);
        totalLabel.setBorderColor(BORDER);
        totalLabel.setPadding(8);
        table.addCell(totalLabel);

        PdfPCell totalValue = new PdfPCell(new Phrase(MONEY_FMT.format(invoice.getTotalAmount()), bodyBold));
        totalValue.setBackgroundColor(TOTAL_ROW_BG);
        totalValue.setBorderColor(BORDER);
        totalValue.setPadding(8);
        totalValue.setHorizontalAlignment(Element.ALIGN_RIGHT);
        table.addCell(totalValue);

        return table;
    }

    private void headerCell(PdfPTable table, String text, Font body) {
        Font headerFont = new Font(body.getBaseFont(), 9, Font.NORMAL, MUTED);
        PdfPCell cell = new PdfPCell(new Phrase(text.toUpperCase(Locale.ROOT), headerFont));
        cell.setBorder(Rectangle.BOTTOM);
        cell.setBorderColor(BORDER);
        cell.setPaddingBottom(6);
        table.addCell(cell);
    }

    private void addFeeRow(PdfPTable table, String name, BigDecimal amount, Font body) {
        PdfPCell nameCell = new PdfPCell(new Phrase(name, body));
        nameCell.setBorder(Rectangle.BOTTOM);
        nameCell.setBorderColor(BORDER);
        nameCell.setPadding(6);
        table.addCell(nameCell);

        PdfPCell amountCell = new PdfPCell(new Phrase(MONEY_FMT.format(amount != null ? amount : BigDecimal.ZERO), body));
        amountCell.setBorder(Rectangle.BOTTOM);
        amountCell.setBorderColor(BORDER);
        amountCell.setPadding(6);
        amountCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
        table.addCell(amountCell);
    }

    private String statusLabel(InvoiceStatus status) {
        return switch (status) {
            case PENDING -> "Chưa thanh toán";
            case PAID -> "Đã thanh toán";
            case OVERDUE -> "Quá hạn";
        };
    }

    private String paymentMethodLabel(PaymentMethod method) {
        if (method == null) return "—";
        return switch (method) {
            case CASH -> "Tiền mặt";
            case PAYOS -> "Chuyển khoản / QR (PayOS)";
        };
    }
}
