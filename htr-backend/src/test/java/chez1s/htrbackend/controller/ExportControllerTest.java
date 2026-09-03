package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Contract;
import chez1s.htrbackend.domain.entity.Invoice;
import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.ContractStatus;
import chez1s.htrbackend.domain.enums.InvoiceStatus;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.security.ActorContext;
import chez1s.htrbackend.security.OwnerScopeResolver;
import chez1s.htrbackend.service.ContractService;
import chez1s.htrbackend.service.InvoiceService;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.DateUtil;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;

import java.io.ByteArrayInputStream;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ExportControllerTest {

    @Mock
    private InvoiceService invoiceService;
    @Mock
    private ContractService contractService;
    @Mock
    private OwnerScopeResolver ownerScopeResolver;
    @Mock
    private Authentication authentication;

    private ExportController controller;

    @BeforeEach
    void setUp() {
        controller = new ExportController(invoiceService, contractService, ownerScopeResolver);
        lenient().when(authentication.getDetails())
                .thenReturn(new ActorContext(UUID.randomUUID(), UserRole.PLATFORM_ADMIN, 1L));
    }

    private Invoice sampleInvoice() {
        User tenant = User.builder().fullName("Nguyễn Văn A").email("a@example.com").role(UserRole.TENANT).build();
        Property property = Property.builder().name("Nhà trọ Xanh").address("12 Lê Lợi").build();
        Room room = Room.builder().property(property).roomNumber("A101").maxPeople(2).build();
        Contract contract = Contract.builder().room(room).tenant(tenant).moveInDate(LocalDate.of(2026, 1, 1)).build();
        return Invoice.builder()
                .id(UUID.randomUUID())
                .room(room)
                .contract(contract)
                .invoiceMonth(LocalDate.of(2026, 9, 1))
                .totalAmount(new BigDecimal("3825000"))
                .status(InvoiceStatus.OVERDUE)
                .dueDate(LocalDate.of(2026, 9, 5))
                .paidAt(null)
                .build();
    }

    @Test
    void exportInvoices_writesTitleHeaderAndFormattedDataRows() throws Exception {
        when(invoiceService.listAll()).thenReturn(List.of(sampleInvoice()));

        ResponseEntity<byte[]> response = controller.exportInvoices(authentication);

        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
        try (Workbook workbook = WorkbookFactory.create(new ByteArrayInputStream(response.getBody()))) {
            Sheet sheet = workbook.getSheetAt(0);

            assertThat(sheet.getRow(0).getCell(0).getStringCellValue()).isEqualTo("DANH SÁCH HÓA ĐƠN");
            assertThat(sheet.getRow(1).getCell(0).getStringCellValue()).contains("1 hóa đơn");

            Row header = sheet.getRow(2);
            assertThat(header.getCell(0).getStringCellValue()).isEqualTo("Mã hóa đơn");
            assertThat(header.getCell(4).getStringCellValue()).isEqualTo("Tổng tiền");
            assertThat(header.getCell(5).getStringCellValue()).isEqualTo("Trạng thái");

            Row data = sheet.getRow(3);
            // Currency: a real numeric cell (so Excel can SUM/sort it), not a string.
            Cell amountCell = data.getCell(4);
            assertThat(amountCell.getCellType()).isEqualTo(CellType.NUMERIC);
            assertThat(amountCell.getNumericCellValue()).isEqualTo(3825000);
            assertThat(DateUtil.isCellDateFormatted(amountCell)).isFalse();

            // Status: OVERDUE renders with its Vietnamese label, not the raw enum name.
            assertThat(data.getCell(5).getStringCellValue()).isEqualTo("Quá hạn");

            // Due date: a real Excel date cell, not a plain string.
            Cell dueDateCell = data.getCell(6);
            assertThat(DateUtil.isCellDateFormatted(dueDateCell)).isTrue();
            assertThat(dueDateCell.getLocalDateTimeCellValue().toLocalDate()).isEqualTo(LocalDate.of(2026, 9, 5));

            // paidAt is null for this invoice — the cell should be blank, not a stray "0" numeric.
            Cell paidAtCell = data.getCell(7);
            assertThat(paidAtCell.getCellType()).isEqualTo(CellType.BLANK);
        }
    }

    @Test
    void exportInvoices_statusColorsDifferByStatus() throws Exception {
        Invoice paid = sampleInvoice();
        paid.setStatus(InvoiceStatus.PAID);
        paid.setPaidAt(LocalDateTime.of(2026, 9, 3, 10, 0));
        Invoice pending = sampleInvoice();
        pending.setStatus(InvoiceStatus.PENDING);
        when(invoiceService.listAll()).thenReturn(List.of(paid, pending));

        ResponseEntity<byte[]> response = controller.exportInvoices(authentication);

        try (Workbook workbook = WorkbookFactory.create(new ByteArrayInputStream(response.getBody()))) {
            Sheet sheet = workbook.getSheetAt(0);
            Cell paidStatusCell = sheet.getRow(3).getCell(5);
            Cell pendingStatusCell = sheet.getRow(4).getCell(5);

            assertThat(paidStatusCell.getStringCellValue()).isEqualTo("Đã thanh toán");
            assertThat(pendingStatusCell.getStringCellValue()).isEqualTo("Chờ thanh toán");
            // Different statuses must render with visibly different fill colors, not just text.
            assertThat(paidStatusCell.getCellStyle().getFillForegroundColorColor())
                    .isNotEqualTo(pendingStatusCell.getCellStyle().getFillForegroundColorColor());
        }
    }

    @Test
    void exportInvoices_noInvoices_returns204WithNoDataHeader() {
        when(invoiceService.listAll()).thenReturn(List.of());

        ResponseEntity<byte[]> response = controller.exportInvoices(authentication);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
        assertThat(response.getHeaders().getFirst("X-Export-Result")).isEqualTo("NO_DATA");
    }

    @Test
    void exportContracts_writesVietnameseHeadersAndStatusLabel() throws Exception {
        User tenant = User.builder().fullName("Trần Thị B").email("b@example.com").role(UserRole.TENANT).build();
        Property property = Property.builder().name("Nhà trọ Xanh").address("12 Lê Lợi").build();
        Room room = Room.builder().property(property).roomNumber("B202").maxPeople(2).build();
        Contract contract = Contract.builder()
                .id(UUID.randomUUID())
                .room(room)
                .tenant(tenant)
                .moveInDate(LocalDate.of(2026, 1, 1))
                .depositAmount(new BigDecimal("5000000"))
                .status(ContractStatus.ACTIVE)
                .build();
        when(contractService.listAll()).thenReturn(List.of(contract));

        ResponseEntity<byte[]> response = controller.exportContracts(authentication);

        try (Workbook workbook = WorkbookFactory.create(new ByteArrayInputStream(response.getBody()))) {
            Sheet sheet = workbook.getSheetAt(0);
            assertThat(sheet.getRow(0).getCell(0).getStringCellValue()).isEqualTo("DANH SÁCH HỢP ĐỒNG");

            Row header = sheet.getRow(2);
            assertThat(header.getCell(3).getStringCellValue()).isEqualTo("Khách thuê");

            Row data = sheet.getRow(3);
            assertThat(data.getCell(3).getStringCellValue()).isEqualTo("Trần Thị B");
            assertThat(data.getCell(8).getStringCellValue()).isEqualTo("Đang hiệu lực");

            Cell depositCell = data.getCell(7);
            assertThat(depositCell.getCellType()).isEqualTo(CellType.NUMERIC);
            assertThat(depositCell.getNumericCellValue()).isEqualTo(5_000_000);
        }
    }
}
